alter table public.material_decks add column if not exists max_reviews int;
alter table public.material_decks add column if not exists review_intervals int[] not null default array[1,3,7,14,30,60];
alter table public.material_decks add column if not exists reset_again_to_first boolean not null default false;
alter table public.material_decks add column if not exists deleted_at timestamptz;
alter table public.word_lists add column if not exists max_reviews int;
alter table public.word_lists add column if not exists review_intervals int[] not null default array[1,3,7,14,30,60];
alter table public.word_lists add column if not exists reset_again_to_first boolean not null default false;
alter table public.word_lists add column if not exists deleted_at timestamptz;
alter table public.material_item_states add column if not exists review_step int not null default 0;
alter table public.material_item_states add column if not exists is_completed boolean not null default false;
alter table public.word_card_states add column if not exists review_step int not null default 0;
alter table public.word_card_states add column if not exists is_completed boolean not null default false;

alter table public.material_decks drop constraint if exists material_decks_max_reviews_check;
alter table public.material_decks add constraint material_decks_max_reviews_check check(max_reviews is null or max_reviews>=0);
alter table public.word_lists drop constraint if exists word_lists_max_reviews_check;
alter table public.word_lists add constraint word_lists_max_reviews_check check(max_reviews is null or max_reviews>=0);

create or replace function public.review_rule_result(
  p_rating rating,
  p_step int,
  p_count int,
  p_max_reviews int,
  p_intervals int[],
  p_reset_again boolean
) returns jsonb
language plpgsql
immutable
as $$
declare
  intervals int[]:=case when coalesce(array_length(p_intervals,1),0)>0 then p_intervals else array[1,3,7,14,30,60] end;
  next_step int:=coalesce(p_step,0);
  next_count int:=coalesce(p_count,0)+1;
  days int:=0;
  idx int;
  completed boolean:=false;
begin
  if p_rating='again' then
    next_step:=case when p_reset_again then 0 else greatest(coalesce(p_step,0)-1,0) end;
    days:=0;
  elsif p_rating='hard' then
    next_step:=coalesce(p_step,0);
    days:=1;
  elsif p_rating='good' then
    next_step:=coalesce(p_step,0)+1;
    idx:=least(greatest(next_step,1),array_length(intervals,1));
    days:=intervals[idx];
  else
    next_step:=coalesce(p_step,0)+2;
    idx:=least(greatest(next_step,1),array_length(intervals,1));
    days:=intervals[idx];
  end if;

  completed:=p_max_reviews=0 or (p_max_reviews is not null and next_count>=p_max_reviews);
  return jsonb_build_object('step',next_step,'count',next_count,'days',days,'completed',completed);
end
$$;

