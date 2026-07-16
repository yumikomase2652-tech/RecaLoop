-- Cafeloop foundation additions for RecaLoop.
-- This migration only adds forward-compatible tables/columns.

alter table public.material_decks add column if not exists subject_category_id uuid;
alter table public.material_decks add column if not exists cover_media_id text;
alter table public.word_lists add column if not exists subject_category_id uuid;
alter table public.word_lists add column if not exists cover_media_id text;

create table if not exists public.subject_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  parent_id uuid references public.subject_categories(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique(user_id, parent_id, name)
);

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'material_decks_subject_category_id_fkey'
  ) then
    alter table public.material_decks
      add constraint material_decks_subject_category_id_fkey
      foreign key (subject_category_id) references public.subject_categories(id) on delete set null;
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'word_lists_subject_category_id_fkey'
  ) then
    alter table public.word_lists
      add constraint word_lists_subject_category_id_fkey
      foreign key (subject_category_id) references public.subject_categories(id) on delete set null;
  end if;
end $$;

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  goal_type text not null default 'custom'
    check (goal_type in ('study_minutes','question_count','review_count','deck_completion','custom')),
  target_value integer not null default 0 check (target_value >= 0),
  current_value integer not null default 0 check (current_value >= 0),
  period text not null default 'custom'
    check (period in ('daily','weekly','monthly','exam','custom')),
  start_date date,
  end_date date,
  status text not null default 'active'
    check (status in ('active','completed','paused','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  taken_at date not null,
  provider text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.test_subject_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  test_id uuid not null references public.tests(id) on delete cascade,
  subject_name text not null,
  score numeric,
  max_score numeric,
  deviation numeric,
  rank_text text,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.manual_study_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  studied_at date not null default current_date,
  minutes integer not null check (minutes > 0),
  subject text,
  material_deck_id uuid references public.material_decks(id) on delete set null,
  word_list_id uuid references public.word_lists(id) on delete set null,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subject_categories enable row level security;
alter table public.goals enable row level security;
alter table public.tests enable row level security;
alter table public.test_subject_results enable row level security;
alter table public.manual_study_logs enable row level security;

drop policy if exists "subject categories own select" on public.subject_categories;
create policy "subject categories own select" on public.subject_categories
  for select using (user_id = auth.uid());
drop policy if exists "subject categories own insert" on public.subject_categories;
create policy "subject categories own insert" on public.subject_categories
  for insert with check (user_id = auth.uid());
drop policy if exists "subject categories own update" on public.subject_categories;
create policy "subject categories own update" on public.subject_categories
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "subject categories own delete" on public.subject_categories;
create policy "subject categories own delete" on public.subject_categories
  for delete using (user_id = auth.uid());

drop policy if exists "goals own select" on public.goals;
create policy "goals own select" on public.goals for select using (user_id = auth.uid());
drop policy if exists "goals own insert" on public.goals;
create policy "goals own insert" on public.goals for insert with check (user_id = auth.uid());
drop policy if exists "goals own update" on public.goals;
create policy "goals own update" on public.goals for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "goals own delete" on public.goals;
create policy "goals own delete" on public.goals for delete using (user_id = auth.uid());

drop policy if exists "tests own select" on public.tests;
create policy "tests own select" on public.tests for select using (user_id = auth.uid());
drop policy if exists "tests own insert" on public.tests;
create policy "tests own insert" on public.tests for insert with check (user_id = auth.uid());
drop policy if exists "tests own update" on public.tests;
create policy "tests own update" on public.tests for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "tests own delete" on public.tests;
create policy "tests own delete" on public.tests for delete using (user_id = auth.uid());

drop policy if exists "test subject results own select" on public.test_subject_results;
create policy "test subject results own select" on public.test_subject_results
  for select using (user_id = auth.uid());
drop policy if exists "test subject results own insert" on public.test_subject_results;
create policy "test subject results own insert" on public.test_subject_results
  for insert with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.tests
      where tests.id = test_subject_results.test_id
      and tests.user_id = auth.uid()
    )
  );
drop policy if exists "test subject results own update" on public.test_subject_results;
create policy "test subject results own update" on public.test_subject_results
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "test subject results own delete" on public.test_subject_results;
create policy "test subject results own delete" on public.test_subject_results
  for delete using (user_id = auth.uid());

drop policy if exists "manual study logs own select" on public.manual_study_logs;
create policy "manual study logs own select" on public.manual_study_logs
  for select using (user_id = auth.uid());
drop policy if exists "manual study logs own insert" on public.manual_study_logs;
create policy "manual study logs own insert" on public.manual_study_logs
  for insert with check (user_id = auth.uid());
drop policy if exists "manual study logs own update" on public.manual_study_logs;
create policy "manual study logs own update" on public.manual_study_logs
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "manual study logs own delete" on public.manual_study_logs;
create policy "manual study logs own delete" on public.manual_study_logs
  for delete using (user_id = auth.uid());

drop policy if exists "study sessions own insert" on public.study_sessions;
create policy "study sessions own insert" on public.study_sessions
  for insert with check (user_id = auth.uid());
drop policy if exists "study sessions own update" on public.study_sessions;
create policy "study sessions own update" on public.study_sessions
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
