alter table public.material_decks add column if not exists published_snapshot_version int not null default 1;
alter table public.material_decks add column if not exists copied_snapshot_version int;
alter table public.material_decks add column if not exists copied_from_deck_id uuid;
alter table public.word_lists add column if not exists published_snapshot_version int not null default 1;
alter table public.word_lists add column if not exists copied_snapshot_version int;
alter table public.word_lists add column if not exists copied_from_deck_id uuid;

create or replace function public.moderate_submission(p_type text,p_id uuid,p_approve boolean,p_reason text default null)returns void language plpgsql security definer set search_path=public as $$
declare kind text;begin
 if not public.is_admin()then raise exception'admin only';end if;
 if p_type='material'then
  select submission_kind into kind from material_decks where id=p_id and pending_snapshot is not null;if kind is null then raise exception'not found';end if;
  update material_decks set published_snapshot=case when p_approve then pending_snapshot else published_snapshot end,published_snapshot_version=case when p_approve then published_snapshot_version+1 else published_snapshot_version end,pending_snapshot=null,submission_kind=null,visibility=case when p_approve or kind='update'then'approved'else'rejected'end,is_public=p_approve or kind='update',approved_at=case when p_approve then now()else approved_at end,rejected_reason=case when p_approve then null else p_reason end,updated_at=now()where id=p_id;
 else
  select submission_kind into kind from word_lists where id=p_id and pending_snapshot is not null;if kind is null then raise exception'not found';end if;
  update word_lists set published_snapshot=case when p_approve then pending_snapshot else published_snapshot end,published_snapshot_version=case when p_approve then published_snapshot_version+1 else published_snapshot_version end,pending_snapshot=null,submission_kind=null,visibility=case when p_approve or kind='update'then'approved'else'rejected'end,is_public=p_approve or kind='update',approved_at=case when p_approve then now()else approved_at end,rejected_reason=case when p_approve then null else p_reason end,updated_at=now()where id=p_id;
 end if;
end$$;

create or replace function public.library_items(p_query text default'',p_type text default'all')returns table(content_type text,id uuid,title text,creator_name text,item_count bigint,copy_count int,updated_at timestamptz,share_token text)language sql stable security definer set search_path=public as $$
 select'material',d.id,d.title,''::text,(select count(*)from material_nodes n where n.deck_id=d.id and n.node_type='item'),d.copy_count,d.updated_at,d.share_token from material_decks d where d.visibility='approved'and(p_type in('all','material'))and(p_query=''or d.title ilike'%'||p_query||'%')
 union all
 select'cards',l.id,l.title,''::text,(select count(*)from word_cards c where c.list_id=l.id),l.copy_count,l.updated_at,l.share_token from word_lists l where l.visibility='approved'and(p_type in('all','cards'))and(p_query=''or l.title ilike'%'||p_query||'%')
 order by updated_at desc
$$;

create or replace function public.copy_shared_material(p_token text)returns uuid language plpgsql security definer set search_path=public as $$
declare source_id uuid;new_deck uuid;snap jsonb;version int;n record;new_node uuid;node_map jsonb:='{}';begin
 if auth.uid()is null then raise exception'login required';end if;
 select id,case when visibility='approved'then published_snapshot else public.content_snapshot('material',id)end,published_snapshot_version into source_id,snap,version from material_decks where share_token=p_token and visibility in('unlisted','approved');
 if source_id is null then raise exception'not found';end if;
 insert into material_decks(user_id,title,description,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version)values(auth.uid(),snap->>'title',snap->>'description',auth.uid(),source_id,source_id,version)returning id into new_deck;
 for n in select*from jsonb_to_recordset(coalesce(snap->'nodes','[]'::jsonb))as x(id uuid,parent_id uuid,node_type text,title text,memo text,order_index int)order by coalesce(parent_id,id),order_index,title loop
  insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)values(new_deck,case when n.parent_id is null then null else(node_map->>n.parent_id::text)::uuid end,n.node_type,n.title,n.memo,coalesce(n.order_index,0))returning id into new_node;
  node_map:=node_map||jsonb_build_object(n.id::text,new_node::text);
 end loop;
 update material_decks set copy_count=copy_count+1,last_copied_at=now()where id=source_id;
 return new_deck;
end$$;

create or replace function public.copy_shared_cards(p_token text)returns uuid language plpgsql security definer set search_path=public as $$
declare source_id uuid;new_list uuid;snap jsonb;version int;begin
 if auth.uid()is null then raise exception'login required';end if;
 select id,case when visibility='approved'then published_snapshot else public.content_snapshot('cards',id)end,published_snapshot_version into source_id,snap,version from word_lists where share_token=p_token and visibility in('unlisted','approved');
 if source_id is null then raise exception'not found';end if;
 insert into word_lists(user_id,title,description,created_by_user_id,source_content_id,copied_from_deck_id,copied_snapshot_version)values(auth.uid(),snap->>'title',snap->>'description',auth.uid(),source_id,source_id,version)returning id into new_list;
 insert into word_cards(list_id,card_id,front,back,memo,order_index)select new_list,card_id,front,back,memo,coalesce(order_index,0)from jsonb_to_recordset(coalesce(snap->'cards','[]'::jsonb))as x(card_id text,front text,back text,memo text,order_index int);
 update word_lists set copy_count=copy_count+1,last_copied_at=now()where id=source_id;
 return new_list;
end$$;

create or replace function public.update_copied_content(p_type text,p_id uuid)returns void language plpgsql security definer set search_path=public as $$
declare source_id uuid;snap jsonb;version int;n record;new_node uuid;node_map jsonb:='{}';begin
 if p_type='material'then
  select copied_from_deck_id into source_id from material_decks where id=p_id and user_id=auth.uid();if source_id is null then raise exception'更新元がありません';end if;
  select published_snapshot,published_snapshot_version into snap,version from material_decks where id=source_id and visibility='approved';
  update material_decks set title=snap->>'title',description=snap->>'description',copied_snapshot_version=version,updated_at=now()where id=p_id and user_id=auth.uid();
  delete from material_nodes where deck_id=p_id and id not in(select material_node_id from material_item_states where user_id=auth.uid());
  for n in select*from jsonb_to_recordset(coalesce(snap->'nodes','[]'::jsonb))as x(id uuid,parent_id uuid,node_type text,title text,memo text,order_index int)order by coalesce(parent_id,id),order_index,title loop
   insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)values(p_id,case when n.parent_id is null then null else(node_map->>n.parent_id::text)::uuid end,n.node_type,n.title,n.memo,coalesce(n.order_index,0))returning id into new_node;
   node_map:=node_map||jsonb_build_object(n.id::text,new_node::text);
  end loop;
 else
  select copied_from_deck_id into source_id from word_lists where id=p_id and user_id=auth.uid();if source_id is null then raise exception'更新元がありません';end if;
  select published_snapshot,published_snapshot_version into snap,version from word_lists where id=source_id and visibility='approved';
  update word_lists set title=snap->>'title',description=snap->>'description',copied_snapshot_version=version,updated_at=now()where id=p_id and user_id=auth.uid();
  delete from word_cards where list_id=p_id and id not in(select word_card_id from word_card_states where user_id=auth.uid());
  insert into word_cards(list_id,card_id,front,back,memo,order_index)select p_id,card_id,front,back,memo,coalesce(order_index,0)from jsonb_to_recordset(coalesce(snap->'cards','[]'::jsonb))as x(card_id text,front text,back text,memo text,order_index int);
 end if;
end$$;
grant execute on function public.update_copied_content(text,uuid) to authenticated;
