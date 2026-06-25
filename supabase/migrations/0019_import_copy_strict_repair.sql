-- Strict repair for CSV import and copy flows.
-- Verification SQL:
-- select count(*) from public.material_nodes where deck_id = '<copied_deck_id>';
-- select count(*) from public.material_nodes where deck_id = '<source_deck_id>';
-- select count(*) from public.word_cards where list_id = '<copied_list_id>';
-- select count(*) from public.word_cards where list_id = '<source_list_id>';

create or replace function public.save_material_node(
 p_deck_id uuid,
 p_parent_id uuid,
 p_node_type text,
 p_title text,
 p_memo text default null,
 p_order_index int default 0
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare new_row material_nodes%rowtype;
begin
 if auth.uid() is null then
  raise exception 'not allowed: login required';
 end if;
 if not exists(select 1 from material_decks where id=p_deck_id and user_id=auth.uid() and deleted_at is null) then
  raise exception 'not allowed: deck owner mismatch';
 end if;
 if p_parent_id is not null and not exists(select 1 from material_nodes where id=p_parent_id and deck_id=p_deck_id and node_type='folder') then
  raise exception 'not allowed: parent node is not in this deck';
 end if;
 if nullif(trim(coalesce(p_title,'')),'') is null then
  raise exception 'invalid material node: title is required';
 end if;

 insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)
 values(p_deck_id,p_parent_id,case when p_node_type='folder' then 'folder' else 'item' end,trim(p_title),p_memo,coalesce(p_order_index,0))
 returning * into new_row;

 return to_jsonb(new_row);
end
$$;

