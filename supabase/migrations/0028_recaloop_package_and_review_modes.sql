alter table public.material_decks add column if not exists external_deck_id text;
alter table public.word_lists add column if not exists external_deck_id text;
alter table public.material_decks add column if not exists review_mode text not null default 'default';
alter table public.word_lists add column if not exists review_mode text not null default 'default';

alter table public.material_decks drop constraint if exists material_decks_review_mode_check;
alter table public.word_lists drop constraint if exists word_lists_review_mode_check;
alter table public.material_decks add constraint material_decks_review_mode_check check (review_mode in ('default','light'));
alter table public.word_lists add constraint word_lists_review_mode_check check (review_mode in ('default','light'));

create index if not exists material_decks_user_external_deck_id_idx on public.material_decks(user_id, external_deck_id) where external_deck_id is not null;
create index if not exists word_lists_user_external_deck_id_idx on public.word_lists(user_id, external_deck_id) where external_deck_id is not null;

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
 if nullif(trim(coalesce(p_front,'')),'') is null then
  raise exception 'invalid word card: front is required';
 end if;

 insert into word_cards(list_id,card_id,front,back,memo,order_index)
 values(p_list_id,nullif(trim(coalesce(p_card_id,'')),''),trim(p_front),coalesce(trim(p_back),''),p_memo,coalesce(p_order_index,0))
 returning * into new_row;

 return to_jsonb(new_row);
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
 where nullif(e->>'front','') is not null;

 if expected_cards=0 then
  raise exception 'invalid CSV: no word cards to import';
 end if;

 for c in
  select
   nullif(e.value->>'card_id','') card_id,
   nullif(e.value->>'front','') front,
   coalesce(e.value->>'back','') back,
   nullif(e.value->>'memo','') memo,
   coalesce(nullif(e.value->>'order_index','')::int,e.ord::int-1) order_index,
   e.ord::int ord
  from jsonb_array_elements(coalesce(p_cards,'[]'::jsonb)) with ordinality as e(value,ord)
  order by e.ord
 loop
  if c.front is null then
   raise exception 'invalid CSV: word card front is missing at row %',c.ord;
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

grant execute on function public.save_word_card(uuid,text,text,text,text,int) to authenticated;
grant execute on function public.import_word_cards(uuid,jsonb) to authenticated;
