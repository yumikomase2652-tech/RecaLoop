-- Teacher viewer mode needs linked read access to the student's learning data,
-- plus editable assignments.

alter table public.assignments add column if not exists updated_at timestamptz not null default now();
alter table public.material_attempts add column if not exists actor_id uuid references public.profiles(id) on delete set null;
alter table public.material_attempts add column if not exists actor_role text check(actor_role in('student','teacher'));
alter table public.word_attempts add column if not exists actor_id uuid references public.profiles(id) on delete set null;
alter table public.word_attempts add column if not exists actor_role text check(actor_role in('student','teacher'));

drop policy if exists "material decks linked teacher read" on public.material_decks;
create policy "material decks linked teacher read" on public.material_decks
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=material_decks.user_id
        and l.status='active'
    )
  );

drop policy if exists "material nodes linked teacher read" on public.material_nodes;
create policy "material nodes linked teacher read" on public.material_nodes
  for select using (
    exists (
      select 1
      from public.material_decks d
      join public.teacher_student_links l on l.student_id=d.user_id
      where d.id=material_nodes.deck_id
        and l.teacher_id=auth.uid()
        and l.status='active'
    )
  );

drop policy if exists "material states linked teacher read" on public.material_item_states;
create policy "material states linked teacher read" on public.material_item_states
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=material_item_states.user_id
        and l.status='active'
    )
  );

drop policy if exists "material attempts linked teacher read" on public.material_attempts;
create policy "material attempts linked teacher read" on public.material_attempts
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=material_attempts.user_id
        and l.status='active'
    )
  );

drop policy if exists "word lists linked teacher read" on public.word_lists;
create policy "word lists linked teacher read" on public.word_lists
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=word_lists.user_id
        and l.status='active'
    )
  );

drop policy if exists "word cards linked teacher read" on public.word_cards;
create policy "word cards linked teacher read" on public.word_cards
  for select using (
    exists (
      select 1
      from public.word_lists wl
      join public.teacher_student_links l on l.student_id=wl.user_id
      where wl.id=word_cards.list_id
        and l.teacher_id=auth.uid()
        and l.status='active'
    )
  );

drop policy if exists "word states linked teacher read" on public.word_card_states;
create policy "word states linked teacher read" on public.word_card_states
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=word_card_states.user_id
        and l.status='active'
    )
  );

drop policy if exists "word attempts linked teacher read" on public.word_attempts;
create policy "word attempts linked teacher read" on public.word_attempts
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=word_attempts.user_id
        and l.status='active'
    )
  );

drop policy if exists "study plans linked teacher read" on public.study_plans;
create policy "study plans linked teacher read" on public.study_plans
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=study_plans.user_id
        and l.status='active'
    )
  );

drop policy if exists "study plan items linked teacher read" on public.study_plan_items;
create policy "study plan items linked teacher read" on public.study_plan_items
  for select using (
    exists (
      select 1
      from public.study_plans p
      join public.teacher_student_links l on l.student_id=p.user_id
      where p.id=study_plan_items.plan_id
        and l.teacher_id=auth.uid()
        and l.status='active'
    )
  );

drop policy if exists "study plan items linked teacher update" on public.study_plan_items;
create policy "study plan items linked teacher update" on public.study_plan_items
  for update using (
    exists (
      select 1
      from public.study_plans p
      join public.teacher_student_links l on l.student_id=p.user_id
      where p.id=study_plan_items.plan_id
        and l.teacher_id=auth.uid()
        and l.status='active'
    )
  ) with check (
    exists (
      select 1
      from public.study_plans p
      join public.teacher_student_links l on l.student_id=p.user_id
      where p.id=study_plan_items.plan_id
        and l.teacher_id=auth.uid()
        and l.status='active'
    )
  );

drop policy if exists "study plan items linked teacher delete" on public.study_plan_items;
create policy "study plan items linked teacher delete" on public.study_plan_items
  for delete using (
    exists (
      select 1
      from public.study_plans p
      join public.teacher_student_links l on l.student_id=p.user_id
      where p.id=study_plan_items.plan_id
        and l.teacher_id=auth.uid()
        and l.status='active'
    )
  );

drop policy if exists "user titles linked teacher read" on public.user_titles;
create policy "user titles linked teacher read" on public.user_titles
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=user_titles.user_id
        and l.status='active'
    )
  );

drop policy if exists "exp transactions linked teacher read" on public.exp_transactions;
create policy "exp transactions linked teacher read" on public.exp_transactions
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=exp_transactions.user_id
        and l.status='active'
    )
  );

