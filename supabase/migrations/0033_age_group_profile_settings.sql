alter table public.profiles add column if not exists age_group text;

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

create or replace function public.complete_onboarding(p_grade_level text,p_target_school text)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  inferred_age_group text;
begin
  if p_grade_level not in(
    '小学1年生','小学2年生','小学3年生','小学4年生','小学5年生','小学6年生',
    '中学1年生','中学2年生','中学3年生',
    '高校1年生','高校2年生','高校3年生',
    '浪人生','大学生','大学院生','社会人','その他'
  ) then
    raise exception '学年を選択してください';
  end if;

  inferred_age_group := case
    when p_grade_level like '小学%' then '小学生'
    when p_grade_level like '中学%' then '中学生'
    when p_grade_level like '高校%' then '高校生'
    when p_grade_level = '浪人生' then '浪人生'
    when p_grade_level in('大学生','大学院生') then '大学生&大学院生'
    when p_grade_level = '社会人' then '社会人'
    else 'その他'
  end;

  update profiles
  set age_group=inferred_age_group,
      grade_level=p_grade_level,
      target_school=p_target_school,
      grade_updated_year=public.current_academic_year(),
      onboarding_completed=true
  where id=auth.uid();
  if not found then raise exception 'profile not found'; end if;
end
$$;

drop function if exists public.update_learning_profile(text,text,text);
drop function if exists public.update_learning_profile(text,text,text,text);

create function public.update_learning_profile(p_display_name text,p_grade_level text,p_target_school text,p_age_group text default null)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  resolved_age_group text := p_age_group;
begin
  if p_grade_level not in(
    '小学1年生','小学2年生','小学3年生','小学4年生','小学5年生','小学6年生',
    '中学1年生','中学2年生','中学3年生',
    '高校1年生','高校2年生','高校3年生',
    '浪人生','大学生','大学院生','社会人','その他'
  ) then
    raise exception '学年を選択してください';
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
      age_group=resolved_age_group,
      grade_level=p_grade_level,
      target_school=p_target_school,
      grade_updated_year=public.current_academic_year()
  where id=auth.uid();
  if not found then raise exception 'profile not found'; end if;
end
$$;

grant update(display_name,target_school,age_group,grade_level,grade_updated_year,onboarding_completed) on public.profiles to authenticated;
