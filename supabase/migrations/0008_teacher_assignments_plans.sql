alter table public.profiles add column if not exists role text not null default 'none';
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check(role in('none','student','teacher'));
alter table public.profiles alter column role set default 'none';
update public.profiles set role='none' where role is null;

create table if not exists public.teacher_student_links(
 id uuid primary key default gen_random_uuid(),
 teacher_id uuid not null references public.profiles(id)on delete cascade,
 student_id uuid references public.profiles(id)on delete cascade,
 invite_code text not null unique,
 status text not null default 'pending' check(status in('pending','active')),
 created_at timestamptz not null default now(),
 unique(teacher_id,student_id)
);
create table if not exists public.assignments(
 id uuid primary key default gen_random_uuid(),
 teacher_id uuid not null references public.profiles(id)on delete cascade,
 student_id uuid not null references public.profiles(id)on delete cascade,
 title text not null,due_date date not null,status text not null default 'active' check(status in('active','completed')),
 created_at timestamptz not null default now()
);
create table if not exists public.assignment_items(
 id uuid primary key default gen_random_uuid(),
 assignment_id uuid not null references public.assignments(id)on delete cascade,
 target_type text not null check(target_type in('material_item','word_card')),
 target_id uuid not null,status text not null default 'assigned' check(status in('assigned','done')),
 created_at timestamptz not null default now(),completed_at timestamptz
);
create table if not exists public.study_plans(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles(id)on delete cascade,
 deck_type text not null check(deck_type in('material','word')),deck_id uuid not null,title text not null,
 start_date date not null,end_date date,created_at timestamptz not null default now()
);
create table if not exists public.study_plan_items(
 id uuid primary key default gen_random_uuid(),plan_id uuid not null references public.study_plans(id)on delete cascade,
 target_type text not null check(target_type in('material_item','word_card')),target_id uuid not null,
 scheduled_date date not null,status text not null default 'planned' check(status in('planned','done','skipped')),
 created_at timestamptz not null default now(),completed_at timestamptz
);

alter table public.teacher_student_links enable row level security;
alter table public.assignments enable row level security;
alter table public.assignment_items enable row level security;
alter table public.study_plans enable row level security;
alter table public.study_plan_items enable row level security;
drop policy if exists "links own" on public.teacher_student_links;
create policy "links own" on public.teacher_student_links for select using(teacher_id=auth.uid()or student_id=auth.uid()or(student_id is null and teacher_id=auth.uid()));
drop policy if exists "assignments own linked" on public.assignments;
create policy "assignments own linked" on public.assignments for select using(student_id=auth.uid()or teacher_id=auth.uid());
drop policy if exists "assignment items own linked" on public.assignment_items;
create policy "assignment items own linked" on public.assignment_items for select using(exists(select 1 from assignments a where a.id=assignment_id and(a.student_id=auth.uid()or a.teacher_id=auth.uid())));
drop policy if exists "plans own" on public.study_plans;
create policy "plans own" on public.study_plans for all using(user_id=auth.uid())with check(user_id=auth.uid());
drop policy if exists "plan items own" on public.study_plan_items;
create policy "plan items own" on public.study_plan_items for all using(exists(select 1 from study_plans p where p.id=plan_id and p.user_id=auth.uid()))with check(exists(select 1 from study_plans p where p.id=plan_id and p.user_id=auth.uid()));

grant select,insert,update on public.teacher_student_links to authenticated;
grant select,insert,update on public.assignments to authenticated;
grant select,insert,update on public.assignment_items to authenticated;
grant select,insert,update,delete on public.study_plans to authenticated;
grant select,insert,update,delete on public.study_plan_items to authenticated;
grant update(role)on public.profiles to authenticated;

drop function if exists public.create_invite_code();
create or replace function public.create_invite_code(p_refresh boolean default false)returns text language plpgsql security definer set search_path=public as $$
declare code text;begin
 if not exists(select 1 from profiles where id=auth.uid()and role='teacher')then raise exception'教師権限が必要です';end if;
 if not p_refresh then
  select invite_code into code from teacher_student_links where teacher_id=auth.uid()and student_id is null and status='pending' order by created_at desc limit 1;
  if code is not null then return code;end if;
 end if;
 code:=upper(substr(replace(gen_random_uuid()::text,'-',''),1,8));
 insert into teacher_student_links(teacher_id,invite_code,status)values(auth.uid(),code,'pending');
 return code;
