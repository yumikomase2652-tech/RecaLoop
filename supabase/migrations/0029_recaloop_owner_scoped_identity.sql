-- .recaloop files carry shared deckId/cardId values, but ownership must remain local
-- to the importing Supabase user. A deckId/cardId may therefore appear under many
-- different users. Remove accidental global uniqueness and keep owner-scoped lookup
-- indexes for imports.

do $$
declare
  r record;
begin
  for r in
    select c.conname
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'word_lists'
      and c.contype = 'u'
      and (
        select array_agg(a.attname::text order by a.attnum)
        from unnest(c.conkey) k(attnum)
        join pg_attribute a on a.attrelid = t.oid and a.attnum = k.attnum
      ) = array['external_deck_id']
  loop
    execute format('alter table public.word_lists drop constraint %I', r.conname);
  end loop;

  for r in
    select c.conname
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'material_decks'
      and c.contype = 'u'
      and (
        select array_agg(a.attname::text order by a.attnum)
        from unnest(c.conkey) k(attnum)
        join pg_attribute a on a.attrelid = t.oid and a.attnum = k.attnum
      ) = array['external_deck_id']
  loop
    execute format('alter table public.material_decks drop constraint %I', r.conname);
  end loop;

  for r in
    select c.conname
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'word_cards'
      and c.contype = 'u'
      and (
        select array_agg(a.attname::text order by a.attnum)
        from unnest(c.conkey) k(attnum)
        join pg_attribute a on a.attrelid = t.oid and a.attnum = k.attnum
      ) = array['card_id']
  loop
    execute format('alter table public.word_cards drop constraint %I', r.conname);
  end loop;
end $$;

drop index if exists public.word_lists_external_deck_id_key;
drop index if exists public.material_decks_external_deck_id_key;
drop index if exists public.word_cards_card_id_key;
drop index if exists public.word_lists_external_deck_id_idx;
drop index if exists public.material_decks_external_deck_id_idx;
drop index if exists public.word_cards_card_id_idx;

create index if not exists word_lists_user_external_deck_id_idx
  on public.word_lists(user_id, external_deck_id)
  where external_deck_id is not null and deleted_at is null;

create index if not exists material_decks_user_external_deck_id_idx
  on public.material_decks(user_id, external_deck_id)
  where external_deck_id is not null and deleted_at is null;

create index if not exists word_cards_list_card_id_idx
  on public.word_cards(list_id, card_id)
  where card_id is not null;

comment on column public.word_lists.external_deck_id is
  'Shared deckId from .recaloop. Not globally unique; imports must scope by user_id.';

comment on column public.material_decks.external_deck_id is
  'Shared deckId from .recaloop. Not globally unique; imports must scope by user_id.';

comment on column public.word_cards.card_id is
  'Shared cardId from .recaloop. Not globally unique; scope by owning list/user.';
