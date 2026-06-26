alter table public.assignments add column if not exists deck_type text;
alter table public.assignments add column if not exists deck_id uuid;

create or replace function public.create_assignment(p_student_id uuid,p_title text,p_due_date date,p_items jsonb)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
 result uuid;
 item jsonb;
 inferred_type text;
 inferred_deck uuid;
 next_type text;
 next_deck uuid;
begin
 if not exists(select 1 from profiles where id=auth.uid()and role='teacher')then raise exception'教師権限が必要です';end if;
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid()and student_id=p_student_id and status='active')then raise exception'連携済みの生徒ではありません';end if;
 for item in select * from jsonb_array_elements(p_items) loop
  if item->>'target_type'='material_item' then
   select 'material',deck_id into next_type,next_deck from material_nodes where id=(item->>'target_id')::uuid and node_type='item';
  else
   select 'word',list_id into next_type,next_deck from word_cards where id=(item->>'target_id')::uuid;
  end if;
  if next_deck is null then raise exception'課題対象が見つかりません';end if;
  if inferred_deck is null then
   inferred_type:=next_type; inferred_deck:=next_deck;
  elsif inferred_type<>next_type or inferred_deck<>next_deck then
   raise exception'1つの課題に複数デッキは指定できません';
  end if;
 end loop;
 insert into assignments(teacher_id,student_id,title,due_date,deck_type,deck_id)
 values(auth.uid(),p_student_id,p_title,p_due_date,inferred_type,inferred_deck)
 returning id into result;
 for item in select * from jsonb_array_elements(p_items) loop
  insert into assignment_items(assignment_id,target_type,target_id)values(result,item->>'target_type',(item->>'target_id')::uuid);
 end loop;
 return result;
end
$$;

create or replace function public.update_assignment(p_assignment_id uuid,p_title text,p_due_date date,p_items jsonb)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
 v_student_id uuid;
 item jsonb;
 inferred_type text;
 inferred_deck uuid;
 next_type text;
 next_deck uuid;
begin
 select student_id into v_student_id from assignments where id=p_assignment_id and teacher_id=auth.uid();
 if v_student_id is null then raise exception 'not allowed: assignment owner mismatch'; end if;
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid()and student_id=v_student_id and status='active')then
  raise exception 'not allowed: teacher is not linked to student';
 end if;
 for item in select * from jsonb_array_elements(p_items) loop
  if item->>'target_type'='material_item' then
   select 'material',deck_id into next_type,next_deck from material_nodes where id=(item->>'target_id')::uuid and node_type='item';
  else
   select 'word',list_id into next_type,next_deck from word_cards where id=(item->>'target_id')::uuid;
  end if;
  if next_deck is null then raise exception'課題対象が見つかりません';end if;
  if inferred_deck is null then
   inferred_type:=next_type; inferred_deck:=next_deck;
  elsif inferred_type<>next_type or inferred_deck<>next_deck then
   raise exception'1つの課題に複数デッキは指定できません';
  end if;
 end loop;
 update assignments
 set title=p_title,due_date=p_due_date,status='active',updated_at=now(),deck_type=inferred_type,deck_id=inferred_deck
 where id=p_assignment_id;
 delete from assignment_items ai
 where ai.assignment_id=p_assignment_id
   and not exists(select 1 from jsonb_array_elements(p_items) item where item->>'target_type'=ai.target_type and (item->>'target_id')::uuid=ai.target_id);
 for item in select * from jsonb_array_elements(p_items) loop
  if not exists(select 1 from assignment_items where assignment_id=p_assignment_id and target_type=item->>'target_type' and target_id=(item->>'target_id')::uuid)then
   insert into assignment_items(assignment_id,target_type,target_id)values(p_assignment_id,item->>'target_type',(item->>'target_id')::uuid);
  end if;
 end loop;
 update assignments a
 set status='completed',updated_at=now()
 where a.id=p_assignment_id
   and not exists(select 1 from assignment_items ai where ai.assignment_id=a.id and ai.status<>'done');
end
$$;

grant execute on function public.create_assignment(uuid,text,date,jsonb) to authenticated;
grant execute on function public.update_assignment(uuid,text,date,jsonb) to authenticated;
