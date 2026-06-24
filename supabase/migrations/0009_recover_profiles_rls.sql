-- Recovery migration: keep login/profile loading independent from teacher/student joins.
-- The previous linked-profile SELECT policy could make the initial app load depend on
-- teacher_student_links evaluation. Own profile access must always be simple.

alter table public.profiles enable row level security;

drop policy if exists "profiles linked read" on public.profiles;
drop policy if exists "profile own" on public.profiles;
drop policy if exists "profile own read" on public.profiles;
drop policy if exists "profile own editable fields" on public.profiles;
drop policy if exists "profile own insert" on public.profiles;

create policy "profile own read" on public.profiles
  for select using (id = auth.uid());

create policy "profile own editable fields" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

create policy "profile own insert" on public.profiles
  for insert with check (id = auth.uid());

grant select,insert on public.profiles to authenticated;
grant update(display_name,target_school,grade_level,grade_updated_year,onboarding_completed,role,equipped_title_id) on public.profiles to authenticated;

drop policy if exists "links own" on public.teacher_student_links;
create policy "links own" on public.teacher_student_links
  for select using (
    teacher_id = auth.uid()
    or student_id = auth.uid()
    or (student_id is null and teacher_id = auth.uid())
  );

create or replace function public.linked_profiles()
returns setof public.profiles
language sql
security definer
set search_path = public
as $$
  select p.*
  from public.profiles p
  where p.id = auth.uid()
     or exists (
      select 1
      from public.teacher_student_links l
      where l.status = 'active'
        and (
          (l.teacher_id = auth.uid() and l.student_id = p.id)
          or
          (l.student_id = auth.uid() and l.teacher_id = p.id)
        )
     )
$$;

grant execute on function public.linked_profiles() to authenticated;
