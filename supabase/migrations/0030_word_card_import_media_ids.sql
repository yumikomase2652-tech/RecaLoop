-- Preserve local media references when importing .recaloop card decks.
-- Media files themselves stay in IndexedDB, but word_cards must keep the
-- front/back media id arrays so the study screen can resolve them later.

create or replace function public.import_word_cards(p_list_id uuid,p_cards jsonb)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
 c record;
 new_row word_cards%rowtype;
 out_rows jsonb:='[]'::jsonb;
 expected_cards int:=0;
 copied_cards int:=0;
begin
 if auth.uid() is null then
  raise exception 'not allowed: login required';
 end if;
 if not exists(select 1 from word_lists where id=p_list_id and user_id=auth.uid() and deleted_at is null) then
  raise exception 'not allowed: card list owner mismatch';
 end if;

 select count(*)::int into expected_cards
 from jsonb_array_elements(coalesce(p_cards,'[]'::jsonb)) e
 where nullif(e->>'front','') is not null
    or jsonb_array_length(coalesce(e->'front_media_ids','[]'::jsonb)) > 0;

 if expected_cards=0 then
  raise exception 'invalid CSV: no word cards to import';
 end if;

 for c in
  select
   nullif(e.value->>'card_id','') card_id,
   coalesce(e.value->>'front','') front,
   coalesce(e.value->>'back','') back,
   nullif(e.value->>'memo','') memo,
   coalesce(nullif(e.value->>'order_index','')::int,e.ord::int-1) order_index,
   coalesce(
    array(select jsonb_array_elements_text(coalesce(e.value->'front_media_ids','[]'::jsonb))),
    '{}'::text[]
   ) front_media_ids,
   coalesce(
    array(select jsonb_array_elements_text(coalesce(e.value->'back_media_ids','[]'::jsonb))),
    '{}'::text[]
   ) back_media_ids,
   e.ord::int ord
  from jsonb_array_elements(coalesce(p_cards,'[]'::jsonb)) with ordinality as e(value,ord)
  order by e.ord
 loop
  if nullif(c.front,'') is null and coalesce(array_length(c.front_media_ids,1),0)=0 then
   raise exception 'invalid CSV: word card front/media is missing at row %',c.ord;
  end if;

  insert into word_cards(
   list_id,
   card_id,
   front,
   back,
   memo,
   order_index,
   front_media_ids,
   back_media_ids
  )
  values(
   p_list_id,
   c.card_id,
   trim(c.front),
   coalesce(trim(c.back),''),
   c.memo,
   c.order_index,
   c.front_media_ids,
   c.back_media_ids
  )
  returning * into new_row;

  out_rows:=out_rows||jsonb_build_array(to_jsonb(new_row));
  copied_cards:=copied_cards+1;
 end loop;

 if copied_cards<>expected_cards then
  raise exception 'import failed: card count mismatch source %, copied %',expected_cards,copied_cards;
 end if;

 return out_rows;
end
$$;

grant execute on function public.import_word_cards(uuid,jsonb) to authenticated;
