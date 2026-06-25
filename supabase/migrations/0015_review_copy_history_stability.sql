create table if not exists public.textbook_masters(
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subject text,
  publisher text,
  created_at timestamptz not null default now()
);

alter table public.material_decks add column if not exists textbook_master_id uuid references public.textbook_masters(id);
alter table public.material_decks add column if not exists edition_label text;
alter table public.word_lists add column if not exists textbook_master_id uuid references public.textbook_masters(id);
alter table public.word_lists add column if not exists edition_label text;
grant update(title,subject,description,edition_label,textbook_master_id,updated_at) on public.material_decks to authenticated;
grant update(title,subject,description,edition_label,textbook_master_id,updated_at) on public.word_lists to authenticated;

update public.material_item_states set is_completed=false where is_completed is null;
update public.word_card_states set is_completed=false where is_completed is null;
update public.material_item_states set review_step=0 where review_step is null;
update public.word_card_states set review_step=0 where review_step is null;
alter table public.material_item_states alter column is_completed set default false;
alter table public.word_card_states alter column is_completed set default false;
alter table public.material_item_states alter column review_step set default 0;
alter table public.word_card_states alter column review_step set default 0;
alter table public.material_item_states alter column is_completed set not null;
alter table public.word_card_states alter column is_completed set not null;
alter table public.material_item_states alter column review_step set not null;
alter table public.word_card_states alter column review_step set not null;

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

  completed:=coalesce(p_max_reviews=0,false) or (p_max_reviews is not null and next_count>=p_max_reviews);
  return jsonb_build_object('step',next_step,'count',next_count,'days',days,'completed',coalesce(completed,false));
end
$$;

create or replace function public.content_snapshot(p_type text,p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path=public
as $$
declare result jsonb;
begin
 if p_type='material' then
  select jsonb_build_object(
    'title',d.title,
    'description',d.description,
    'edition_label',d.edition_label,
    'textbook_master_id',d.textbook_master_id,
    'nodes',coalesce((
      with recursive tree as(
        select n.*,0 depth,array[coalesce(n.order_index,0)] sort_path
        from material_nodes n
        where n.deck_id=d.id and n.parent_id is null
        union all
        select child.*,tree.depth+1,tree.sort_path||coalesce(child.order_index,0)
        from material_nodes child
        join tree on child.parent_id=tree.id
        where child.deck_id=d.id
      )
      select jsonb_agg(jsonb_build_object(
        'id',id,
        'parent_id',parent_id,
        'node_type',node_type,
        'title',title,
        'memo',memo,
        'order_index',order_index
      ) order by depth,sort_path,title,created_at)
      from tree
    ),'[]'::jsonb)
  ) into result
  from material_decks d
  where d.id=p_id;
 else
  select jsonb_build_object(
    'title',l.title,
    'description',l.description,
    'edition_label',l.edition_label,
    'textbook_master_id',l.textbook_master_id,
    'cards',coalesce((
      select jsonb_agg(jsonb_build_object(
        'card_id',c.card_id,
        'front',c.front,
        'back',c.back,
        'memo',c.memo,
        'order_index',c.order_index
      ) order by coalesce(c.order_index,0),c.card_id,c.front,c.created_at)
      from word_cards c
      where c.list_id=l.id
    ),'[]'::jsonb)
  ) into result
  from word_lists l
  where l.id=p_id;
 end if;
 return result;
end
$$;
revoke all on function public.content_snapshot(text,uuid) from public,anon,authenticated;

create or replace function public.copy_shared_material(p_token text)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;new_deck uuid;snap jsonb;version int;n record;new_node uuid;node_map jsonb:='{}';
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,case when visibility='approved' then published_snapshot else public.content_snapshot('material',id) end,published_snapshot_version
 into source_id,snap,version
 from material_decks
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 insert into material_decks(user_id,title,description,edition_label,textbook_master_id,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)
 select auth.uid(),snap->>'title',snap->>'description',snap->>'edition_label',(snap->>'textbook_master_id')::uuid,auth.uid(),source_id,source_id,version,max_reviews,review_intervals,reset_again_to_first
 from material_decks where id=source_id returning id into new_deck;
 for n in
  with recursive source as(
   select * from jsonb_to_recordset(coalesce(snap->'nodes','[]'::jsonb)) as x(id uuid,parent_id uuid,node_type text,title text,memo text,order_index int)
  ),tree as(
   select s.*,0 depth,array[coalesce(s.order_index,0)] sort_path from source s where parent_id is null
   union all
   select s.*,tree.depth+1,tree.sort_path||coalesce(s.order_index,0) from source s join tree on s.parent_id=tree.id
  )
  select * from tree order by depth,sort_path,title
 loop
  insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)
  values(new_deck,case when n.parent_id is null then null else (node_map->>n.parent_id::text)::uuid end,n.node_type,n.title,n.memo,coalesce(n.order_index,0))
  returning id into new_node;
  node_map:=node_map||jsonb_build_object(n.id::text,new_node::text);
 end loop;
 update material_decks set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_deck;
