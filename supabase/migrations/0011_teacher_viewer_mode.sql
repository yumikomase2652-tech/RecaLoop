-- Teacher viewer mode: allow linked teachers to review a connected student's own items.
drop function if exists public.review_target_for_student(uuid,text,uuid,rating,boolean);
create function public.review_target_for_student(
  p_student_id uuid,
  p_type text,
  p_id uuid,
  p_rating rating,
  p_unknown boolean
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  days int;
  target_kind text;
  v_deck_id uuid;
begin
  if not exists (
    select 1 from teacher_student_links
    where teacher_id=auth.uid()
      and student_id=p_student_id
      and status='active'
  ) then
    raise exception 'not allowed';
  end if;

  target_kind:=case when p_type='material' then 'material_item' else 'word_card' end;

  if p_type='material' then
    select n.deck_id into v_deck_id
    from material_nodes n
    join material_decks d on d.id=n.deck_id
    where n.id=p_id
      and n.node_type='item'
      and d.user_id=p_student_id;

    if v_deck_id is null then
      raise exception 'not allowed';
    end if;

    if p_rating is null then
      insert into material_item_states(user_id,material_node_id,unknown_flag)
      values(p_student_id,p_id,p_unknown)
      on conflict(user_id,material_node_id)
      do update set unknown_flag=p_unknown,updated_at=now();

      insert into material_attempts(user_id,material_node_id,rating,unknown_flag,action)
      values(p_student_id,p_id,null,p_unknown,'check');
    else
      days:=case p_rating when 'again' then 0 when 'hard' then 1 when 'good' then 3 else 7 end;

      insert into material_item_states(user_id,material_node_id,last_rating,unknown_flag,review_count,due_at,next_review_date)
      values(p_student_id,p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)
      on conflict(user_id,material_node_id)
      do update set
        last_rating=p_rating,
        unknown_flag=p_unknown,
        review_count=material_item_states.review_count+1,
        due_at=now()+make_interval(days=>days),
        next_review_date=current_date+days,
        updated_at=now();

      insert into material_attempts(user_id,material_node_id,rating,unknown_flag,action)
      values(p_student_id,p_id,p_rating,p_unknown,'review');
    end if;
  else
    select c.list_id into v_deck_id
    from word_cards c
    join word_lists l on l.id=c.list_id
    where c.id=p_id
      and l.user_id=p_student_id;

    if v_deck_id is null then
      raise exception 'not allowed';
    end if;

    if p_rating is null then
      insert into word_card_states(user_id,word_card_id,unknown_flag)
      values(p_student_id,p_id,p_unknown)
      on conflict(user_id,word_card_id)
      do update set unknown_flag=p_unknown,updated_at=now();

      insert into word_attempts(user_id,word_card_id,rating,unknown_flag,action)
      values(p_student_id,p_id,null,p_unknown,'check');
    else
      days:=case p_rating when 'again' then 0 when 'hard' then 1 when 'good' then 3 else 7 end;

      insert into word_card_states(user_id,word_card_id,last_rating,unknown_flag,review_count,due_at,next_review_date)
      values(p_student_id,p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)
      on conflict(user_id,word_card_id)
      do update set
        last_rating=p_rating,
        unknown_flag=p_unknown,
        review_count=word_card_states.review_count+1,
        due_at=now()+make_interval(days=>days),
        next_review_date=current_date+days,
        updated_at=now();

      insert into word_attempts(user_id,word_card_id,rating,unknown_flag,action)
      values(p_student_id,p_id,p_rating,p_unknown,'review');
    end if;
  end if;

  if p_rating is not null then
    update assignment_items ai
      set status='done',completed_at=coalesce(completed_at,now())
    from assignments a
    where a.id=ai.assignment_id
      and a.student_id=p_student_id
      and ai.target_type=target_kind
      and ai.target_id=p_id
      and ai.status='assigned';

    update assignments a
      set status='completed'
    where a.student_id=p_student_id
      and status='active'
      and not exists (
        select 1 from assignment_items ai
        where ai.assignment_id=a.id
          and ai.status<>'done'
      );

    update study_plan_items spi
      set status='done',completed_at=coalesce(completed_at,now())
    from study_plans sp
    where sp.id=spi.plan_id
      and sp.user_id=p_student_id
      and spi.target_type=target_kind
      and spi.target_id=p_id
      and spi.status='planned';
  end if;

  return jsonb_build_object('exp_gained',0,'new_titles','[]'::jsonb,'deck_completed',false);
end
$$;

grant execute on function public.review_target_for_student(uuid,text,uuid,rating,boolean) to authenticated;