create or replace function public.save_word_card(
 p_list_id uuid,
 p_card_id text,
 p_front text,
 p_back text,
 p_memo text default null,
 p_order_index int default 0
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare new_row word_cards%rowtype;
begin
 if auth.uid() is null then
  raise exception 'not allowed: login required';
 end if;
 if not exists(select 1 from word_lists where id=p_list_id and user_id=auth.uid() and deleted_at is null) then
  raise exception 'not allowed: card list owner mismatch';
 end if;
 if nullif(trim(coalesce(p_front,'')),'') is null or nullif(trim(coalesce(p_back,'')),'') is null then
  raise exception 'invalid word card: front/back are required';
 end if;

 insert into word_cards(list_id,card_id,front,back,memo,order_index)
 values(p_list_id,nullif(trim(coalesce(p_card_id,'')),''),trim(p_front),trim(p_back),p_memo,coalesce(p_order_index,0))
 returning * into new_row;

 return to_jsonb(new_row);
end
$$;

create or replace function public.import_material_nodes(p_deck_id uuid,p_nodes jsonb)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
 n record;
 new_row jsonb;
 parent_new_id uuid;
 node_map jsonb:='{}'::jsonb;
 out_rows jsonb:='[]'::jsonb;
 expected_items int:=0;
 copied_items int:=0;
begin
 if auth.uid() is null then raise exception 'not allowed: login required'; end if;
 if not exists(select 1 from material_decks where id=p_deck_id and user_id=auth.uid() and deleted_at is null) then
  raise exception 'not allowed: deck owner mismatch';
 end if;

 select count(*)::int into expected_items
 from jsonb_array_elements(coalesce(p_nodes,'[]'::jsonb)) e
 where e->>'node_type'='item';

 if expected_items=0 then
  raise exception 'invalid CSV: no material items to import';
 end if;

 for n in
  select
   coalesce(e.value->>'id',e.ord::text) old_id,
   nullif(e.value->>'parent_id','') parent_old_id,
   case when e.value->>'node_type'='folder' then 'folder' else 'item' end node_type,
   nullif(e.value->>'title','') title,
   nullif(e.value->>'memo','') memo,
   coalesce(nullif(e.value->>'order_index','')::int,e.ord::int-1) order_index,
   e.ord::int ord
  from jsonb_array_elements(coalesce(p_nodes,'[]'::jsonb)) with ordinality as e(value,ord)
  order by e.ord
 loop
  if n.title is null then
   raise exception 'invalid CSV: material node title is missing at row %',n.ord;
  end if;

  if n.parent_old_id is null then
   parent_new_id:=null;
  elsif node_map ? n.parent_old_id then
   parent_new_id:=nullif(node_map->>n.parent_old_id,'')::uuid;
  else
   raise exception 'invalid CSV: parent mapping missing for %',n.title;
  end if;

  new_row:=public.save_material_node(p_deck_id,parent_new_id,n.node_type,n.title,n.memo,n.order_index);
  node_map:=node_map||jsonb_build_object(n.old_id,new_row->>'id');
  out_rows:=out_rows||jsonb_build_array(new_row);
  if n.node_type='item' then copied_items:=copied_items+1; end if;
 end loop;

 if copied_items<>expected_items then
  raise exception 'import failed: item count mismatch source %, copied %',expected_items,copied_items;
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
 new_row jsonb;
 out_rows jsonb:='[]'::jsonb;
 expected_cards int:=0;
 copied_cards int:=0;
begin
 if auth.uid() is null then raise exception 'not allowed: login required'; end if;
 if not exists(select 1 from word_lists where id=p_list_id and user_id=auth.uid() and deleted_at is null) then
  raise exception 'not allowed: card list owner mismatch';
 end if;

 select count(*)::int into expected_cards
 from jsonb_array_elements(coalesce(p_cards,'[]'::jsonb)) e
 where nullif(e->>'front','') is not null and nullif(e->>'back','') is not null;

 if expected_cards=0 then
  raise exception 'invalid CSV: no word cards to import';
 end if;

 for c in
  select
   nullif(e.value->>'card_id','') card_id,
   nullif(e.value->>'front','') front,
   nullif(e.value->>'back','') back,
   nullif(e.value->>'memo','') memo,
   coalesce(nullif(e.value->>'order_index','')::int,e.ord::int-1) order_index,
   e.ord::int ord
  from jsonb_array_elements(coalesce(p_cards,'[]'::jsonb)) with ordinality as e(value,ord)
  order by e.ord
 loop
  if c.front is null or c.back is null then
   raise exception 'invalid CSV: word card front/back is missing at row %',c.ord;
  end if;

  new_row:=public.save_word_card(p_list_id,c.card_id,c.front,c.back,c.memo,c.order_index);
  out_rows:=out_rows||jsonb_build_array(new_row);
  copied_cards:=copied_cards+1;
 end loop;

 if copied_cards<>expected_cards then
  raise exception 'import failed: card count mismatch source %, copied %',expected_cards,copied_cards;
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
 if p_owner_id is null then raise exception 'copy failed: target user is required'; end if;
 if p_snapshot is null then raise exception 'copy failed: source snapshot is empty'; end if;
 if source_items=0 then raise exception 'copy failed: source material has no items'; end if;

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
 where d.id=p_source_id and d.deleted_at is null
 returning id into new_deck;

 if new_deck is null then raise exception 'copy failed: source material deck not found'; end if;

 for n in
  with recursive source as(
   select
    coalesce(e.value->>'id',e.ord::text) old_id,
    nullif(e.value->>'parent_id','') parent_old_id,
    case when e.value->>'node_type'='folder' then 'folder' else 'item' end node_type,
    nullif(e.value->>'title','') title,
    nullif(e.value->>'memo','') memo,
    coalesce(nullif(e.value->>'order_index','')::int,e.ord::int-1) order_index,
    e.ord::int ord
   from jsonb_array_elements(coalesce(p_snapshot->'nodes','[]'::jsonb)) with ordinality as e(value,ord)
  ),tree as(
   select s.*,0 depth,array[s.ord] sort_path from source s where s.parent_old_id is null
   union all
   select s.*,tree.depth+1,tree.sort_path||s.ord from source s join tree on s.parent_old_id=tree.old_id
  )
  select * from tree order by depth,sort_path
 loop
  if n.title is null then
   raise exception 'copy failed: source node title is missing';
  end if;
  if n.parent_old_id is not null and not (node_map ? n.parent_old_id) then
   raise exception 'copy failed: parent mapping missing for %',n.title;
  end if;

  insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)
  values(new_deck,case when n.parent_old_id is null then null else nullif(node_map->>n.parent_old_id,'')::uuid end,n.node_type,n.title,n.memo,n.order_index)
  returning id into new_node;

  node_map:=node_map||jsonb_build_object(n.old_id,new_node::text);
  if n.node_type='item' then copied_items:=copied_items+1; end if;
 end loop;

 if copied_items<>source_items then
  raise exception 'copy failed: material item count mismatch source %, copied %',source_items,copied_items;
 end if;

 if (select count(*)::int from material_nodes where deck_id=new_deck and node_type='item')<>source_items then
  raise exception 'copy failed: copied material item count verification failed';
 end if;

 return new_deck;
