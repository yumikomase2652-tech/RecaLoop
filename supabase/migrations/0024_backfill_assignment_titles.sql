alter table public.assignments add column if not exists deck_type text;
alter table public.assignments add column if not exists deck_id uuid;
alter table public.assignments add column if not exists updated_at timestamptz default now();

with targets as (
  select
    ai.assignment_id,
    'material'::text as deck_type,
    mn.deck_id,
    md.title
  from public.assignment_items ai
  join public.material_nodes mn
    on ai.target_type = 'material_item'
   and mn.id = ai.target_id
   and mn.node_type = 'item'
  join public.material_decks md on md.id = mn.deck_id
  union all
  select
    ai.assignment_id,
    'word'::text as deck_type,
    wc.list_id as deck_id,
    wl.title
  from public.assignment_items ai
  join public.word_cards wc
    on ai.target_type = 'word_card'
   and wc.id = ai.target_id
  join public.word_lists wl on wl.id = wc.list_id
),
resolved as (
  select
    assignment_id,
    (array_agg(deck_type order by deck_type))[1] as deck_type,
    (array_agg(deck_id order by deck_id::text))[1] as deck_id,
    (array_agg(title order by title))[1] as title,
    count(distinct deck_type || ':' || deck_id::text) as deck_count
  from targets
  group by assignment_id
)
update public.assignments a
set
  deck_type = r.deck_type,
  deck_id = r.deck_id,
  title = r.title,
  updated_at = now()
from resolved r
where a.id = r.assignment_id
  and r.deck_count = 1;
