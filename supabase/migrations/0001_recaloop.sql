create extension if not exists pgcrypto;

create type public.user_role as enum ('student','teacher');
create type public.unit_type as enum ('page','problem','lesson','word');
create type public.understanding_level as enum ('good','normal','bad');
create type public.review_status as enum ('pending','done');
create type public.assignment_status as enum ('assigned','done');
create type public.card_difficulty as enum ('easy','normal','hard');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  roles user_role[] not null default array['student']::user_role[],
  coin_balance int not null default 0 check (coin_balance >= 0),
  created_at timestamptz not null default now()
);
create table public.materials (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null, subject text not null, unit_type unit_type not null, total_units int not null check(total_units > 0),
  current_unit int not null default 0 check(current_unit >= 0), created_at timestamptz not null default now()
);
create table public.study_logs (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  material_id uuid not null references public.materials(id) on delete cascade, start_unit int not null, end_unit int not null,
  understanding understanding_level not null, memo text, studied_at date not null default current_date, created_at timestamptz not null default now(),
  check(start_unit > 0 and end_unit >= start_unit)
);
create table public.reviews (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  material_id uuid not null references public.materials(id) on delete cascade, start_unit int not null, end_unit int not null,
  review_date date not null, review_count int not null default 0, status review_status not null default 'pending', created_at timestamptz not null default now()
);
create table public.flashcards (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  deck_name text not null, subject text not null, front text not null, back text not null, memo text,
  difficulty card_difficulty not null default 'normal', next_review_date date not null default current_date,
  review_count int not null default 0, created_at timestamptz not null default now()
);
create table public.teacher_student_links (
  id uuid primary key default gen_random_uuid(), teacher_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid references public.profiles(id) on delete cascade, invite_code text not null unique default upper(substr(encode(gen_random_bytes(6),'hex'),1,8)),
  status text not null default 'active', created_at timestamptz not null default now(), unique(teacher_id, student_id)
);
create table public.assignments (
  id uuid primary key default gen_random_uuid(), teacher_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade, related_material_id uuid references public.materials(id) on delete set null,
  title text not null, description text, due_date date not null, status assignment_status not null default 'assigned', created_at timestamptz not null default now()
);
create table public.coin_transactions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  amount int not null, reason text not null, created_at timestamptz not null default now()
);

create or replace function public.is_linked_teacher(student uuid) returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=student and status='active') $$;

alter table profiles enable row level security; alter table materials enable row level security; alter table study_logs enable row level security;
alter table reviews enable row level security; alter table flashcards enable row level security; alter table teacher_student_links enable row level security;
alter table assignments enable row level security; alter table coin_transactions enable row level security;

create policy "profiles own or linked teacher" on profiles for select using(id=auth.uid() or is_linked_teacher(id));
create policy "profiles own update" on profiles for update using(id=auth.uid());
create policy "materials own write" on materials for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "materials linked teacher read" on materials for select using(is_linked_teacher(user_id));
create policy "logs own write" on study_logs for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "logs linked teacher read" on study_logs for select using(is_linked_teacher(user_id));
create policy "reviews own write" on reviews for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "reviews linked teacher read" on reviews for select using(is_linked_teacher(user_id));
create policy "cards own only" on flashcards for all using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "links participants read" on teacher_student_links for select using(teacher_id=auth.uid() or student_id=auth.uid());
create policy "teachers create links" on teacher_student_links for insert with check(teacher_id=auth.uid());
create policy "teachers update links" on teacher_student_links for update using(teacher_id=auth.uid());
create policy "assignments participants read" on assignments for select using(teacher_id=auth.uid() or student_id=auth.uid());
create policy "teachers assignments write" on assignments for insert with check(teacher_id=auth.uid() and is_linked_teacher(student_id));
create policy "teachers assignments update" on assignments for update using(teacher_id=auth.uid());
create policy "students complete assignments" on assignments for update using(student_id=auth.uid()) with check(student_id=auth.uid());
create policy "coins own read" on coin_transactions for select using(user_id=auth.uid());

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name','')); return new; end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.add_study_log(p_material_id uuid,p_start int,p_end int,p_understanding understanding_level,p_memo text default null,p_date date default current_date)
returns uuid language plpgsql security definer set search_path=public as $$
declare log_id uuid; days int; finished boolean;
begin
  if not exists(select 1 from materials where id=p_material_id and user_id=auth.uid()) then raise exception 'not allowed'; end if;
  insert into study_logs(user_id,material_id,start_unit,end_unit,understanding,memo,studied_at) values(auth.uid(),p_material_id,p_start,p_end,p_understanding,p_memo,p_date) returning id into log_id;
  days := case p_understanding when 'good' then 7 when 'normal' then 3 else 1 end;
  insert into reviews(user_id,material_id,start_unit,end_unit,review_date) values(auth.uid(),p_material_id,p_start,p_end,p_date+days);
  update materials set current_unit=greatest(current_unit,p_end) where id=p_material_id returning current_unit>=total_units into finished;
  insert into coin_transactions(user_id,amount,reason) values(auth.uid(),5,'study_log');
  update profiles set coin_balance=coin_balance+5 where id=auth.uid();
  if finished and not exists(select 1 from coin_transactions where user_id=auth.uid() and reason='material_complete:'||p_material_id) then
    insert into coin_transactions(user_id,amount,reason) values(auth.uid(),100,'material_complete:'||p_material_id);
    update profiles set coin_balance=coin_balance+100 where id=auth.uid();
  end if; return log_id;
end $$;

create or replace function public.complete_review(p_review_id uuid) returns void language plpgsql security definer set search_path=public as $$
declare r reviews; days int;
begin select * into r from reviews where id=p_review_id and user_id=auth.uid() and status='pending'; if not found then raise exception 'not allowed'; end if;
days := case r.review_count when 0 then 3 when 1 then 7 when 2 then 14 else 30 end;
update reviews set status='done' where id=r.id;
insert into reviews(user_id,material_id,start_unit,end_unit,review_date,review_count) values(auth.uid(),r.material_id,r.start_unit,r.end_unit,current_date+days,r.review_count+1);
insert into coin_transactions(user_id,amount,reason) values(auth.uid(),10,'review_complete'); update profiles set coin_balance=coin_balance+10 where id=auth.uid(); end $$;

create or replace function public.review_flashcard(p_card_id uuid,p_difficulty card_difficulty) returns void language plpgsql security definer set search_path=public as $$
begin update flashcards set difficulty=p_difficulty,review_count=review_count+1,next_review_date=current_date+(case p_difficulty when 'easy' then 7 when 'normal' then 3 else 1 end) where id=p_card_id and user_id=auth.uid();
if not found then raise exception 'not allowed'; end if; insert into coin_transactions(user_id,amount,reason) values(auth.uid(),1,'flashcard_review'); update profiles set coin_balance=coin_balance+1 where id=auth.uid(); end $$;

create or replace function public.join_teacher(p_code text) returns void language plpgsql security definer set search_path=public as $$
begin update teacher_student_links set student_id=auth.uid() where invite_code=upper(p_code) and student_id is null and teacher_id<>auth.uid(); if not found then raise exception 'invalid invite code'; end if; end $$;
