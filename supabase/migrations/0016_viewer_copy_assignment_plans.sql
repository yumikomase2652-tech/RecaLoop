create or replace function public.set_distribution(p_type text,p_id uuid,p_enabled boolean)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare token text;current_visibility text;
begin
 if p_type='material' then
  select visibility,share_token into current_visibility,token from material_decks where id=p_id and user_id=auth.uid() and deleted_at is null;
  if current_visibility is null then raise exception 'not allowed'; end if;
  if current_visibility='approved' then return token; end if;
  if current_visibility not in('private','unlisted','rejected') then raise exception 'この状態では配布設定を変更できません'; end if;
  update material_decks set visibility=case when p_enabled then 'unlisted' else 'private' end,is_public=p_enabled,updated_at=now() where id=p_id returning share_token into token;
 else
  select visibility,share_token into current_visibility,token from word_lists where id=p_id and user_id=auth.uid() and deleted_at is null;
  if current_visibility is null then raise exception 'not allowed'; end if;
  if current_visibility='approved' then return token; end if;
  if current_visibility not in('private','unlisted','rejected') then raise exception 'この状態では配布設定を変更できません'; end if;
  update word_lists set visibility=case when p_enabled then 'unlisted' else 'private' end,is_public=p_enabled,updated_at=now() where id=p_id returning share_token into token;
 end if;
 if token is null then raise exception 'not allowed'; end if;
 return token;
end
$$;