drop function if exists public.review_target(text,uuid,rating,boolean);
create function public.review_target(p_type text,p_id uuid,p_rating rating,p_unknown boolean)returns jsonb language plpgsql security definer set search_path=public as $$
declare prior_count int:=0;prior_step int:=0;attempt_id uuid:=gen_random_uuid();v_deck_id uuid;v_source_id uuid;v_deck_title text;v_title_id uuid;all_count int;done_count int;exp_gained int:=0;new_titles jsonb:='[]'::jsonb;inserted_title uuid;target_kind text;rule jsonb;days int;next_count int;next_step int;completed boolean;max_reviews int;intervals int[];reset_again boolean;begin
 target_kind:=case when p_type='material'then'material_item'else'word_card'end;
 if p_type='material'then
  select n.deck_id,coalesce(s.review_count,0),coalesce(s.review_step,0),d.max_reviews,d.review_intervals,d.reset_again_to_first into v_deck_id,prior_count,prior_step,max_reviews,intervals,reset_again from material_nodes n join material_decks d on d.id=n.deck_id left join material_item_states s on s.material_node_id=n.id and s.user_id=auth.uid()where n.id=p_id and n.node_type='item'and d.user_id=auth.uid()and d.deleted_at is null;if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then insert into material_item_states(user_id,material_node_id,unknown_flag)values(auth.uid(),p_id,p_unknown)on conflict(user_id,material_node_id)do update set unknown_flag=p_unknown,updated_at=now();insert into material_attempts(id,user_id,material_node_id,rating,unknown_flag,action,actor_id,actor_role)values(attempt_id,auth.uid(),p_id,null,p_unknown,'check',auth.uid(),'student');
  else rule:=public.review_rule_result(p_rating,prior_step,prior_count,max_reviews,intervals,reset_again);days:=(rule->>'days')::int;next_count:=(rule->>'count')::int;next_step:=(rule->>'step')::int;completed:=(rule->>'completed')::boolean;
   insert into material_item_states(user_id,material_node_id,last_rating,unknown_flag,review_count,review_step,is_completed,due_at,next_review_date)values(auth.uid(),p_id,p_rating,p_unknown,next_count,next_step,completed,case when completed then null else now()+make_interval(days=>days)end,case when completed then null else current_date+days end)on conflict(user_id,material_node_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=next_count,review_step=next_step,is_completed=completed,due_at=case when completed then null else now()+make_interval(days=>days)end,next_review_date=case when completed then null else current_date+days end,updated_at=now();
   insert into material_attempts(id,user_id,material_node_id,rating,unknown_flag,action,actor_id,actor_role)values(attempt_id,auth.uid(),p_id,p_rating,p_unknown,'review',auth.uid(),'student');if grant_exp(5,'material_rating',attempt_id::text)then exp_gained:=exp_gained+5;end if;if prior_count>0 and grant_exp(5,'review_complete',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   select count(*)into all_count from material_nodes where deck_id=v_deck_id and node_type='item';select count(*)into done_count from material_item_states s join material_nodes n on n.id=s.material_node_id where n.deck_id=v_deck_id and s.user_id=auth.uid()and s.last_rating is not null;
   if all_count>0 and done_count=all_count and grant_exp(50,'deck_complete','material:'||v_deck_id::text)then exp_gained:=exp_gained+50;select coalesce(d.source_content_id,d.id),coalesce(src.published_snapshot->>'title',d.title)into v_source_id,v_deck_title from material_decks d left join material_decks src on src.id=d.source_content_id where d.id=v_deck_id;insert into titles(title_key,display_name,title_type,condition_json)values('deck_completion:material:'||v_source_id::text,v_deck_title,'deck_completion',jsonb_build_object('source_type','material','source_id',v_source_id))on conflict(title_key)do update set display_name=excluded.display_name,condition_json=excluded.condition_json returning id into v_title_id;inserted_title:=null;insert into user_titles(user_id,title_id,source_type,source_id)values(auth.uid(),v_title_id,'material',v_source_id)on conflict do nothing returning id into inserted_title;if inserted_title is not null then update profiles set equipped_title_id=v_title_id where id=auth.uid();new_titles:=new_titles||jsonb_build_array(v_deck_title);end if;end if;
  end if;
 else
  select c.list_id,coalesce(s.review_count,0),coalesce(s.review_step,0),l.max_reviews,l.review_intervals,l.reset_again_to_first into v_deck_id,prior_count,prior_step,max_reviews,intervals,reset_again from word_cards c join word_lists l on l.id=c.list_id left join word_card_states s on s.word_card_id=c.id and s.user_id=auth.uid()where c.id=p_id and l.user_id=auth.uid()and l.deleted_at is null;if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then insert into word_card_states(user_id,word_card_id,unknown_flag)values(auth.uid(),p_id,p_unknown)on conflict(user_id,word_card_id)do update set unknown_flag=p_unknown,updated_at=now();insert into word_attempts(id,user_id,word_card_id,rating,unknown_flag,action,actor_id,actor_role)values(attempt_id,auth.uid(),p_id,null,p_unknown,'check',auth.uid(),'student');
  else rule:=public.review_rule_result(p_rating,prior_step,prior_count,max_reviews,intervals,reset_again);days:=(rule->>'days')::int;next_count:=(rule->>'count')::int;next_step:=(rule->>'step')::int;completed:=(rule->>'completed')::boolean;
   insert into word_card_states(user_id,word_card_id,last_rating,unknown_flag,review_count,review_step,is_completed,due_at,next_review_date)values(auth.uid(),p_id,p_rating,p_unknown,next_count,next_step,completed,case when completed then null else now()+make_interval(days=>days)end,case when completed then null else current_date+days end)on conflict(user_id,word_card_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=next_count,review_step=next_step,is_completed=completed,due_at=case when completed then null else now()+make_interval(days=>days)end,next_review_date=case when completed then null else current_date+days end,updated_at=now();
   insert into word_attempts(id,user_id,word_card_id,rating,unknown_flag,action,actor_id,actor_role)values(attempt_id,auth.uid(),p_id,p_rating,p_unknown,'review',auth.uid(),'student');if grant_exp(3,'word_rating',attempt_id::text)then exp_gained:=exp_gained+3;end if;if prior_count>0 and grant_exp(5,'review_complete',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   select count(*)into all_count from word_cards where list_id=v_deck_id;select count(*)into done_count from word_card_states s join word_cards c on c.id=s.word_card_id where c.list_id=v_deck_id and s.user_id=auth.uid()and s.last_rating is not null;
   if all_count>0 and done_count=all_count and grant_exp(50,'deck_complete','cards:'||v_deck_id::text)then exp_gained:=exp_gained+50;select coalesce(l.source_content_id,l.id),coalesce(src.published_snapshot->>'title',l.title)into v_source_id,v_deck_title from word_lists l left join word_lists src on src.id=l.source_content_id where l.id=v_deck_id;insert into titles(title_key,display_name,title_type,condition_json)values('deck_completion:cards:'||v_source_id::text,v_deck_title,'deck_completion',jsonb_build_object('source_type','cards','source_id',v_source_id))on conflict(title_key)do update set display_name=excluded.display_name,condition_json=excluded.condition_json returning id into v_title_id;inserted_title:=null;insert into user_titles(user_id,title_id,source_type,source_id)values(auth.uid(),v_title_id,'cards',v_source_id)on conflict do nothing returning id into inserted_title;if inserted_title is not null then update profiles set equipped_title_id=v_title_id where id=auth.uid();new_titles:=new_titles||jsonb_build_array(v_deck_title);end if;end if;
  end if;
 end if;
 if p_rating is not null then
  update assignment_items ai set status='done',completed_at=coalesce(completed_at,now())from assignments a where a.id=ai.assignment_id and a.student_id=auth.uid()and ai.target_type=target_kind and ai.target_id=p_id and ai.status='assigned';
  update assignments a set status='completed',updated_at=now()where a.student_id=auth.uid()and status='active'and not exists(select 1 from assignment_items ai where ai.assignment_id=a.id and ai.status<>'done');
  update study_plan_items spi set status='done',completed_at=coalesce(completed_at,now())from study_plans sp where sp.id=spi.plan_id and sp.user_id=auth.uid()and spi.target_type=target_kind and spi.target_id=p_id and spi.status='planned';
  if(exists(select 1 from material_attempts where user_id=auth.uid()and rating is not null and reviewed_at::date=current_date-1)or exists(select 1 from word_attempts where user_id=auth.uid()and rating is not null and reviewed_at::date=current_date-1))and grant_exp(10,'daily_streak',current_date::text)then exp_gained:=exp_gained+10;end if;
  new_titles:=new_titles||public.sync_exp_titles()||public.sync_streak_titles();
 end if;
 return jsonb_build_object('exp_gained',exp_gained,'new_titles',new_titles,'deck_completed',coalesce(all_count>0 and done_count=all_count,false));
end$$;

drop function if exists public.review_target_for_student(uuid,text,uuid,rating,boolean);
create function public.review_target_for_student(p_student_id uuid,p_type text,p_id uuid,p_rating rating,p_unknown boolean)returns jsonb language plpgsql security definer set search_path=public as $$
declare days int;target_kind text;v_deck_id uuid;prior_count int:=0;prior_step int:=0;rule jsonb;next_count int;next_step int;completed boolean;max_reviews int;intervals int[];reset_again boolean;begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid()and student_id=p_student_id and status='active')then raise exception'not allowed';end if;
 target_kind:=case when p_type='material'then'material_item'else'word_card'end;
 if p_type='material'then
  select n.deck_id,coalesce(s.review_count,0),coalesce(s.review_step,0),d.max_reviews,d.review_intervals,d.reset_again_to_first into v_deck_id,prior_count,prior_step,max_reviews,intervals,reset_again from material_nodes n join material_decks d on d.id=n.deck_id left join material_item_states s on s.material_node_id=n.id and s.user_id=p_student_id where n.id=p_id and n.node_type='item'and d.user_id=p_student_id and d.deleted_at is null;
  if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then insert into material_item_states(user_id,material_node_id,unknown_flag)values(p_student_id,p_id,p_unknown)on conflict(user_id,material_node_id)do update set unknown_flag=p_unknown,updated_at=now();insert into material_attempts(user_id,material_node_id,rating,unknown_flag,action,actor_id,actor_role)values(p_student_id,p_id,null,p_unknown,'check',auth.uid(),'teacher');
  else rule:=public.review_rule_result(p_rating,prior_step,prior_count,max_reviews,intervals,reset_again);days:=(rule->>'days')::int;next_count:=(rule->>'count')::int;next_step:=(rule->>'step')::int;completed:=(rule->>'completed')::boolean;insert into material_item_states(user_id,material_node_id,last_rating,unknown_flag,review_count,review_step,is_completed,due_at,next_review_date)values(p_student_id,p_id,p_rating,p_unknown,next_count,next_step,completed,case when completed then null else now()+make_interval(days=>days)end,case when completed then null else current_date+days end)on conflict(user_id,material_node_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=next_count,review_step=next_step,is_completed=completed,due_at=case when completed then null else now()+make_interval(days=>days)end,next_review_date=case when completed then null else current_date+days end,updated_at=now();insert into material_attempts(user_id,material_node_id,rating,unknown_flag,action,actor_id,actor_role)values(p_student_id,p_id,p_rating,p_unknown,'review',auth.uid(),'teacher');end if;
 else
  select c.list_id,coalesce(s.review_count,0),coalesce(s.review_step,0),l.max_reviews,l.review_intervals,l.reset_again_to_first into v_deck_id,prior_count,prior_step,max_reviews,intervals,reset_again from word_cards c join word_lists l on l.id=c.list_id left join word_card_states s on s.word_card_id=c.id and s.user_id=p_student_id where c.id=p_id and l.user_id=p_student_id and l.deleted_at is null;
  if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then insert into word_card_states(user_id,word_card_id,unknown_flag)values(p_student_id,p_id,p_unknown)on conflict(user_id,word_card_id)do update set unknown_flag=p_unknown,updated_at=now();insert into word_attempts(user_id,word_card_id,rating,unknown_flag,action,actor_id,actor_role)values(p_student_id,p_id,null,p_unknown,'check',auth.uid(),'teacher');
  else rule:=public.review_rule_result(p_rating,prior_step,prior_count,max_reviews,intervals,reset_again);days:=(rule->>'days')::int;next_count:=(rule->>'count')::int;next_step:=(rule->>'step')::int;completed:=(rule->>'completed')::boolean;insert into word_card_states(user_id,word_card_id,last_rating,unknown_flag,review_count,review_step,is_completed,due_at,next_review_date)values(p_student_id,p_id,p_rating,p_unknown,next_count,next_step,completed,case when completed then null else now()+make_interval(days=>days)end,case when completed then null else current_date+days end)on conflict(user_id,word_card_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=next_count,review_step=next_step,is_completed=completed,due_at=case when completed then null else now()+make_interval(days=>days)end,next_review_date=case when completed then null else current_date+days end,updated_at=now();insert into word_attempts(user_id,word_card_id,rating,unknown_flag,action,actor_id,actor_role)values(p_student_id,p_id,p_rating,p_unknown,'review',auth.uid(),'teacher');end if;
 end if;
 if p_rating is not null then
  update assignment_items ai set status='done',completed_at=coalesce(completed_at,now())from assignments a where a.id=ai.assignment_id and a.student_id=p_student_id and ai.target_type=target_kind and ai.target_id=p_id and ai.status='assigned';
  update assignments a set status='completed',updated_at=now()where a.student_id=p_student_id and status='active'and not exists(select 1 from assignment_items ai where ai.assignment_id=a.id and ai.status<>'done');
  update study_plan_items spi set status='done',completed_at=coalesce(completed_at,now())from study_plans sp where sp.id=spi.plan_id and sp.user_id=p_student_id and spi.target_type=target_kind and spi.target_id=p_id and spi.status='planned';
 end if;
 return jsonb_build_object('exp_gained',0,'new_titles','[]'::jsonb,'deck_completed',false);
end$$;
grant execute on function public.review_target_for_student(uuid,text,uuid,rating,boolean) to authenticated;

create or replace function public.copy_shared_material_for_student(p_token text,p_student_id uuid)returns uuid language plpgsql security definer set search_path=public as $$
declare source_id uuid;new_deck uuid;snap jsonb;version int;n record;new_node uuid;node_map jsonb:='{}';begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid()and student_id=p_student_id and status='active')then raise exception'not allowed';end if;
 select id,case when visibility='approved'then published_snapshot else public.content_snapshot('material',id)end,published_snapshot_version into source_id,snap,version from material_decks where share_token=p_token and visibility in('unlisted','approved');
 if source_id is null then raise exception'not found';end if;
 insert into material_decks(user_id,title,description,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)select p_student_id,snap->>'title',snap->>'description',p_student_id,source_id,source_id,version,max_reviews,review_intervals,reset_again_to_first from material_decks where id=source_id returning id into new_deck;
 for n in select*from jsonb_to_recordset(coalesce(snap->'nodes','[]'::jsonb))as x(id uuid,parent_id uuid,node_type text,title text,memo text,order_index int)order by coalesce(parent_id,id),order_index,title loop
  insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)values(new_deck,case when n.parent_id is null then null else(node_map->>n.parent_id::text)::uuid end,n.node_type,n.title,n.memo,coalesce(n.order_index,0))returning id into new_node;
  node_map:=node_map||jsonb_build_object(n.id::text,new_node::text);
 end loop;
 update material_decks set copy_count=copy_count+1,last_copied_at=now()where id=source_id;
 return new_deck;
end$$;

create or replace function public.copy_shared_cards_for_student(p_token text,p_student_id uuid)returns uuid language plpgsql security definer set search_path=public as $$
declare source_id uuid;new_list uuid;snap jsonb;version int;begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid()and student_id=p_student_id and status='active')then raise exception'not allowed';end if;
 select id,case when visibility='approved'then published_snapshot else public.content_snapshot('cards',id)end,published_snapshot_version into source_id,snap,version from word_lists where share_token=p_token and visibility in('unlisted','approved');
 if source_id is null then raise exception'not found';end if;
 insert into word_lists(user_id,title,description,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)select p_student_id,snap->>'title',snap->>'description',p_student_id,source_id,source_id,version,max_reviews,review_intervals,reset_again_to_first from word_lists where id=source_id returning id into new_list;
 insert into word_cards(list_id,card_id,front,back,memo,order_index)select new_list,card_id,front,back,memo,coalesce(order_index,0)from jsonb_to_recordset(coalesce(snap->'cards','[]'::jsonb))as x(card_id text,front text,back text,memo text,order_index int);
 update word_lists set copy_count=copy_count+1,last_copied_at=now()where id=source_id;
 return new_list;
end$$;
grant execute on function public.copy_shared_material_for_student(text,uuid) to authenticated;
grant execute on function public.copy_shared_cards_for_student(text,uuid) to authenticated;

create or replace function public.delete_owned_content(p_type text,p_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if auth.uid() is null then raise exception 'login required'; end if;
  if p_type='material' then
    update public.material_decks set deleted_at=coalesce(deleted_at,now()),updated_at=now()
    where id=p_id and user_id=auth.uid();
    if not found then raise exception 'not allowed'; end if;
  elsif p_type='word' or p_type='cards' then
    update public.word_lists set deleted_at=coalesce(deleted_at,now()),updated_at=now()
    where id=p_id and user_id=auth.uid();
    if not found then raise exception 'not allowed'; end if;
  else
    raise exception 'invalid content type';
  end if;
end
$$;
grant execute on function public.delete_owned_content(text,uuid) to authenticated;
