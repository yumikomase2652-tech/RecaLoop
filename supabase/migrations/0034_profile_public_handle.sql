create or replace function public.current_academic_year()
returns int
language sql
stable
as $$
  select case
    when extract(month from current_date) >= 4 then extract(year from current_date)::int
    else extract(year from current_date)::int - 1
  end
$$;

alter table public.profiles add column if not exists target_school text;
alter table public.profiles add column if not exists age_group text;
alter table public.profiles add column if not exists grade_level text;
alter table public.profiles add column if not exists grade_updated_year int;
alter table public.profiles add column if not exists onboarding_completed boolean default false;
alter table public.profiles add column if not exists public_handle text;

update public.profiles
set public_handle = 'user_' || substr(replace(id::text,'-',''),1,8)
where nullif(trim(coalesce(public_handle,'')),'') is null;

alter table public.profiles drop constraint if exists profiles_age_group_check;
alter table public.profiles add constraint profiles_age_group_check check(
  age_group is null
  or age_group in('小学生','中学生','高校生','浪人生','大学生&大学院生','社会人','その他')
);

alter table public.profiles drop constraint if exists profiles_grade_level_check;
alter table public.profiles add constraint profiles_grade_level_check check(
  grade_level is null
  or grade_level in(
    '小学1年生','小学2年生','小学3年生','小学4年生','小学5年生','小学6年生',
    '中学1年生','中学2年生','中学3年生',
    '高校1年生','高校2年生','高校3年生',
    '浪人生','大学生','大学院生','社会人','その他'
  )
);

create unique index if not exists profiles_public_handle_unique
on public.profiles(lower(public_handle))
where public_handle is not null and public_handle <> '';

alter table public.profiles drop constraint if exists profiles_public_handle_format_check;
alter table public.profiles add constraint profiles_public_handle_format_check check(
  public_handle ~ '^[A-Za-z0-9_]{3,20}$'
);

alter table public.profiles alter column public_handle set not null;

drop function if exists public.update_learning_profile(text,text,text,text);
drop function if exists public.update_learning_profile(text,text,text,text,text);

create function public.update_learning_profile(
  p_display_name text,
  p_grade_level text,
  p_target_school text,
  p_age_group text default null,
  p_public_handle text default null
)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  resolved_age_group text := p_age_group;
  normalized_handle text := coalesce(nullif(trim(coalesce(p_public_handle,'')),''),'user_' || substr(replace(auth.uid()::text,'-',''),1,8));
begin
  if p_grade_level not in(
    '小学1年生','小学2年生','小学3年生','小学4年生','小学5年生','小学6年生',
    '中学1年生','中学2年生','中学3年生',
    '高校1年生','高校2年生','高校3年生',
    '浪人生','大学生','大学院生','社会人','その他'
  ) then
    raise exception '学年を選択してください';
  end if;

  if normalized_handle is not null and normalized_handle !~ '^[A-Za-z0-9_]{3,20}$' then
    raise exception 'IDは半角英数字と_で3〜20文字にしてください';
  end if;

  if normalized_handle is not null and exists(
    select 1 from profiles
    where lower(public_handle)=lower(normalized_handle)
      and id<>auth.uid()
  ) then
    raise exception 'このIDはすでに使われています';
  end if;

  if resolved_age_group is null then
    resolved_age_group := case
      when p_grade_level like '小学%' then '小学生'
      when p_grade_level like '中学%' then '中学生'
      when p_grade_level like '高校%' then '高校生'
      when p_grade_level = '浪人生' then '浪人生'
      when p_grade_level in('大学生','大学院生') then '大学生&大学院生'
      when p_grade_level = '社会人' then '社会人'
      else 'その他'
    end;
  end if;

  if resolved_age_group not in('小学生','中学生','高校生','浪人生','大学生&大学院生','社会人','その他') then
    raise exception '年代を選択してください';
  end if;

  update profiles
  set display_name=trim(p_display_name),
      public_handle=normalized_handle,
      age_group=resolved_age_group,
      grade_level=p_grade_level,
      target_school=p_target_school,
      grade_updated_year=public.current_academic_year()
  where id=auth.uid();
  if not found then raise exception 'profile not found'; end if;
end
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  insert into public.profiles(id,display_name,public_handle)
  values(
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1), ''),
    'user_' || substr(replace(new.id::text,'-',''),1,8)
  )
  on conflict (id) do nothing;
  return new;
end
$$;

grant update(display_name,public_handle,target_school,age_group,grade_level,grade_updated_year,onboarding_completed) on public.profiles to authenticated;