end
$$;

create or replace function public.copy_shared_cards(p_token text)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;new_list uuid;snap jsonb;version int;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,case when visibility='approved' then published_snapshot else public.content_snapshot('cards',id) end,published_snapshot_version
 into source_id,snap,version
 from word_lists
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 insert into word_lists(user_id,title,description,edition_label,textbook_master_id,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)
 select auth.uid(),snap->>'title',snap->>'description',snap->>'edition_label',(snap->>'textbook_master_id')::uuid,auth.uid(),source_id,source_id,version,max_reviews,review_intervals,reset_again_to_first
 from word_lists where id=source_id returning id into new_list;
 insert into word_cards(list_id,card_id,front,back,memo,order_index)
 select new_list,card_id,front,back,memo,coalesce(order_index,0)
 from jsonb_to_recordset(coalesce(snap->'cards','[]'::jsonb)) as x(card_id text,front text,back text,memo text,order_index int);
 update word_lists set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_list;
end
$$;

create or replace function public.copy_shared_material_for_student(p_token text,p_student_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;new_deck uuid;snap jsonb;version int;n record;new_node uuid;node_map jsonb:='{}';
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 select id,case when visibility='approved' then published_snapshot else public.content_snapshot('material',id) end,published_snapshot_version
 into source_id,snap,version
 from material_decks
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 insert into material_decks(user_id,title,description,edition_label,textbook_master_id,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)
 select p_student_id,snap->>'title',snap->>'description',snap->>'edition_label',(snap->>'textbook_master_id')::uuid,p_student_id,source_id,source_id,version,max_reviews,review_intervals,reset_again_to_first
 from material_decks where id=source_id returning id into new_deck;
 for n in
  with recursive source as(
   select * from jsonb_to_recordset(coalesce(snap->'nodes','[]'::jsonb)) as x(id uuid,parent_id uuid,node_type text,title text,memo text,order_index int)
  ),tree as(
   select s.*,0 depth,array[coalesce(s.order_index,0)] sort_path from source s where parent_id is null
   union all
   select s.*,tree.depth+1,tree.sort_path||coalesce(s.order_index,0) from source s join tree on s.parent_id=tree.id
  )
  select * from tree order by depth,sort_path,title
 loop
  insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)
  values(new_deck,case when n.parent_id is null then null else (node_map->>n.parent_id::text)::uuid end,n.node_type,n.title,n.memo,coalesce(n.order_index,0))
  returning id into new_node;
  node_map:=node_map||jsonb_build_object(n.id::text,new_node::text);
 end loop;
 update material_decks set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_deck;
end
$$;

