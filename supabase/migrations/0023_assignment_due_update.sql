alter table public.assignments add column if not exists updated_at timestamptz not null default now();

create or replace function public.update_assignment_due(p_assignment_id uuid,p_due_date date)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
 v_student_id uuid;
begin
 select student_id into v_student_id
 from assignments
 where id=p_assignment_id
   and teacher_id=auth.uid();

 if v_student_id is null then
  raise exception 'not allowed: assignment owner mismatch';
 end if;

 if not exists(
  select 1
  from teacher_student_links
  where teacher_id=auth.uid()
    and student_id=v_student_id
    and status='active'
 ) then
  raise exception 'not allowed: teacher is not linked to student';
 end if;

 update assignments
 set due_date=p_due_date,
     status='active',
     updated_at=now()
 where id=p_assignment_id
   and teacher_id=auth.uid();

 if not found then
  raise exception 'not allowed: assignment update failed';
 end if;
end
$$;

grant execute on function public.update_assignment_due(uuid,date) to authenticated;
