-- Stop relying on client-side direct inserts for CSV import and make every copy path
-- validate that child rows were actually copied.

grant select,insert,update,delete on public.material_decks to authenticated;
grant select,insert,update,delete on public.material_nodes to authenticated;
grant select,insert,update,delete on public.word_lists to authenticated;
grant select,insert,update,delete on public.word_cards to authenticated;

drop policy if exists "material nodes own" on public.material_nodes;
create policy "material nodes own" on public.material_nodes
for all
using(exists(select 1 from public.material_decks d where d.id=deck_id and d.user_id=auth.uid()))
with check(exists(select 1 from public.material_decks d where d.id=deck_id and d.user_id=auth.uid()));

drop policy if exists "word cards own" on public.word_cards;
create policy "word cards own" on public.word_cards
for all
using(exists(select 1 from public.word_lists l where l.id=list_id and l.user_id=auth.uid()))
with check(exists(select 1 from public.word_lists l where l.id=list_id and l.user_id=auth.uid()));

create or replace function public.material_snapshot_item_count(p_snapshot jsonb)
returns int
language sql
immutable
as $$
 select count(*)::int
 from jsonb_array_elements(coalesce(p_snapshot->'nodes','[]'::jsonb)) n
 where n->>'node_type'='item'
$$;

create or replace function public.cards_snapshot_item_count(p_snapshot jsonb)
returns int
language sql
immutable
as $$
 select jsonb_array_length(coalesce(p_snapshot->'cards','[]'::jsonb))::int
$$;

create or replace function public.material_snapshot_for_copy(p_source_id uuid,p_prefer_published boolean)
returns jsonb
language plpgsql
stable
security definer
set search_path=public
as $$
declare snap jsonb;live jsonb;
begin
 select case when p_prefer_published then published_snapshot else null end into snap
 from material_decks
 where id=p_source_id;

 if snap is null or public.material_snapshot_item_count(snap)=0 then
  live:=public.content_snapshot('material',p_source_id);
  if public.material_snapshot_item_count(live)>0 then
   snap:=live;
  end if;
 end if;

 return snap;
end
$$;

create or replace function public.cards_snapshot_for_copy(p_source_id uuid,p_prefer_published boolean)
returns jsonb
language plpgsql
stable
security definer
set search_path=public
as $$
declare snap jsonb;live jsonb;
begin
 select case when p_prefer_published then published_snapshot else null end into snap
 from word_lists
 where id=p_source_id;

 if snap is null or public.cards_snapshot_item_count(snap)=0 then
  live:=public.content_snapshot('cards',p_source_id);
  if public.cards_snapshot_item_count(live)>0 then
   snap:=live;
  end if;
 end if;

 return snap;
end
$$;

revoke all on function public.material_snapshot_for_copy(uuid,boolean) from public,anon,authenticated;
revoke all on function public.cards_snapshot_for_copy(uuid,boolean) from public,anon,authenticated;

create or replace function public.import_material_nodes(p_deck_id uuid,p_nodes jsonb)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
 n record;
 new_id uuid;
 new_created timestamptz;
 parent_new_id uuid;
 node_map jsonb:='{}'::jsonb;
 out_rows jsonb:='[]'::jsonb;
 expected_items int:=0;
 copied_items int:=0;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 if not exists(select 1 from material_decks where id=p_deck_id and user_id=auth.uid() and deleted_at is null) then
  raise exception 'not allowed';
 end if;

 select count(*)::int into expected_items
 from jsonb_array_elements(coalesce(p_nodes,'[]'::jsonb)) e
 where e->>'node_type'='item';

 for n in
  select
   e.value->>'id' old_id,
   nullif(e.value->>'parent_id','') parent_old_id,
   coalesce(e.value->>'node_type','item') node_type,
   nullif(e.value->>'title','') title,
   nullif(e.value->>'memo','') memo,
   coalesce((e.value->>'order_index')::int,e.ord::int-1) order_index
  from jsonb_array_elements(coalesce(p_nodes,'[]'::jsonb)) with ordinality as e(value,ord)
  order by e.ord
 loop
  if n.title is null then
   continue;
  end if;
  if n.parent_old_id is null then
   parent_new_id:=null;
  else
   parent_new_id:=nullif(node_map->>n.parent_old_id,'')::uuid;
  end if;

  insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)
  values(p_deck_id,parent_new_id,case when n.node_type='folder' then 'folder' else 'item' end,n.title,n.memo,n.order_index)
  returning id,created_at into new_id,new_created;

  node_map:=node_map||jsonb_build_object(coalesce(n.old_id,new_id::text),new_id::text);
  if n.node_type='item' then copied_items:=copied_items+1; end if;

  out_rows:=out_rows||jsonb_build_array(jsonb_build_object(
   'id',new_id,
   'deck_id',p_deck_id,
   'parent_id',parent_new_id,
   'node_type',case when n.node_type='folder' then 'folder' else 'item' end,
   'title',n.title,
   'memo',n.memo,
   'order_index',n.order_index,
   'created_at',new_created
  ));
 end loop;

 if expected_items>0 and copied_items=0 then
  raise exception 'CSVの問題を保存できませんでした';
 end if;

 return out_rows;