create or replace function public.copy_material_snapshot_to_user(p_source_id uuid,p_owner_id uuid,p_snapshot jsonb,p_version int)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare new_deck uuid;n record;new_node uuid;node_map jsonb:='{}';
begin
 insert into material_decks(user_id,title,description,edition_label,textbook_master_id,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)
 select p_owner_id,p_snapshot->>'title',p_snapshot->>'description',p_snapshot->>'edition_label',nullif(p_snapshot->>'textbook_master_id','')::uuid,p_owner_id,p_source_id,p_source_id,p_version,max_reviews,review_intervals,reset_again_to_first
 from material_decks where id=p_source_id returning id into new_deck;
 for n in
  with recursive source as(
   select * from jsonb_to_recordset(coalesce(p_snapshot->'nodes','[]'::jsonb)) as x(id uuid,parent_id uuid,node_type text,title text,memo text,order_index int)
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
 return new_deck;
end
$$;

create or replace function public.copy_cards_snapshot_to_user(p_source_id uuid,p_owner_id uuid,p_snapshot jsonb,p_version int)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare new_list uuid;
begin
 insert into word_lists(user_id,title,description,edition_label,textbook_master_id,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)
 select p_owner_id,p_snapshot->>'title',p_snapshot->>'description',p_snapshot->>'edition_label',nullif(p_snapshot->>'textbook_master_id','')::uuid,p_owner_id,p_source_id,p_source_id,p_version,max_reviews,review_intervals,reset_again_to_first
 from word_lists where id=p_source_id returning id into new_list;
 insert into word_cards(list_id,card_id,front,back,memo,order_index)
 select new_list,card_id,front,back,memo,coalesce(order_index,0)
 from jsonb_to_recordset(coalesce(p_snapshot->'cards','[]'::jsonb)) as x(card_id text,front text,back text,memo text,order_index int);
 return new_list;
end
$$;
revoke all on function public.copy_material_snapshot_to_user(uuid,uuid,jsonb,int) from public,anon,authenticated;
revoke all on function public.copy_cards_snapshot_to_user(uuid,uuid,jsonb,int) from public,anon,authenticated;

create or replace function public.copy_shared_material(p_token text)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;snap jsonb;version int;new_id uuid;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,case when visibility='approved' then published_snapshot else public.content_snapshot('material',id) end,published_snapshot_version
 into source_id,snap,version
 from material_decks where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 if snap is null or jsonb_array_length(coalesce(snap->'nodes','[]'::jsonb))=0 then
  snap:=public.content_snapshot('material',source_id);
 end if;
 new_id:=public.copy_material_snapshot_to_user(source_id,auth.uid(),snap,version);
 update material_decks set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_id;
end
$$;

create or replace function public.copy_shared_cards(p_token text)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;snap jsonb;version int;new_id uuid;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,case when visibility='approved' then published_snapshot else public.content_snapshot('cards',id) end,published_snapshot_version
 into source_id,snap,version
 from word_lists where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 if snap is null or jsonb_array_length(coalesce(snap->'cards','[]'::jsonb))=0 then
  snap:=public.content_snapshot('cards',source_id);
 end if;
 new_id:=public.copy_cards_snapshot_to_user(source_id,auth.uid(),snap,version);
 update word_lists set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_id;
end
$$;

create or replace function public.copy_shared_material_for_student(p_token text,p_student_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;snap jsonb;version int;new_id uuid;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 select id,case when visibility='approved' then published_snapshot else public.content_snapshot('material',id) end,published_snapshot_version
 into source_id,snap,version
 from material_decks where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 if snap is null or jsonb_array_length(coalesce(snap->'nodes','[]'::jsonb))=0 then
  snap:=public.content_snapshot('material',source_id);
 end if;
 new_id:=public.copy_material_snapshot_to_user(source_id,p_student_id,snap,version);
 update material_decks set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_id;
end
$$;

create or replace function public.copy_shared_cards_for_student(p_token text,p_student_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;snap jsonb;version int;new_id uuid;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 select id,case when visibility='approved' then published_snapshot else public.content_snapshot('cards',id) end,published_snapshot_version
 into source_id,snap,version
 from word_lists where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 if snap is null or jsonb_array_length(coalesce(snap->'cards','[]'::jsonb))=0 then
  snap:=public.content_snapshot('cards',source_id);
 end if;
 new_id:=public.copy_cards_snapshot_to_user(source_id,p_student_id,snap,version);
 update word_lists set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_id;
end
$$;
grant execute on function public.copy_shared_material_for_student(text,uuid) to authenticated;
grant execute on function public.copy_shared_cards_for_student(text,uuid) to authenticated;

create or replace function public.copy_owned_content_to_student(p_student_id uuid,p_type text,p_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare snap jsonb;version int;new_id uuid;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 if p_type='material' then
  if not exists(select 1 from material_decks where id=p_id and user_id=auth.uid() and deleted_at is null) then raise exception 'not found'; end if;
  snap:=public.content_snapshot('material',p_id);
  select published_snapshot_version into version from material_decks where id=p_id;
  new_id:=public.copy_material_snapshot_to_user(p_id,p_student_id,snap,version);
 else
  if not exists(select 1 from word_lists where id=p_id and user_id=auth.uid() and deleted_at is null) then raise exception 'not found'; end if;
  snap:=public.content_snapshot('cards',p_id);
  select published_snapshot_version into version from word_lists where id=p_id;
  new_id:=public.copy_cards_snapshot_to_user(p_id,p_student_id,snap,version);
 end if;
 return new_id;
end
$$;
grant execute on function public.copy_owned_content_to_student(uuid,text,uuid) to authenticated;

create or replace function public.plan_assignment_remaining(p_assignment_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare a record;result uuid;days date[];day_count int;remaining int;idx int:=0;item record;target_deck_type text:='material';target_deck_id uuid:=null;target_date date;
begin
 select * into a from assignments where id=p_assignment_id;
 if a.id is null then raise exception 'not found'; end if;
 if a.student_id<>auth.uid() and not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=a.student_id and status='active') then raise exception 'not allowed'; end if;
 if a.due_date<current_date then days:=array[current_date]; else select array_agg(d::date order by d) into days from generate_series(current_date,a.due_date,interval '1 day') d; end if;
 day_count:=greatest(coalesce(array_length(days,1),0),1);
 select count(*) into remaining from assignment_items where assignment_id=p_assignment_id and status<>'done';
 if remaining=0 then raise exception '未完了の課題がありません'; end if;
 select case when ai.target_type='word_card' then 'word' else 'material' end,
        case when ai.target_type='word_card' then c.list_id else n.deck_id end
 into target_deck_type,target_deck_id
 from assignment_items ai
 left join material_nodes n on n.id=ai.target_id and ai.target_type='material_item'
 left join word_cards c on c.id=ai.target_id and ai.target_type='word_card'
 where ai.assignment_id=p_assignment_id and ai.status<>'done'
 order by ai.created_at
 limit 1;
 insert into study_plans(user_id,deck_type,deck_id,title,start_date,end_date)
 values(a.student_id,target_deck_type,target_deck_id,'課題: '||a.title,current_date,a.due_date)
 returning id into result;
 for item in
  select ai.* from assignment_items ai
  left join material_nodes n on n.id=ai.target_id and ai.target_type='material_item'
  left join word_cards c on c.id=ai.target_id and ai.target_type='word_card'
  where ai.assignment_id=p_assignment_id and ai.status<>'done'
  order by coalesce(n.order_index,c.order_index,0),ai.created_at
 loop
  target_date:=days[least(floor((idx::numeric*day_count)/remaining)::int+1,day_count)];
  insert into study_plan_items(plan_id,target_type,target_id,scheduled_date)
  values(result,item.target_type,item.target_id,target_date);
  idx:=idx+1;
 end loop;
 return result;
end
$$;
grant execute on function public.plan_assignment_remaining(uuid) to authenticated;
