alter table public.material_decks add column if not exists external_version text;
alter table public.word_lists add column if not exists external_version text;

create index if not exists material_decks_user_external_deck_version_idx
  on public.material_decks(user_id, external_deck_id, external_version)
  where external_deck_id is not null and deleted_at is null;

create index if not exists word_lists_user_external_deck_version_idx
  on public.word_lists(user_id, external_deck_id, external_version)
  where external_deck_id is not null and deleted_at is null;