end
$$;

create or replace function public.import_word_cards(p_list_id uuid,p_cards jsonb)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
 c record;
 new_id uuid;
 new_created timestamptz;
 out_rows jsonb:='[]'::jsonb;
 expected_cards int:=0;
 copied_cards int:=0;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 if not exists(select 1 from word_lists where id=p_list_id and user_id=auth.uid() and deleted_at is null) then
  raise exception 'not allowed';
 end if;

 select count(*)::int into expected_cards
 from jsonb_array_elements(coalesce(p_cards,'[]'::jsonb)) e
 where coalesce(e->>'front','')<>'' and coalesce(e->>'back','')<>'';

 for c in
  select
   nullif(e.value->>'card_id','') card_id,
   nullif(e.value->>'front','') front,
   nullif(e.value->>'back','') back,
   nullif(e.value->>'memo','') memo,
   coalesce((e.value->>'order_index')::int,e.ord::int-1) order_index
  from jsonb_array_elements(coalesce(p_cards,'[]'::jsonb)) with ordinality as e(value,ord)
  order by e.ord
 loop
  if c.front is null or c.back is null then
   continue;
  end if;

  insert into word_cards(list_id,card_id,front,back,memo,order_index)
  values(p_list_id,c.card_id,c.front,c.back,c.memo,c.order_index)
  returning id,created_at into new_id,new_created;
  copied_cards:=copied_cards+1;

  out_rows:=out_rows||jsonb_build_array(jsonb_build_object(
   'id',new_id,
   'list_id',p_list_id,
   'card_id',c.card_id,
   'front',c.front,
   'back',c.back,
   'memo',c.memo,
   'order_index',c.order_index,
   'created_at',new_created
  ));
 end loop;

 if expected_cards>0 and copied_cards=0 then
  raise exception 'CSVのカードを保存できませんでした';
 end if;

 return out_rows;
end
$$;

create or replace function public.copy_material_snapshot_to_user(p_source_id uuid,p_owner_id uuid,p_snapshot jsonb,p_version int)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
 new_deck uuid;
 n record;
 new_node uuid;
 node_map jsonb:='{}'::jsonb;
 source_items int:=public.material_snapshot_item_count(p_snapshot);
 copied_items int:=0;
