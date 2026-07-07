alter table public.word_cards
  add column if not exists front_media_ids text[] not null default '{}',
  add column if not exists back_media_ids text[] not null default '{}';