drop policy if exists "study sessions linked teacher read" on public.study_sessions;
create policy "study sessions linked teacher read" on public.study_sessions
  for select using (
    exists (
      select 1 from public.teacher_student_links l
      where l.teacher_id=auth.uid()
        and l.student_id=study_sessions.user_id
        and l.status='active'
    )
  );

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
    where n.id=p_id and n.node_type='item' and d.user_id=p_student_id;
    if v_deck_id is null then raise exception 'not allowed'; end if;

    if p_rating is null then
      insert into material_item_states(user_id,material_node_id,unknown_flag)
      values(p_student_id,p_id,p_unknown)
      on conflict(user_id,material_node_id)
      do update set unknown_flag=p_unknown,updated_at=now();
      insert into material_attempts(user_id,material_node_id,rating,unknown_flag,action,actor_id,actor_role)
      values(p_student_id,p_id,null,p_unknown,'check',auth.uid(),'teacher');
    else
      days:=case p_rating when 'again' then 0 when 'hard' then 1 when 'good' then 3 else 7 end;
      insert into material_item_states(user_id,material_node_id,last_rating,unknown_flag,review_count,due_at,next_review_date)
      values(p_student_id,p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)
      on conflict(user_id,material_node_id)
      do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=material_item_states.review_count+1,due_at=now()+make_interval(days=>days),next_review_date=current_date+days,updated_at=now();
      insert into material_attempts(user_id,material_node_id,rating,unknown_flag,action,actor_id,actor_role)
      values(p_student_id,p_id,p_rating,p_unknown,'review',auth.uid(),'teacher');
    end if;
  else
    select c.list_id into v_deck_id
    from word_cards c
    join word_lists l on l.id=c.list_id
    where c.id=p_id and l.user_id=p_student_id;
    if v_deck_id is null then raise exception 'not allowed'; end if;

    if p_rating is null then
      insert into word_card_states(user_id,word_card_id,unknown_flag)
      values(p_student_id,p_id,p_unknown)
      on conflict(user_id,word_card_id)
      do update set unknown_flag=p_unknown,updated_at=now();
      insert into word_attempts(user_id,word_card_id,rating,unknown_flag,action,actor_id,actor_role)
      values(p_student_id,p_id,null,p_unknown,'check',auth.uid(),'teacher');
    else
      days:=case p_rating when 'again' then 0 when 'hard' then 1 when 'good' then 3 else 7 end;
      insert into word_card_states(user_id,word_card_id,last_rating,unknown_flag,review_count,due_at,next_review_date)
      values(p_student_id,p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)
      on conflict(user_id,word_card_id)
      do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=word_card_states.review_count+1,due_at=now()+make_interval(days=>days),next_review_date=current_date+days,updated_at=now();
      insert into word_attempts(user_id,word_card_id,rating,unknown_flag,action,actor_id,actor_role)
      values(p_student_id,p_id,p_rating,p_unknown,'review',auth.uid(),'teacher');
    end if;
  end if;

  if p_rating is not null then
    update assignment_items ai set status='done',completed_at=coalesce(completed_at,now())
    from assignments a
    where a.id=ai.assignment_id
      and a.student_id=p_student_id
      and ai.target_type=target_kind
      and ai.target_id=p_id
      and ai.status='assigned';

    update assignments a set status='completed',updated_at=now()
    where a.student_id=p_student_id
      and status='active'
      and not exists(select 1 from assignment_items ai where ai.assignment_id=a.id and ai.status<>'done');

    update study_plan_items spi set status='done',completed_at=coalesce(completed_at,now())
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

create or replace function public.update_assignment(
  p_assignment_id uuid,
  p_title text,
  p_due_date date,
  p_items jsonb
) returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  v_student_id uuid;
  item jsonb;
begin
  select student_id into v_student_id
  from assignments
  where id=p_assignment_id and teacher_id=auth.uid();

  if v_student_id is null then raise exception 'not allowed'; end if;

  if not exists (
    select 1 from teacher_student_links
    where teacher_id=auth.uid()
      and student_id=v_student_id
      and status='active'
  ) then
    raise exception 'not allowed';
  end if;

  update assignments
  set title=p_title,due_date=p_due_date,status='active',updated_at=now()
  where id=p_assignment_id;

  delete from assignment_items ai
  where ai.assignment_id=p_assignment_id
    and not exists (
      select 1
      from jsonb_array_elements(p_items) item
      where item->>'target_type'=ai.target_type
        and (item->>'target_id')::uuid=ai.target_id
    );

  for item in select * from jsonb_array_elements(p_items) loop
    if not exists (
      select 1 from assignment_items
      where assignment_id=p_assignment_id
        and target_type=item->>'target_type'
        and target_id=(item->>'target_id')::uuid
    ) then
      insert into assignment_items(assignment_id,target_type,target_id)
      values(p_assignment_id,item->>'target_type',(item->>'target_id')::uuid);
    end if;
  end loop;

  update assignments a
  set status='completed',updated_at=now()
  where a.id=p_assignment_id
    and not exists(select 1 from assignment_items ai where ai.assignment_id=a.id and ai.status<>'done');
end
$$;

grant execute on function public.update_assignment(uuid,text,date,jsonb) to authenticated;

create or replace function public.delete_assignment(p_assignment_id uuid)
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
  where id=p_assignment_id and teacher_id=auth.uid();

  if v_student_id is null then raise exception 'not allowed'; end if;

  if not exists (
    select 1 from teacher_student_links
    where teacher_id=auth.uid()
      and student_id=v_student_id
      and status='active'
  ) then
    raise exception 'not allowed';
  end if;

  delete from assignments where id=p_assignment_id;
end
$$;

grant execute on function public.delete_assignment(uuid) to authenticated;

create or replace function public.start_study_session_for_student(
  p_student_id uuid,
  p_related_type text,
  p_related_id uuid
) returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
  result uuid;
begin
  if not exists (
    select 1 from teacher_student_links
    where teacher_id=auth.uid()
      and student_id=p_student_id
      and status='active'
  ) then
    raise exception 'not allowed';
  end if;

  insert into study_sessions(user_id,related_type,related_id)
  values(p_student_id,p_related_type,p_related_id)
  returning id into result;

  return result;
end
$$;

grant execute on function public.start_study_session_for_student(uuid,text,uuid) to authenticated;

create or replace function public.end_study_session_for_student(
  p_student_id uuid,
  p_session_id uuid
) returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not exists (
    select 1 from teacher_student_links
    where teacher_id=auth.uid()
      and student_id=p_student_id
      and status='active'
  ) then
    raise exception 'not allowed';
  end if;

  update study_sessions
  set ended_at=now(),
      duration_minutes=greatest(1,ceil(extract(epoch from(now()-started_at))/60)::int)
  where id=p_session_id
    and user_id=p_student_id
    and ended_at is null;
end
$$;

grant execute on function public.end_study_session_for_student(uuid,uuid) to authenticated;