begin
 if p_owner_id is null then raise exception 'copy owner is required'; end if;
 if p_snapshot is null or source_items=0 then raise exception 'コピーできる問題がありません'; end if;

 insert into material_decks(user_id,title,description,edition_label,textbook_master_id,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)
 select
  p_owner_id,
  coalesce(nullif(p_snapshot->>'title',''),d.title),
  coalesce(p_snapshot->>'description',d.description),
  coalesce(p_snapshot->>'edition_label',d.edition_label),
  coalesce(nullif(p_snapshot->>'textbook_master_id','')::uuid,d.textbook_master_id),
  p_owner_id,
  p_source_id,
  p_source_id,
  coalesce(p_version,0),
  d.max_reviews,
  d.review_intervals,
  d.reset_again_to_first
 from material_decks d
 where d.id=p_source_id
 returning id into new_deck;

 if new_deck is null then raise exception 'copy source not found'; end if;

 for n in
  with recursive source as(
   select
    e.value->>'id' old_id,
    nullif(e.value->>'parent_id','') parent_old_id,
    coalesce(e.value->>'node_type','item') node_type,
    nullif(e.value->>'title','') title,
    nullif(e.value->>'memo','') memo,
    coalesce((e.value->>'order_index')::int,e.ord::int-1) order_index,
    e.ord::int ord
   from jsonb_array_elements(coalesce(p_snapshot->'nodes','[]'::jsonb)) with ordinality as e(value,ord)
  ),tree as(
   select s.*,0 depth,array[s.ord] sort_path from source s where s.parent_old_id is null
   union all
   select s.*,tree.depth+1,tree.sort_path||s.ord from source s join tree on s.parent_old_id=tree.old_id
  )
  select * from tree order by depth,sort_path
 loop
  if n.title is null then continue; end if;
  insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)
  values(new_deck,case when n.parent_old_id is null then null else nullif(node_map->>n.parent_old_id,'')::uuid end,case when n.node_type='folder' then 'folder' else 'item' end,n.title,n.memo,n.order_index)
  returning id into new_node;
  node_map:=node_map||jsonb_build_object(coalesce(n.old_id,new_node::text),new_node::text);
  if n.node_type='item' then copied_items:=copied_items+1; end if;
 end loop;

 if copied_items<>source_items then
  raise exception 'コピー後の問題数が一致しません: source %, copied %',source_items,copied_items;
 end if;

 return new_deck;
end
$$;

create or replace function public.copy_cards_snapshot_to_user(p_source_id uuid,p_owner_id uuid,p_snapshot jsonb,p_version int)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare
 new_list uuid;
 source_cards int:=public.cards_snapshot_item_count(p_snapshot);
 copied_cards int:=0;
begin
 if p_owner_id is null then raise exception 'copy owner is required'; end if;
 if p_snapshot is null or source_cards=0 then raise exception 'コピーできるカードがありません'; end if;

 insert into word_lists(user_id,title,description,edition_label,textbook_master_id,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version,max_reviews,review_intervals,reset_again_to_first)
 select
  p_owner_id,
  coalesce(nullif(p_snapshot->>'title',''),l.title),
  coalesce(p_snapshot->>'description',l.description),
  coalesce(p_snapshot->>'edition_label',l.edition_label),
  coalesce(nullif(p_snapshot->>'textbook_master_id','')::uuid,l.textbook_master_id),
  p_owner_id,
  p_source_id,
  p_source_id,
  coalesce(p_version,0),
  l.max_reviews,
  l.review_intervals,
  l.reset_again_to_first
 from word_lists l
 where l.id=p_source_id
 returning id into new_list;

 if new_list is null then raise exception 'copy source not found'; end if;

 insert into word_cards(list_id,card_id,front,back,memo,order_index)
 select new_list,x.card_id,x.front,x.back,x.memo,coalesce(x.order_index,x.ord::int-1)
 from (
  select
   e.value->>'card_id' card_id,
   e.value->>'front' front,
   e.value->>'back' back,
   e.value->>'memo' memo,
   nullif(e.value->>'order_index','')::int order_index,
   e.ord
  from jsonb_array_elements(coalesce(p_snapshot->'cards','[]'::jsonb)) with ordinality as e(value,ord)
 ) x
 where coalesce(x.front,'')<>'' and coalesce(x.back,'')<>'';

 get diagnostics copied_cards = row_count;
 if copied_cards<>source_cards then
  raise exception 'コピー後のカード数が一致しません: source %, copied %',source_cards,copied_cards;
 end if;

 return new_list;
end
$$;