exception when others then
 if new_deck is not null then
  delete from material_decks where id=new_deck;
 end if;
 raise;
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
 if p_owner_id is null then raise exception 'copy failed: target user is required'; end if;
 if p_snapshot is null then raise exception 'copy failed: source snapshot is empty'; end if;
 if source_cards=0 then raise exception 'copy failed: source card deck has no cards'; end if;

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
 where l.id=p_source_id and l.deleted_at is null
 returning id into new_list;

 if new_list is null then raise exception 'copy failed: source card deck not found'; end if;

 insert into word_cards(list_id,card_id,front,back,memo,order_index)
 select new_list,x.card_id,x.front,x.back,x.memo,coalesce(x.order_index,x.ord::int-1)
 from (
  select
   nullif(e.value->>'card_id','') card_id,
   nullif(e.value->>'front','') front,
   nullif(e.value->>'back','') back,
   nullif(e.value->>'memo','') memo,
   nullif(e.value->>'order_index','')::int order_index,
   e.ord
  from jsonb_array_elements(coalesce(p_snapshot->'cards','[]'::jsonb)) with ordinality as e(value,ord)
 ) x
 where x.front is not null and x.back is not null;

 get diagnostics copied_cards = row_count;
 if copied_cards<>source_cards then
  raise exception 'copy failed: card count mismatch source %, copied %',source_cards,copied_cards;
 end if;

 if (select count(*)::int from word_cards where list_id=new_list)<>source_cards then
  raise exception 'copy failed: copied card count verification failed';
 end if;

 return new_list;
exception when others then
 if new_list is not null then
  delete from word_lists where id=new_list;
 end if;
 raise;
end
$$;

create or replace function public.copy_content_to_user(p_type text,p_source_id uuid,p_owner_id uuid,p_prefer_published boolean)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare snap jsonb;version int;new_id uuid;live_count int;snap_count int;
begin
 if p_type='material' then
  if not exists(select 1 from material_decks where id=p_source_id and deleted_at is null) then
   raise exception 'copy failed: source material deck not found';
  end if;
  select published_snapshot_version into version from material_decks where id=p_source_id;
  select count(*)::int into live_count from material_nodes where deck_id=p_source_id and node_type='item';
  snap:=public.material_snapshot_for_copy(p_source_id,p_prefer_published);
  snap_count:=public.material_snapshot_item_count(snap);
  if live_count>0 and snap_count=0 then
   raise exception 'copy failed: source material has % live items but snapshot has 0',live_count;
  end if;
  new_id:=public.copy_material_snapshot_to_user(p_source_id,p_owner_id,snap,coalesce(version,0));
 else
  if not exists(select 1 from word_lists where id=p_source_id and deleted_at is null) then
   raise exception 'copy failed: source card deck not found';
  end if;
  select published_snapshot_version into version from word_lists where id=p_source_id;
  select count(*)::int into live_count from word_cards where list_id=p_source_id;
  snap:=public.cards_snapshot_for_copy(p_source_id,p_prefer_published);
  snap_count:=public.cards_snapshot_item_count(snap);
  if live_count>0 and snap_count=0 then
   raise exception 'copy failed: source card deck has % live cards but snapshot has 0',live_count;
  end if;
  new_id:=public.copy_cards_snapshot_to_user(p_source_id,p_owner_id,snap,coalesce(version,0));
 end if;
 return new_id;
