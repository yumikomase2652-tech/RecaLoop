-- Repair content import/copy paths that can produce empty decks or RLS failures.

grant select,insert,update,delete on public.material_decks to authenticated;
grant select,insert,update,delete on public.material_nodes to authenticated;
grant select,insert,update,delete on public.word_lists to authenticated;
grant select,insert,update,delete on public.word_cards to authenticated;

drop policy if exists "material decks own" on public.material_decks;
create policy "material decks own" on public.material_decks
for all
using(user_id=auth.uid())
with check(user_id=auth.uid());

drop policy if exists "material nodes own" on public.material_nodes;
create policy "material nodes own" on public.material_nodes
for all
using(exists(select 1 from public.material_decks d where d.id=deck_id and d.user_id=auth.uid()))
with check(exists(select 1 from public.material_decks d where d.id=deck_id and d.user_id=auth.uid()));

drop policy if exists "word lists own" on public.word_lists;
create policy "word lists own" on public.word_lists
for all
using(user_id=auth.uid())
with check(user_id=auth.uid());

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

create or replace function public.shared_content(p_type text,p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path=public
as $$
declare result jsonb;source_id uuid;source_visibility text;snap jsonb;
begin
 if p_type='material' then
  select id,visibility into source_id,source_visibility
  from material_decks
  where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
  if source_id is null then return null; end if;
  snap:=public.material_snapshot_for_copy(source_id,source_visibility='approved');
 else
  select id,visibility into source_id,source_visibility
  from word_lists
  where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
  if source_id is null then return null; end if;
  snap:=public.cards_snapshot_for_copy(source_id,source_visibility='approved');
 end if;
 result:=coalesce(snap,'{}'::jsonb)||jsonb_build_object('id',source_id,'visibility',source_visibility,'share_token',p_token);
 return result;
end
$$;

create or replace function public.copy_shared_material(p_token text)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare source_id uuid;snap jsonb;version int;new_id uuid;prefer_published boolean;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,visibility='approved',published_snapshot_version
 into source_id,prefer_published,version
 from material_decks
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 snap:=public.material_snapshot_for_copy(source_id,prefer_published);
 if snap is null or public.material_snapshot_item_count(snap)=0 then raise exception 'コピーできる問題がありません'; end if;
 new_id:=public.copy_material_snapshot_to_user(source_id,auth.uid(),snap,coalesce(version,0));
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
declare source_id uuid;snap jsonb;version int;new_id uuid;prefer_published boolean;
begin
 if auth.uid() is null then raise exception 'login required'; end if;
 select id,visibility='approved',published_snapshot_version
 into source_id,prefer_published,version
 from word_lists
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 snap:=public.cards_snapshot_for_copy(source_id,prefer_published);
 if snap is null or public.cards_snapshot_item_count(snap)=0 then raise exception 'コピーできるカードがありません'; end if;
 new_id:=public.copy_cards_snapshot_to_user(source_id,auth.uid(),snap,coalesce(version,0));
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
declare source_id uuid;snap jsonb;version int;new_id uuid;prefer_published boolean;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 select id,visibility='approved',published_snapshot_version
 into source_id,prefer_published,version
 from material_decks
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 snap:=public.material_snapshot_for_copy(source_id,prefer_published);
 if snap is null or public.material_snapshot_item_count(snap)=0 then raise exception 'コピーできる問題がありません'; end if;
 new_id:=public.copy_material_snapshot_to_user(source_id,p_student_id,snap,coalesce(version,0));
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
declare source_id uuid;snap jsonb;version int;new_id uuid;prefer_published boolean;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 select id,visibility='approved',published_snapshot_version
 into source_id,prefer_published,version
 from word_lists
 where share_token=p_token and visibility in('unlisted','approved') and deleted_at is null;
 if source_id is null then raise exception 'not found'; end if;
 snap:=public.cards_snapshot_for_copy(source_id,prefer_published);
 if snap is null or public.cards_snapshot_item_count(snap)=0 then raise exception 'コピーできるカードがありません'; end if;
 new_id:=public.copy_cards_snapshot_to_user(source_id,p_student_id,snap,coalesce(version,0));
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
declare snap jsonb;version int;new_id uuid;
begin
 if not exists(select 1 from teacher_student_links where teacher_id=auth.uid() and student_id=p_student_id and status='active') then raise exception 'not allowed'; end if;
 if p_type='material' then
  if not exists(select 1 from material_decks where id=p_id and user_id=auth.uid() and deleted_at is null) then raise exception 'not found'; end if;
  snap:=public.material_snapshot_for_copy(p_id,false);
  if snap is null or public.material_snapshot_item_count(snap)=0 then raise exception 'コピーできる問題がありません'; end if;
  select published_snapshot_version into version from material_decks where id=p_id;
  new_id:=public.copy_material_snapshot_to_user(p_id,p_student_id,snap,coalesce(version,0));
 else
  if not exists(select 1 from word_lists where id=p_id and user_id=auth.uid() and deleted_at is null) then raise exception 'not found'; end if;
  snap:=public.cards_snapshot_for_copy(p_id,false);
  if snap is null or public.cards_snapshot_item_count(snap)=0 then raise exception 'コピーできるカードがありません'; end if;
  select published_snapshot_version into version from word_lists where id=p_id;
  new_id:=public.copy_cards_snapshot_to_user(p_id,p_student_id,snap,coalesce(version,0));
 end if;
 return new_id;
end
$$;

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
   coalesce(nullif(public.material_snapshot_for_copy(d.id,true)->>'title',''),d.title)::text title,
   ''::text creator_name,
   public.material_snapshot_item_count(public.material_snapshot_for_copy(d.id,true))::bigint item_count,
   d.copy_count::int,
   coalesce(d.approved_at,d.updated_at,d.created_at)::timestamptz updated_at,
   d.share_token::text,
   coalesce((select jsonb_agg(jsonb_build_object('name',q.display_name,'count',q.cnt) order by q.cnt desc) from (select t.display_name,count(*)::int cnt from user_titles ut join titles t on t.id=ut.title_id where t.title_type='deck_completion' and ut.source_type='material' and ut.source_id=d.id group by t.display_name having count(*)>=3) q),'[]'::jsonb) clear_titles,
   coalesce(public.material_snapshot_for_copy(d.id,true)->>'description',d.description)::text description,
   coalesce(public.material_snapshot_for_copy(d.id,true)->>'edition_label',d.edition_label)::text edition_label
  from material_decks d
  where d.visibility='approved' and d.deleted_at is null and p_type in('all','material') and (p_query='' or coalesce(public.material_snapshot_for_copy(d.id,true)->>'title',d.title) ilike '%'||p_query||'%')
  union all
  select
   'cards'::text content_type,
   l.id,
   coalesce(nullif(public.cards_snapshot_for_copy(l.id,true)->>'title',''),l.title)::text title,
   ''::text creator_name,
   public.cards_snapshot_item_count(public.cards_snapshot_for_copy(l.id,true))::bigint item_count,
   l.copy_count::int,
   coalesce(l.approved_at,l.updated_at,l.created_at)::timestamptz updated_at,
   l.share_token::text,
   coalesce((select jsonb_agg(jsonb_build_object('name',q.display_name,'count',q.cnt) order by q.cnt desc) from (select t.display_name,count(*)::int cnt from user_titles ut join titles t on t.id=ut.title_id where t.title_type='deck_completion' and ut.source_type='cards' and ut.source_id=l.id group by t.display_name having count(*)>=3) q),'[]'::jsonb) clear_titles,
   coalesce(public.cards_snapshot_for_copy(l.id,true)->>'description',l.description)::text description,
   coalesce(public.cards_snapshot_for_copy(l.id,true)->>'edition_label',l.edition_label)::text edition_label
  from word_lists l
  where l.visibility='approved' and l.deleted_at is null and p_type in('all','cards') and (p_query='' or coalesce(public.cards_snapshot_for_copy(l.id,true)->>'title',l.title) ilike '%'||p_query||'%')
 ) x
 order by updated_at desc
$$;

grant execute on function public.shared_content(text,text) to authenticated;
grant execute on function public.copy_shared_material(text) to authenticated;
grant execute on function public.copy_shared_cards(text) to authenticated;
grant execute on function public.copy_shared_material_for_student(text,uuid) to authenticated;
grant execute on function public.copy_shared_cards_for_student(text,uuid) to authenticated;
grant execute on function public.copy_owned_content_to_student(uuid,text,uuid) to authenticated;
grant execute on function public.library_items(text,text) to authenticated;
