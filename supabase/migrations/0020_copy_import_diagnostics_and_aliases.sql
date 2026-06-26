-- Diagnostics and compatibility aliases for CSV import/copy recovery.
--
-- Useful SQL Editor checks:
-- select * from public.debug_copy_source('material','<source_deck_id>'::uuid,null);
-- select * from public.debug_copy_source('cards','<source_list_id>'::uuid,null);
-- select routine_name,security_type,pg_get_function_arguments(p.oid) args
-- from information_schema.routines r
-- join pg_proc p on p.proname=r.routine_name
-- join pg_namespace n on n.oid=p.pronamespace and n.nspname=r.specific_schema
-- where r.specific_schema='public'
--   and routine_name in (
--    'import_material_nodes','import_word_cards','save_material_node','save_word_card',
--    'copy_content_to_user','copy_shared_content','copy_library_content',
--    'copy_teacher_owned_content_to_student','copy_shared_material','copy_shared_cards',
--    'copy_owned_content_to_student'
--   )
-- order by routine_name,args;

create or replace function public.debug_copy_source(p_type text,p_id uuid default null,p_token text default null)
returns jsonb
language plpgsql
stable
security definer
set search_path=public
as $$
declare
 source_id uuid;
 source_visibility text;
 live_count int:=0;
 published_count int:=0;
 live_snapshot_count int:=0;
 chosen_snapshot_count int:=0;
 result jsonb;
begin
 if p_type='material' then
  select id,visibility into source_id,source_visibility
  from material_decks
  where (p_id is not null and id=p_id or p_token is not null and share_token=p_token)
    and deleted_at is null
  limit 1;
  if source_id is null then
   return jsonb_build_object('found',false,'type',p_type,'id',p_id,'token',p_token,'error','source material not found');
  end if;
  select count(*)::int into live_count from material_nodes where deck_id=source_id and node_type='item';
  select public.material_snapshot_item_count(published_snapshot) into published_count from material_decks where id=source_id;
  live_snapshot_count:=public.material_snapshot_item_count(public.content_snapshot('material',source_id));
  chosen_snapshot_count:=public.material_snapshot_item_count(public.material_snapshot_for_copy(source_id,source_visibility='approved'));
 else
  select id,visibility into source_id,source_visibility
  from word_lists
  where (p_id is not null and id=p_id or p_token is not null and share_token=p_token)
    and deleted_at is null
  limit 1;
  if source_id is null then
   return jsonb_build_object('found',false,'type',p_type,'id',p_id,'token',p_token,'error','source card deck not found');
  end if;
  select count(*)::int into live_count from word_cards where list_id=source_id;
  select public.cards_snapshot_item_count(published_snapshot) into published_count from word_lists where id=source_id;
  live_snapshot_count:=public.cards_snapshot_item_count(public.content_snapshot('cards',source_id));
  chosen_snapshot_count:=public.cards_snapshot_item_count(public.cards_snapshot_for_copy(source_id,source_visibility='approved'));
 end if;

 result:=jsonb_build_object(
  'found',true,
  'type',p_type,
  'source_id',source_id,
  'visibility',source_visibility,
  'live_count',coalesce(live_count,0),
  'published_snapshot_count',coalesce(published_count,0),
  'live_snapshot_count',coalesce(live_snapshot_count,0),
  'chosen_snapshot_count',coalesce(chosen_snapshot_count,0)
 );
 return result;
end
$$;

create or replace function public.copy_shared_content(p_type text,p_token text,p_student_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
begin
 if p_student_id is not null then
  if p_type='material' then
   return public.copy_shared_material_for_student(p_token,p_student_id);
  end if;
  return public.copy_shared_cards_for_student(p_token,p_student_id);
 end if;

 if p_type='material' then
  return public.copy_shared_material(p_token);
 end if;
 return public.copy_shared_cards(p_token);
end
$$;

create or replace function public.copy_library_content(p_type text,p_id uuid,p_student_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
begin
 return public.copy_library_item(p_type,p_id,p_student_id);
end
$$;

create or replace function public.copy_teacher_owned_content_to_student(p_student_id uuid,p_type text,p_id uuid)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
begin
 return public.copy_owned_content_to_student(p_student_id,p_type,p_id);
end
$$;

grant execute on function public.debug_copy_source(text,uuid,text) to authenticated;
grant execute on function public.copy_shared_content(text,text,uuid) to authenticated;
grant execute on function public.copy_library_content(text,uuid,uuid) to authenticated;
grant execute on function public.copy_teacher_owned_content_to_student(uuid,text,uuid) to authenticated;