end
$$;

create or replace function public.copy_shared_material(p_token text)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;prefer_published boolean;new_id uuid;
begin
 if auth.uid() is null then raise exception 'not allowed: login required'; end if;
 select id,visibility='approved' into source_id,prefer_published
 from material_decks
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'copy failed: shared material token not found'; end if;
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
 if auth.uid() is null then raise exception 'not allowed: login required'; end if;
 select id,visibility='approved' into source_id,prefer_published
 from word_lists
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'copy failed: shared card token not found'; end if;
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
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then
  raise exception 'not allowed: teacher is not linked to student';
 end if;
 select id,visibility='approved' into source_id,prefer_published
 from material_decks
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'copy failed: shared material token not found'; end if;
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
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then
  raise exception 'not allowed: teacher is not linked to student';
 end if;
 select id,visibility='approved' into source_id,prefer_published
 from word_lists
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'copy failed: shared card token not found'; end if;
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
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then
  raise exception 'not allowed: teacher is not linked to student';
 end if;
 if p_type='material' then
  if not exists(select 1 from material_decks where id=p_id and user_id=auth.uid() and deleted_at is null) then
   raise exception 'not allowed: source material deck is not owned by teacher';
  end if;
  new_id:=public.copy_content_to_user('material',p_id,p_student_id,false);
 else
  if not exists(select 1 from word_lists where id=p_id and user_id=auth.uid() and deleted_at is null) then
   raise exception 'not allowed: source card deck is not owned by teacher';
  end if;
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
 if auth.uid() is null then raise exception 'not allowed: login required'; end if;
 if p_student_id is not null and not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then
  raise exception 'not allowed: teacher is not linked to student';
 end if;

 if p_type='material' then
  if not exists(select 1 from material_decks where id=p_id and visibility='approved' and deleted_at is null) then
   raise exception 'copy failed: approved material deck not found';
  end if;
  new_id:=public.copy_content_to_user('material',p_id,coalesce(p_student_id,auth.uid()),true);
  update material_decks set copy_count=copy_count+1,last_copied_at=now() where id=p_id;
 else
  if not exists(select 1 from word_lists where id=p_id and visibility='approved' and deleted_at is null) then
   raise exception 'copy failed: approved card deck not found';
  end if;
  new_id:=public.copy_content_to_user('cards',p_id,coalesce(p_student_id,auth.uid()),true);
  update word_lists set copy_count=copy_count+1,last_copied_at=now() where id=p_id;
 end if;

 return new_id;
end
$$;

grant execute on function public.save_material_node(uuid,uuid,text,text,text,int) to authenticated;
grant execute on function public.save_word_card(uuid,text,text,text,text,int) to authenticated;
grant execute on function public.import_material_nodes(uuid,jsonb) to authenticated;
grant execute on function public.import_word_cards(uuid,jsonb) to authenticated;
grant execute on function public.copy_shared_material(text) to authenticated;
grant execute on function public.copy_shared_cards(text) to authenticated;
grant execute on function public.copy_shared_material_for_student(text,uuid) to authenticated;
grant execute on function public.copy_shared_cards_for_student(text,uuid) to authenticated;
grant execute on function public.copy_owned_content_to_student(uuid,text,uuid) to authenticated;
grant execute on function public.copy_library_item(text,uuid,uuid) to authenticated;