create or replace function public.copy_shared_cards_for_student(p_token text,p_student_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;new_list uuid;snap jsonb;version int;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 select id,case when visibility='approved' then published_snapshot else public.content_snapshot('cards',id) end,published_snapshot_version
 into source_id,snap,version
 from word_lists
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 insert into word_lists(user_id,title,description,edition_label,textbook_master_id,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)
 select p_student_id,snap->>'title',snap->>'description',snap->>'edition_label',(snap->>'textbook_master_id')::uuid,p_student_id,source_id,source_id,version,max_reviews,review_intervals,reset_again_to_first
 from word_lists where id=source_id returning id into new_list;
 insert into word_cards(list_id,card_id,front,back,memo,order_index)
 select new_list,card_id,front,back,memo,coalesce(order_index,0)
 from jsonb_to_recordset(coalesce(snap->'cards','[]'::jsonb)) as x(card_id text,front text,back text,memo text,order_index int);
 update word_lists set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_list;
end
$$;
grant execute on function public.copy_shared_material_for_student(text,uuid) to authenticated;
grant execute on function public.copy_shared_cards_for_student(text,uuid) to authenticated;

create or replace function public.update_copied_content(p_type text,p_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;snap jsonb;version int;n record;new_node uuid;node_map jsonb:='{}';
begin
 if p_type='material' then
  select copied_from_deck_id into source_id from material_decks where id=p_id and user_id=auth.uid() and deleted_at is null;
  if source_id is null then raise exception '更新元がありません'; end if;
  select published_snapshot,published_snapshot_version into snap,version from material_decks where id=source_id and visibility='approved' and deleted_at is null;
  if snap is null then raise exception '公開版が見つかりません'; end if;
  update material_decks set title=snap->>'title',description=snap->>'description',edition_label=snap->>'edition_label',textbook_master_id=(snap->>'textbook_master_id')::uuid,copied_snapshot_version=version,updated_at=now() where id=p_id and user_id=auth.uid();
  delete from material_nodes where deck_id=p_id and id not in(select material_node_id from material_item_states where user_id=auth.uid());
  for n in
   with recursive source as(
    select * from jsonb_to_recordset(coalesce(snap->'nodes','[]'::jsonb)) as x(id uuid,parent_id uuid,node_type text,title text,memo text,order_index int)
   ),tree as(
    select s.*,0 depth,array[coalesce(s.order_index,0)] sort_path from source s where parent_id is null
    union all
    select s.*,tree.depth+1,tree.sort_path||coalesce(s.order_index,0) from source s join tree on s.parent_id=tree.id
   )
   select * from tree order by depth,sort_path,title
  loop
   insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)
   values(p_id,case when n.parent_id is null then null else (node_map->>n.parent_id::text)::uuid end,n.node_type,n.title,n.memo,coalesce(n.order_index,0))
   returning id into new_node;
   node_map:=node_map||jsonb_build_object(n.id::text,new_node::text);
  end loop;
 else
  select copied_from_deck_id into source_id from word_lists where id=p_id and user_id=auth.uid() and deleted_at is null;
  if source_id is null then raise exception '更新元がありません'; end if;
  select published_snapshot,published_snapshot_version into snap,version from word_lists where id=source_id and visibility='approved' and deleted_at is null;
  if snap is null then raise exception '公開版が見つかりません'; end if;
  update word_lists set title=snap->>'title',description=snap->>'description',edition_label=snap->>'edition_label',textbook_master_id=(snap->>'textbook_master_id')::uuid,copied_snapshot_version=version,updated_at=now() where id=p_id and user_id=auth.uid();
  delete from word_cards where list_id=p_id and id not in(select word_card_id from word_card_states where user_id=auth.uid());
  insert into word_cards(list_id,card_id,front,back,memo,order_index)
  select p_id,card_id,front,back,memo,coalesce(order_index,0)
  from jsonb_to_recordset(coalesce(snap->'cards','[]'::jsonb)) as x(card_id text,front text,back text,memo text,order_index int);
 end if;
end
$$;
grant execute on function public.update_copied_content(text,uuid) to authenticated;

drop function if exists public.library_items(text,text);
create function public.library_items(p_query text default'',p_type text default'all')
returns table(content_type text,id uuid,title text,creator_name text,item_count bigint,copy_count int,updated_at timestamptz,share_token text,clear_titles jsonb,description text,edition_label text)
language sql
stable
security definer
set search_path=public
as $$
 select * from (
  select
   'material'::text content_type,
   d.id,
   (d.published_snapshot->>'title')::text title,
   ''::text creator_name,
   (select count(*) from jsonb_array_elements(coalesce(d.published_snapshot->'nodes','[]'::jsonb)) n where n->>'node_type'='item')::bigint item_count,
   d.copy_count::int,
   coalesce(d.approved_at,d.updated_at,d.created_at)::timestamptz updated_at,
   d.share_token::text,
   coalesce((select jsonb_agg(jsonb_build_object('name',q.display_name,'count',q.cnt) order by q.cnt desc) from (select t.display_name,count(*)::int cnt from user_titles ut join titles t on t.id=ut.title_id where t.title_type='deck_completion' and ut.source_type='material' and ut.source_id=d.id group by t.display_name having count(*)>=3) q),'[]'::jsonb) clear_titles,
   (d.published_snapshot->>'description')::text description,
   (d.published_snapshot->>'edition_label')::text edition_label
  from material_decks d
  where d.visibility='approved' and d.published_snapshot is not null and d.deleted_at is null and p_type in('all','material') and (p_query='' or d.published_snapshot->>'title' ilike '%'||p_query||'%')
  union all
  select
   'cards'::text content_type,
   l.id,
   (l.published_snapshot->>'title')::text title,
   ''::text creator_name,
   jsonb_array_length(coalesce(l.published_snapshot->'cards','[]'::jsonb))::bigint item_count,
   l.copy_count::int,
   coalesce(l.approved_at,l.updated_at,l.created_at)::timestamptz updated_at,
   l.share_token::text,
   coalesce((select jsonb_agg(jsonb_build_object('name',q.display_name,'count',q.cnt) order by q.cnt desc) from (select t.display_name,count(*)::int cnt from user_titles ut join titles t on t.id=ut.title_id where t.title_type='deck_completion' and ut.source_type='cards' and ut.source_id=l.id group by t.display_name having count(*)>=3) q),'[]'::jsonb) clear_titles,
   (l.published_snapshot->>'description')::text description,
   (l.published_snapshot->>'edition_label')::text edition_label
  from word_lists l
  where l.visibility='approved' and l.published_snapshot is not null and l.deleted_at is null and p_type in('all','cards') and (p_query='' or l.published_snapshot->>'title' ilike '%'||p_query||'%')
 ) x
 order by updated_at desc
$$;

drop function if exists public.admin_submissions();
create function public.admin_submissions()
returns table(content_type text,id uuid,title text,creator_name text,item_count bigint,copy_count int,updated_at timestamptz,share_token text,description text,submitted_at timestamptz,rejected_reason text,submission_kind text,edition_label text)
language sql
stable
security definer
set search_path=public
as $$
 select 'material'::text,d.id,(d.pending_snapshot->>'title')::text,''::text,(select count(*) from jsonb_array_elements(coalesce(d.pending_snapshot->'nodes','[]'::jsonb)) n where n->>'node_type'='item')::bigint,d.copy_count::int,coalesce(d.updated_at,d.created_at)::timestamptz,d.share_token::text,(d.pending_snapshot->>'description')::text,d.submitted_at::timestamptz,d.rejected_reason::text,d.submission_kind::text,(d.pending_snapshot->>'edition_label')::text
 from material_decks d
 where d.pending_snapshot is not null and public.is_admin()
 union all
 select 'cards'::text,l.id,(l.pending_snapshot->>'title')::text,''::text,jsonb_array_length(coalesce(l.pending_snapshot->'cards','[]'::jsonb))::bigint,l.copy_count::int,coalesce(l.updated_at,l.created_at)::timestamptz,l.share_token::text,(l.pending_snapshot->>'description')::text,l.submitted_at::timestamptz,l.rejected_reason::text,l.submission_kind::text,(l.pending_snapshot->>'edition_label')::text
 from word_lists l
 where l.pending_snapshot is not null and public.is_admin()
 order by submitted_at
$$;

create or replace function public.delete_student_content(p_student_id uuid,p_type text,p_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 if p_type='material' then
  update material_decks set deleted_at=coalesce(deleted_at,now()),updated_at=now() where id=p_id and user_id=p_student_id;
  if not found then raise exception 'not allowed'; end if;
 elsif p_type='word' or p_type='cards' then
  update word_lists set deleted_at=coalesce(deleted_at,now()),updated_at=now() where id=p_id and user_id=p_student_id;
  if not found then raise exception 'not allowed'; end if;
 else
  raise exception 'invalid content type';
 end if;
end
$$;
grant execute on function public.delete_student_content(uuid,text,uuid) to authenticated;

create or replace function public.recalculate_review_state(p_type text,p_target_id uuid,p_user_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare a record;state_rating rating:=null;state_unknown boolean:=false;cnt int:=0;step int:=0;rule jsonb;days int;completed boolean:=false;due_date date:=null;due_ts timestamptz:=null;max_reviews int;intervals int[];reset_again boolean;
begin
 if p_type='material' then
  select d.max_reviews,d.review_intervals,d.reset_again_to_first into max_reviews,intervals,reset_again
  from material_nodes n join material_decks d on d.id=n.deck_id
  where n.id=p_target_id;
  for a in select * from material_attempts where user_id=p_user_id and material_node_id=p_target_id order by reviewed_at,created_at,id loop
   state_unknown:=coalesce(a.unknown_flag,false);
   if a.rating is not null then
    rule:=public.review_rule_result(a.rating,step,cnt,max_reviews,intervals,reset_again);
    cnt:=(rule->>'count')::int;step:=(rule->>'step')::int;days:=(rule->>'days')::int;completed:=coalesce((rule->>'completed')::boolean,false);
    state_rating:=a.rating;
    due_date:=case when completed then null else a.reviewed_at::date+days end;
    due_ts:=case when completed then null else a.reviewed_at+make_interval(days=>days) end;
   end if;
  end loop;
  if state_rating is null and cnt=0 and not exists(select 1 from material_attempts where user_id=p_user_id and material_node_id=p_target_id) then
   delete from material_item_states where user_id=p_user_id and material_node_id=p_target_id;
  else
   insert into material_item_states(user_id,material_node_id,last_rating,unknown_flag,review_count,review_step,is_completed,due_at,next_review_date)
   values(p_user_id,p_target_id,state_rating,state_unknown,cnt,step,coalesce(completed,false),due_ts,due_date)
   on conflict(user_id,material_node_id) do update set last_rating=excluded.last_rating,unknown_flag=excluded.unknown_flag,review_count=excluded.review_count,review_step=excluded.review_step,is_completed=excluded.is_completed,due_at=excluded.due_at,next_review_date=excluded.next_review_date,updated_at=now();
  end if;
 else
  select l.max_reviews,l.review_intervals,l.reset_again_to_first into max_reviews,intervals,reset_again
  from word_cards c join word_lists l on l.id=c.list_id
  where c.id=p_target_id;
  for a in select * from word_attempts where user_id=p_user_id and word_card_id=p_target_id order by reviewed_at,created_at,id loop
   state_unknown:=coalesce(a.unknown_flag,false);
   if a.rating is not null then
    rule:=public.review_rule_result(a.rating,step,cnt,max_reviews,intervals,reset_again);
    cnt:=(rule->>'count')::int;step:=(rule->>'step')::int;days:=(rule->>'days')::int;completed:=coalesce((rule->>'completed')::boolean,false);
    state_rating:=a.rating;
    due_date:=case when completed then null else a.reviewed_at::date+days end;
    due_ts:=case when completed then null else a.reviewed_at+make_interval(days=>days) end;
   end if;
  end loop;
  if state_rating is null and cnt=0 and not exists(select 1 from word_attempts where user_id=p_user_id and word_card_id=p_target_id) then
   delete from word_card_states where user_id=p_user_id and word_card_id=p_target_id;
  else
   insert into word_card_states(user_id,word_card_id,last_rating,unknown_flag,review_count,review_step,is_completed,due_at,next_review_date)
   values(p_user_id,p_target_id,state_rating,state_unknown,cnt,step,coalesce(completed,false),due_ts,due_date)
   on conflict(user_id,word_card_id) do update set last_rating=excluded.last_rating,unknown_flag=excluded.unknown_flag,review_count=excluded.review_count,review_step=excluded.review_step,is_completed=excluded.is_completed,due_at=excluded.due_at,next_review_date=excluded.next_review_date,updated_at=now();
  end if;
 end if;
end
$$;

create or replace function public.update_review_attempt(p_type text,p_attempt_id uuid,p_rating rating,p_unknown boolean)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare owner_id uuid;target_id uuid;
begin
 if p_type='material' then
  select user_id,material_node_id into owner_id,target_id from material_attempts where id=p_attempt_id;
  if owner_id is null then raise exception 'not found'; end if;
  if owner_id<>auth.uid() and not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=owner_id and status='active') then raise exception 'not allowed'; end if;
  update material_attempts set rating=p_rating,unknown_flag=p_unknown,action=case when p_rating is null then 'check' else 'review' end where id=p_attempt_id;
  perform public.recalculate_review_state('material',target_id,owner_id);
 else
  select user_id,word_card_id into owner_id,target_id from word_attempts where id=p_attempt_id;
  if owner_id is null then raise exception 'not found'; end if;
  if owner_id<>auth.uid() and not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=owner_id and status='active') then raise exception 'not allowed'; end if;
  update word_attempts set rating=p_rating,unknown_flag=p_unknown,action=case when p_rating is null then 'check' else 'review' end where id=p_attempt_id;
  perform public.recalculate_review_state('word',target_id,owner_id);
 end if;
end
$$;

create or replace function public.delete_review_attempt(p_type text,p_attempt_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare owner_id uuid;target_id uuid;
begin
 if p_type='material' then
  select user_id,material_node_id into owner_id,target_id from material_attempts where id=p_attempt_id;
  if owner_id is null then raise exception 'not found'; end if;
  if owner_id<>auth.uid() and not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=owner_id and status='active') then raise exception 'not allowed'; end if;
  delete from material_attempts where id=p_attempt_id;
  perform public.recalculate_review_state('material',target_id,owner_id);
 else
  select user_id,word_card_id into owner_id,target_id from word_attempts where id=p_attempt_id;
  if owner_id is null then raise exception 'not found'; end if;
  if owner_id<>auth.uid() and not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=owner_id and status='active') then raise exception 'not allowed'; end if;
  delete from word_attempts where id=p_attempt_id;
  perform public.recalculate_review_state('word',target_id,owner_id);
 end if;
end
$$;
grant execute on function public.update_review_attempt(text,uuid,rating,boolean) to authenticated;
grant execute on function public.delete_review_attempt(text,uuid) to authenticated;