create or replace function public.copy_content_to_user(p_type text,p_source_id uuid,p_owner_id uuid,p_prefer_published boolean)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare snap jsonb;version int;new_id uuid;
begin
 if p_type='material' then
  select published_snapshot_version into version from material_decks where id=p_source_id and deleted_at is null;
  snap:=public.material_snapshot_for_copy(p_source_id,p_prefer_published);
  new_id:=public.copy_material_snapshot_to_user(p_source_id,p_owner_id,snap,coalesce(version,0));
 else
  select published_snapshot_version into version from word_lists where id=p_source_id and deleted_at is null;
  snap:=public.cards_snapshot_for_copy(p_source_id,p_prefer_published);
  new_id:=public.copy_cards_snapshot_to_user(p_source_id,p_owner_id,snap,coalesce(version,0));
 end if;
 return new_id;
end
$$;

revoke all on function public.copy_content_to_user(text,uuid,uuid,boolean) from public,anon,authenticated;

create or replace function public.copy_shared_material(p_token text)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;prefer_published boolean;new_id uuid;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,visibility='approved' into source_id,prefer_published
 from material_decks
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 new_id:=public.copy_content_to_user('material',source_id,auth.uid(),prefer_published);
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
declare source_id uuid;prefer_published boolean;new_id uuid;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,visibility='approved' into source_id,prefer_published
 from word_lists
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 new_id:=public.copy_content_to_user('cards',source_id,auth.uid(),prefer_published);
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
declare source_id uuid;prefer_published boolean;new_id uuid;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 select id,visibility='approved' into source_id,prefer_published
 from material_decks
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 new_id:=public.copy_content_to_user('material',source_id,p_student_id,prefer_published);
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
declare source_id uuid;prefer_published boolean;new_id uuid;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 select id,visibility='approved' into source_id,prefer_published
 from word_lists
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 new_id:=public.copy_content_to_user('cards',source_id,p_student_id,prefer_published);
 update word_lists set copy_count=copy_count+1,last_copied_at=now() where id=source_id;
 return new_id;
end
$$;

create or replace function public.copy_owned_content_to_student(p_student_id uuid,p_type text,p_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare new_id uuid;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 if p_type='material' then
  if not exists(select 1 from material_decks where id=p_id and user_id=auth.uid() and deleted_at is null) then raise exception 'not found'; end if;
  new_id:=public.copy_content_to_user('material',p_id,p_student_id,false);
 else
  if not exists(select 1 from word_lists where id=p_id and user_id=auth.uid() and deleted_at is null) then raise exception 'not found'; end if;
  new_id:=public.copy_content_to_user('cards',p_id,p_student_id,false);
 end if;
 return new_id;
end
$$;

create or replace function public.copy_library_item(p_type text,p_id uuid,p_student_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare new_id uuid;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 if p_student_id is not null and not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then
  raise exception 'not allowed';
 end if;
 if p_type='material' then
  if not exists(select 1 from material_decks where id=p_id and visibility='approved' and deleted_at is null) then raise exception 'not found'; end if;
  new_id:=public.copy_content_to_user('material',p_id,coalesce(p_student_id,auth.uid()),true);
  update material_decks set copy_count=copy_count+1,last_copied_at=now() where id=p_id;
 else
  if not exists(select 1 from word_lists where id=p_id and visibility='approved' and deleted_at is null) then raise exception 'not found'; end if;
  new_id:=public.copy_content_to_user('cards',p_id,coalesce(p_student_id,auth.uid()),true);
  update word_lists set copy_count=copy_count+1,last_copied_at=now() where id=p_id;
 end if;
 return new_id;
end
$$;

grant execute on function public.import_material_nodes(uuid,jsonb) to authenticated;
grant execute on function public.import_word_cards(uuid,jsonb) to authenticated;
grant execute on function public.copy_shared_material(text) to authenticated;
grant execute on function public.copy_shared_cards(text) to authenticated;
grant execute on function public.copy_shared_material_for_student(text,uuid) to authenticated;
grant execute on function public.copy_shared_cards_for_student(text,uuid) to authenticated;
grant execute on function public.copy_owned_content_to_student(uuid,text,uuid) to authenticated;
grant execute on function public.copy_library_item(text,uuid,uuid) to authenticated;
