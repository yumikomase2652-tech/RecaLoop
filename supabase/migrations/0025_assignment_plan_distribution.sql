create or replace function public.plan_assignment_remaining(p_assignment_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
 a record;
 result uuid;
 days date[];
 day_count int;
 remaining int;
 idx int := 0;
 day_pos int := 1;
 slot_in_day int := 0;
 day_capacity int;
 base_count int;
 extra_count int;
 item record;
 target_deck_type text := 'material';
 target_deck_id uuid := null;
 target_title text := '課題';
 target_date date;
begin
 select * into a from assignments where id = p_assignment_id;
 if a.id is null then
  raise exception 'not found';
 end if;
 if a.student_id <> auth.uid()
   and not exists(
    select 1 from teacher_student_links
    where teacher_id = auth.uid()
      and student_id = a.student_id
      and status = 'active'
   ) then
  raise exception 'not allowed: assignment is not linked to current user';
 end if;

 if a.due_date < current_date then
  days := array[current_date];
 else
  select array_agg(d::date order by d)
  into days
  from generate_series(current_date, a.due_date, interval '1 day') d;
 end if;
 day_count := greatest(coalesce(array_length(days, 1), 0), 1);

 select count(*)
 into remaining
 from assignment_items
 where assignment_id = p_assignment_id
   and status <> 'done';
 if remaining = 0 then
  raise exception '未完了の課題がありません';
 end if;

 select
  case when ai.target_type = 'word_card' then 'word' else 'material' end,
  case when ai.target_type = 'word_card' then c.list_id else n.deck_id end,
  case when ai.target_type = 'word_card' then wl.title else md.title end
 into target_deck_type, target_deck_id, target_title
 from assignment_items ai
 left join material_nodes n on n.id = ai.target_id and ai.target_type = 'material_item'
 left join material_decks md on md.id = n.deck_id
 left join word_cards c on c.id = ai.target_id and ai.target_type = 'word_card'
 left join word_lists wl on wl.id = c.list_id
 where ai.assignment_id = p_assignment_id
   and ai.status <> 'done'
 order by ai.created_at
 limit 1;

 insert into study_plans(user_id, deck_type, deck_id, title, start_date, end_date)
 values(a.student_id, target_deck_type, target_deck_id, '課題: ' || coalesce(target_title, a.title), current_date, a.due_date)
 returning id into result;

 base_count := floor(remaining::numeric / day_count)::int;
 extra_count := remaining % day_count;
 day_capacity := base_count + case when day_pos <= extra_count then 1 else 0 end;

 for item in
  with recursive material_tree as (
   select
    n.id,
    n.parent_id,
    n.deck_id,
    array[n.order_index] as order_path,
    array[n.title] as title_path
   from material_nodes n
   where n.deck_id = target_deck_id
     and n.parent_id is null
   union all
   select
    child.id,
    child.parent_id,
    child.deck_id,
    material_tree.order_path || child.order_index,
    material_tree.title_path || child.title
   from material_nodes child
   join material_tree on material_tree.id = child.parent_id
   where child.deck_id = target_deck_id
  ),
  ordered_items as (
   select
    ai.*,
    coalesce(mt.order_path, array[coalesce(n.order_index, 0)]) as material_order_path,
    c.order_index as card_order_index,
    c.card_id,
    c.front
   from assignment_items ai
   left join material_nodes n on n.id = ai.target_id and ai.target_type = 'material_item'
   left join material_tree mt on mt.id = ai.target_id
   left join word_cards c on c.id = ai.target_id and ai.target_type = 'word_card'
   where ai.assignment_id = p_assignment_id
     and ai.status <> 'done'
  )
  select *
  from ordered_items
  order by
   case when target_type = 'material_item' then 0 else 1 end,
   material_order_path,
   card_order_index nulls last,
   card_id nulls last,
   front nulls last,
   created_at
 loop
  if day_capacity = 0 then
   day_pos := least(day_pos + 1, day_count);
   day_capacity := base_count + case when day_pos <= extra_count then 1 else 0 end;
  end if;
  target_date := days[least(day_pos, day_count)];
  insert into study_plan_items(plan_id, target_type, target_id, scheduled_date)
  values(result, item.target_type, item.target_id, target_date);
  idx := idx + 1;
  slot_in_day := slot_in_day + 1;
  if slot_in_day >= day_capacity then
   day_pos := least(day_pos + 1, day_count);
   slot_in_day := 0;
   day_capacity := base_count + case when day_pos <= extra_count then 1 else 0 end;
  end if;
 end loop;

 return result;
end
$$;

grant execute on function public.plan_assignment_remaining(uuid) to authenticated;