end$$;
create or replace function public.join_teacher(p_invite_code text)returns void language plpgsql security definer set search_path=public as $$
begin
 update teacher_student_links set student_id=auth.uid(),status='active' where invite_code=upper(trim(p_invite_code))and student_id is null;
 if not found then raise exception'招待コードが見つかりません';end if;
end$$;
create or replace function public.create_assignment(p_student_id uuid,p_title text,p_due_date date,p_items jsonb)returns uuid language plpgsql security definer set search_path=public as $$
declare result uuid;item jsonb;begin
 if not exists(select 1 from profiles where id=auth.uid()and role='teacher')then raise exception'教師権限が必要です';end if;
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid()and student_id=p_student_id and status='active')then raise exception'連携済みの生徒ではありません';end if;
 insert into assignments(teacher_id,student_id,title,due_date)values(auth.uid(),p_student_id,p_title,p_due_date)returning id into result;
 for item in select*from jsonb_array_elements(p_items)loop
  insert into assignment_items(assignment_id,target_type,target_id)values(result,item->>'target_type',(item->>'target_id')::uuid);
 end loop;
 return result;
end$$;
create or replace function public.save_study_plan(p_deck_type text,p_deck_id uuid,p_title text,p_start_date date,p_end_date date,p_items jsonb)returns uuid language plpgsql security definer set search_path=public as $$
declare result uuid;item jsonb;begin
 insert into study_plans(user_id,deck_type,deck_id,title,start_date,end_date)values(auth.uid(),p_deck_type,p_deck_id,p_title,p_start_date,p_end_date)returning id into result;
 for item in select*from jsonb_array_elements(p_items)loop
  insert into study_plan_items(plan_id,target_type,target_id,scheduled_date)values(result,item->>'target_type',(item->>'target_id')::uuid,(item->>'scheduled_date')::date);
 end loop;
 return result;
end$$;

