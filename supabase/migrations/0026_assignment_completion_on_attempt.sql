create or replace function public.mark_assignment_item_done_from_attempt(
  p_user_id uuid,
  p_target_type text,
  p_target_id uuid
) returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  with touched as (
    update public.assignment_items ai
    set
      status = 'done',
      completed_at = coalesce(ai.completed_at, now())
    from public.assignments a
    where a.id = ai.assignment_id
      and a.student_id = p_user_id
      and a.status = 'active'
      and ai.target_type = p_target_type
      and ai.target_id = p_target_id
      and ai.status <> 'done'
    returning ai.assignment_id
  )
  update public.assignments a
  set
    status = 'completed',
    updated_at = now()
  where a.id in (select assignment_id from touched)
    and a.status = 'active'
    and not exists (
      select 1
      from public.assignment_items ai
      where ai.assignment_id = a.id
        and ai.status <> 'done'
    );
end
$$;

create or replace function public.mark_material_assignment_item_done_from_attempt()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.mark_assignment_item_done_from_attempt(NEW.user_id, 'material_item', NEW.material_node_id);
  return NEW;
end
$$;

create or replace function public.mark_word_assignment_item_done_from_attempt()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  perform public.mark_assignment_item_done_from_attempt(NEW.user_id, 'word_card', NEW.word_card_id);
  return NEW;
end
$$;

drop trigger if exists material_attempts_mark_assignment_done on public.material_attempts;
create trigger material_attempts_mark_assignment_done
after insert on public.material_attempts
for each row execute function public.mark_material_assignment_item_done_from_attempt();

drop trigger if exists word_attempts_mark_assignment_done on public.word_attempts;
create trigger word_attempts_mark_assignment_done
after insert on public.word_attempts
for each row execute function public.mark_word_assignment_item_done_from_attempt();

grant execute on function public.mark_assignment_item_done_from_attempt(uuid,text,uuid) to authenticated;