-- Recreate final review RPC so assignment items and study plan items are marked done on rating.
drop function if exists public.review_target(text,uuid,rating,boolean);
create function public.review_target(p_type text,p_id uuid,p_rating rating,p_unknown boolean)returns jsonb language plpgsql security definer set search_path=public as $$
declare days int;prior_count int:=0;attempt_id uuid:=gen_random_uuid();v_deck_id uuid;v_source_id uuid;v_deck_title text;v_title_id uuid;all_count int;done_count int;exp_gained int:=0;new_titles jsonb:='[]'::jsonb;inserted_title uuid;target_kind text;begin
 target_kind:=case when p_type='material'then'material_item'else'word_card'end;
 if p_type='material'then
  select n.deck_id,coalesce(s.review_count,0)into v_deck_id,prior_count from material_nodes n join material_decks d on d.id=n.deck_id left join material_item_states s on s.material_node_id=n.id and s.user_id=auth.uid()where n.id=p_id and n.node_type='item'and d.user_id=auth.uid();if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then insert into material_item_states(user_id,material_node_id,unknown_flag)values(auth.uid(),p_id,p_unknown)on conflict(user_id,material_node_id)do update set unknown_flag=p_unknown,updated_at=now();insert into material_attempts(id,user_id,material_node_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,null,p_unknown,'check');
  else days:=case p_rating when'again'then 0 when'hard'then 1 when'good'then 3 else 7 end;insert into material_item_states(user_id,material_node_id,last_rating,unknown_flag,review_count,due_at,next_review_date)values(auth.uid(),p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)on conflict(user_id,material_node_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=material_item_states.review_count+1,due_at=now()+make_interval(days=>days),next_review_date=current_date+days,updated_at=now();insert into material_attempts(id,user_id,material_node_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,p_rating,p_unknown,'review');if grant_exp(5,'material_rating',attempt_id::text)then exp_gained:=exp_gained+5;end if;if prior_count>0 and grant_exp(5,'review_complete',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   select count(*)into all_count from material_nodes where deck_id=v_deck_id and node_type='item';select count(*)into done_count from material_item_states s join material_nodes n on n.id=s.material_node_id where n.deck_id=v_deck_id and s.user_id=auth.uid()and s.last_rating is not null;
   if all_count>0 and done_count=all_count and grant_exp(50,'deck_complete','material:'||v_deck_id::text)then exp_gained:=exp_gained+50;select coalesce(d.source_content_id,d.id),coalesce(src.published_snapshot->>'title',d.title)into v_source_id,v_deck_title from material_decks d left join material_decks src on src.id=d.source_content_id where d.id=v_deck_id;insert into titles(title_key,display_name,title_type,condition_json)values('deck_completion:material:'||v_source_id::text,v_deck_title,'deck_completion',jsonb_build_object('source_type','material','source_id',v_source_id))on conflict(title_key)do update set display_name=excluded.display_name,condition_json=excluded.condition_json returning id into v_title_id;inserted_title:=null;insert into user_titles(user_id,title_id,source_type,source_id)values(auth.uid(),v_title_id,'material',v_source_id)on conflict do nothing returning id into inserted_title;if inserted_title is not null then update profiles set equipped_title_id=v_title_id where id=auth.uid();new_titles:=new_titles||jsonb_build_array(v_deck_title);end if;end if;
  end if;
 else
  select c.list_id,coalesce(s.review_count,0)into v_deck_id,prior_count from word_cards c join word_lists l on l.id=c.list_id left join word_card_states s on s.word_card_id=c.id and s.user_id=auth.uid()where c.id=p_id and l.user_id=auth.uid();if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then insert into word_card_states(user_id,word_card_id,unknown_flag)values(auth.uid(),p_id,p_unknown)on conflict(user_id,word_card_id)do update set unknown_flag=p_unknown,updated_at=now();insert into word_attempts(id,user_id,word_card_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,null,p_unknown,'check');
  else days:=case p_rating when'again'then 0 when'hard'then 1 when'good'then 3 else 7 end;insert into word_card_states(user_id,word_card_id,last_rating,unknown_flag,review_count,due_at,next_review_date)values(auth.uid(),p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)on conflict(user_id,word_card_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=word_card_states.review_count+1,due_at=now()+make_interval(days=>days),next_review_date=current_date+days,updated_at=now();insert into word_attempts(id,user_id,word_card_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,p_rating,p_unknown,'review');if grant_exp(3,'word_rating',attempt_id::text)then exp_gained:=exp_gained+3;end if;if prior_count>0 and grant_exp(5,'review_complete',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   select count(*)into all_count from word_cards where list_id=v_deck_id;select count(*)into done_count from word_card_states s join word_cards c on c.id=s.word_card_id where c.list_id=v_deck_id and s.user_id=auth.uid()and s.last_rating is not null;
   if all_count>0 and done_count=all_count and grant_exp(50,'deck_complete','cards:'||v_deck_id::text)then exp_gained:=exp_gained+50;select coalesce(l.source_content_id,l.id),coalesce(src.published_snapshot->>'title',l.title)into v_source_id,v_deck_title from word_lists l left join word_lists src on src.id=l.source_content_id where l.id=v_deck_id;insert into titles(title_key,display_name,title_type,condition_json)values('deck_completion:cards:'||v_source_id::text,v_deck_title,'deck_completion',jsonb_build_object('source_type','cards','source_id',v_source_id))on conflict(title_key)do update set display_name=excluded.display_name,condition_json=excluded.condition_json returning id into v_title_id;inserted_title:=null;insert into user_titles(user_id,title_id,source_type,source_id)values(auth.uid(),v_title_id,'cards',v_source_id)on conflict do nothing returning id into inserted_title;if inserted_title is not null then update profiles set equipped_title_id=v_title_id where id=auth.uid();new_titles:=new_titles||jsonb_build_array(v_deck_title);end if;end if;
  end if;
 end if;
 if p_rating is not null then
  update assignment_items ai set status='done',completed_at=coalesce(completed_at,now())from assignments a where a.id=ai.assignment_id and a.student_id=auth.uid()and ai.target_type=target_kind and ai.target_id=p_id and ai.status='assigned';
  update assignments a set status='completed'where a.student_id=auth.uid()and status='active'and not exists(select 1 from assignment_items ai where ai.assignment_id=a.id and ai.status<>'done');
  update study_plan_items spi set status='done',completed_at=coalesce(completed_at,now())from study_plans sp where sp.id=spi.plan_id and sp.user_id=auth.uid()and spi.target_type=target_kind and spi.target_id=p_id and spi.status='planned';
  if(exists(select 1 from material_attempts where user_id=auth.uid()and rating is not null and reviewed_at::date=current_date-1)or exists(select 1 from word_attempts where user_id=auth.uid()and rating is not null and reviewed_at::date=current_date-1))and grant_exp(10,'daily_streak',current_date::text)then exp_gained:=exp_gained+10;end if;
  new_titles:=new_titles||public.sync_exp_titles()||public.sync_streak_titles();
 end if;
 return jsonb_build_object('exp_gained',exp_gained,'new_titles',new_titles,'deck_completed',coalesce(all_count>0 and done_count=all_count,false));
end$$;
