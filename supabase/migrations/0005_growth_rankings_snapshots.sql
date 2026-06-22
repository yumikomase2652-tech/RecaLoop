-- Final growth model: EXP, levels and titles. Character features are intentionally removed.
drop table if exists public.user_character_items cascade;
drop table if exists public.character_items cascade;
drop function if exists public.unlock_character_item(uuid);
drop function if exists public.equip_character_item(uuid);
alter table public.profiles drop column if exists spendable_exp;
alter table public.profiles drop column if exists character_stage;
alter table public.profiles drop column if exists character_name;
alter table public.profiles drop column if exists equipped_color;
alter table public.profiles drop column if exists equipped_outfit;
alter table public.profiles drop column if exists equipped_item;
alter table public.profiles drop column if exists equipped_background;

alter table public.profiles add column if not exists total_exp int not null default 0;
alter table public.profiles add column if not exists level int not null default 1;
alter table public.profiles add column if not exists target_school text;
alter table public.profiles add column if not exists exam_year int;
alter table public.profiles add column if not exists study_goal text;

alter table public.material_decks add column if not exists updated_at timestamptz not null default now();
alter table public.material_decks add column if not exists published_snapshot jsonb;
alter table public.material_decks add column if not exists pending_snapshot jsonb;
alter table public.material_decks add column if not exists submission_kind text;
alter table public.material_decks add column if not exists source_content_id uuid;
alter table public.material_decks add column if not exists last_copied_at timestamptz;
alter table public.word_lists add column if not exists updated_at timestamptz not null default now();
alter table public.word_lists add column if not exists published_snapshot jsonb;
alter table public.word_lists add column if not exists pending_snapshot jsonb;
alter table public.word_lists add column if not exists submission_kind text;
alter table public.word_lists add column if not exists source_content_id uuid;
alter table public.word_lists add column if not exists last_copied_at timestamptz;
-- Older databases did not consistently have these columns, while review_target updates them.
alter table public.material_item_states add column if not exists updated_at timestamptz not null default now();
alter table public.word_card_states add column if not exists updated_at timestamptz not null default now();

create table if not exists public.exp_transactions(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,
 amount int not null,reason text not null,reference_key text,created_at timestamptz not null default now(),
 unique(user_id,reason,reference_key)
);
alter table public.exp_transactions add column if not exists reference_key text;
create unique index if not exists exp_transactions_reference_key on public.exp_transactions(user_id,reason,reference_key)where reference_key is not null;

create table if not exists public.titles(
 id uuid primary key default gen_random_uuid(),title_key text not null unique,display_name text not null,
 title_type text not null check(title_type in('level','deck_completion')),condition_json jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
insert into public.titles(title_key,display_name,title_type,condition_json)values
 ('exp:100','見習い学習者','level','{"required_exp":100}'),
 ('exp:500','学び始めた者','level','{"required_exp":500}'),
 ('exp:1000','継続の達人','level','{"required_exp":1000}'),
 ('exp:2000','努力の証','level','{"required_exp":2000}'),
 ('exp:5000','知識の収集家','level','{"required_exp":5000}'),
 ('exp:10000','探究者','level','{"required_exp":10000}'),
 ('exp:20000','学者','level','{"required_exp":20000}'),
 ('exp:40000','賢者','level','{"required_exp":40000}')
on conflict(title_key)do update set display_name=excluded.display_name,title_type=excluded.title_type,condition_json=excluded.condition_json;

-- Convert an earlier 0005 draft without losing already earned titles.
do $$begin
 if exists(select 1 from information_schema.columns where table_schema='public'and table_name='user_titles'and column_name='title_key')
 and not exists(select 1 from information_schema.columns where table_schema='public'and table_name='user_titles'and column_name='title_id')then
  alter table public.user_titles rename to user_titles_legacy_0005;
 end if;
end$$;
create table if not exists public.user_titles(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,
 title_id uuid not null references public.titles on delete cascade,source_type text,source_id uuid,
 earned_at timestamptz not null default now(),unique(user_id,title_id)
);
do $$begin
 if to_regclass('public.user_titles_legacy_0005')is not null then
  insert into public.titles(title_key,display_name,title_type,condition_json)
  select distinct title_key,title_name,case when source_type='exp'then'level'else'deck_completion'end,
   case when source_type='exp'then jsonb_build_object('required_exp',regexp_replace(title_key,'\D','','g')::int)else jsonb_build_object('source_type',source_type,'source_id',source_id)end
  from public.user_titles_legacy_0005 on conflict(title_key)do nothing;
  insert into public.user_titles(id,user_id,title_id,source_type,source_id,earned_at)
  select legacy.id,legacy.user_id,title.id,legacy.source_type,legacy.source_id,legacy.earned_at from public.user_titles_legacy_0005 legacy join public.titles title on title.title_key=legacy.title_key on conflict do nothing;
  drop table public.user_titles_legacy_0005;
 end if;
end$$;
alter table public.profiles add column if not exists equipped_title_id uuid references public.titles(id)on delete set null;
do $$begin
 if exists(select 1 from information_schema.columns where table_schema='public'and table_name='profiles'and column_name='title')then
  execute 'update public.profiles p set equipped_title_id=t.id from public.user_titles ut join public.titles t on t.id=ut.title_id where ut.user_id=p.id and t.display_name=p.title and p.equipped_title_id is null';
  alter table public.profiles drop column title;
 end if;
end$$;
create table if not exists public.study_sessions(
 id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,
 started_at timestamptz not null default now(),ended_at timestamptz,duration_minutes int,
 related_type text not null check(related_type in('material_deck','word_list')),related_id uuid,created_at timestamptz not null default now()
);

alter table public.exp_transactions enable row level security;
alter table public.titles enable row level security;
alter table public.user_titles enable row level security;
alter table public.study_sessions enable row level security;
drop policy if exists "exp own read" on public.exp_transactions;
create policy "exp own read" on public.exp_transactions for select using(user_id=auth.uid());
drop policy if exists "titles catalog read" on public.titles;
create policy "titles catalog read" on public.titles for select using(true);
drop policy if exists "titles own read" on public.user_titles;
create policy "titles own read" on public.user_titles for select using(user_id=auth.uid());
drop policy if exists "sessions own read" on public.study_sessions;
create policy "sessions own read" on public.study_sessions for select using(user_id=auth.uid());

drop policy if exists "profile own" on public.profiles;
drop policy if exists "profile own read" on public.profiles;
drop policy if exists "profile own editable fields" on public.profiles;
create policy "profile own read" on public.profiles for select using(id=auth.uid());
create policy "profile own editable fields" on public.profiles for update using(id=auth.uid())with check(id=auth.uid());
revoke update on public.profiles from anon,authenticated;
grant update(display_name,target_school,exam_year,study_goal)on public.profiles to authenticated;
revoke update on public.material_decks from anon,authenticated;
grant update(title,subject,description,updated_at)on public.material_decks to authenticated;
revoke insert on public.material_decks from anon,authenticated;
grant insert(user_id,title,subject,description)on public.material_decks to authenticated;
revoke update on public.word_lists from anon,authenticated;
grant update(title,subject,description,updated_at)on public.word_lists to authenticated;
revoke insert on public.word_lists from anon,authenticated;
grant insert(user_id,title,subject,description)on public.word_lists to authenticated;

create or replace function public.equip_title(p_title_id uuid)returns void language plpgsql security definer set search_path=public as $$begin
 if p_title_id is not null and not exists(select 1 from user_titles where user_id=auth.uid()and title_id=p_title_id)then raise exception'未獲得の称号です';end if;
 update profiles set equipped_title_id=p_title_id where id=auth.uid();
end$$;

create or replace function public.set_distribution(p_type text,p_id uuid,p_enabled boolean)returns text language plpgsql security definer set search_path=public as $$declare token text;current_visibility text;begin
 if p_type='material'then select visibility into current_visibility from material_decks where id=p_id and user_id=auth.uid();if current_visibility not in('private','unlisted','rejected')then raise exception'この状態では配布設定を変更できません';end if;update material_decks set visibility=case when p_enabled then'unlisted'else'private'end,is_public=p_enabled,updated_at=now()where id=p_id returning share_token into token;
 else select visibility into current_visibility from word_lists where id=p_id and user_id=auth.uid();if current_visibility not in('private','unlisted','rejected')then raise exception'この状態では配布設定を変更できません';end if;update word_lists set visibility=case when p_enabled then'unlisted'else'private'end,is_public=p_enabled,updated_at=now()where id=p_id returning share_token into token;end if;
 if token is null then raise exception'not allowed';end if;return token;
end$$;

create or replace function public.content_snapshot(p_type text,p_id uuid)returns jsonb language plpgsql stable security definer set search_path=public as $$declare result jsonb;begin
 if p_type='material'then select jsonb_build_object('title',d.title,'description',d.description,'nodes',coalesce((select jsonb_agg(jsonb_build_object('id',n.id,'parent_id',n.parent_id,'node_type',n.node_type,'title',n.title,'memo',n.memo,'order_index',n.order_index)order by n.order_index,n.created_at)from material_nodes n where n.deck_id=d.id),'[]'::jsonb))into result from material_decks d where d.id=p_id;
 else select jsonb_build_object('title',l.title,'description',l.description,'cards',coalesce((select jsonb_agg(jsonb_build_object('card_id',c.card_id,'front',c.front,'back',c.back,'memo',c.memo,'order_index',c.order_index)order by c.order_index,c.created_at)from word_cards c where c.list_id=l.id),'[]'::jsonb))into result from word_lists l where l.id=p_id;end if;return result;
end$$;
revoke all on function public.content_snapshot(text,uuid)from public,anon,authenticated;

update public.material_decks set published_snapshot=public.content_snapshot('material',id)where visibility='approved'and published_snapshot is null;
update public.word_lists set published_snapshot=public.content_snapshot('cards',id)where visibility='approved'and published_snapshot is null;
update public.material_decks set pending_snapshot=public.content_snapshot('material',id),submission_kind='initial'where visibility='submitted'and pending_snapshot is null;
update public.word_lists set pending_snapshot=public.content_snapshot('cards',id),submission_kind='initial'where visibility='submitted'and pending_snapshot is null;

create or replace function public.submit_content(p_type text,p_id uuid)returns void language plpgsql security definer set search_path=public as $$declare snap jsonb;current_visibility text;begin
 snap:=public.content_snapshot(p_type,p_id);
 if p_type='material'then select visibility into current_visibility from material_decks where id=p_id and user_id=auth.uid();if current_visibility is null then raise exception'not allowed';end if;update material_decks set pending_snapshot=snap,submission_kind=case when current_visibility='approved'then'update'else'initial'end,visibility=case when current_visibility='approved'then'approved'else'submitted'end,is_public=current_visibility='approved',submitted_at=now(),rejected_reason=null,created_by_user_id=coalesce(created_by_user_id,auth.uid()),updated_at=now()where id=p_id;
 else select visibility into current_visibility from word_lists where id=p_id and user_id=auth.uid();if current_visibility is null then raise exception'not allowed';end if;update word_lists set pending_snapshot=snap,submission_kind=case when current_visibility='approved'then'update'else'initial'end,visibility=case when current_visibility='approved'then'approved'else'submitted'end,is_public=current_visibility='approved',submitted_at=now(),rejected_reason=null,created_by_user_id=coalesce(created_by_user_id,auth.uid()),updated_at=now()where id=p_id;end if;
end$$;

create or replace function public.moderate_submission(p_type text,p_id uuid,p_approve boolean,p_reason text default null)returns void language plpgsql security definer set search_path=public as $$declare kind text;begin
 if not public.is_admin()then raise exception'admin only';end if;if not p_approve and coalesce(trim(p_reason),'')=''then raise exception'rejection reason required';end if;
 if p_type='material'then select submission_kind into kind from material_decks where id=p_id and pending_snapshot is not null;if kind is null then raise exception'not found';end if;update material_decks set published_snapshot=case when p_approve then pending_snapshot else published_snapshot end,pending_snapshot=null,submission_kind=null,visibility=case when p_approve or kind='update'then'approved'else'rejected'end,is_public=p_approve or kind='update',approved_at=case when p_approve then now()else approved_at end,rejected_reason=case when p_approve then null else p_reason end,updated_at=now()where id=p_id;
 else select submission_kind into kind from word_lists where id=p_id and pending_snapshot is not null;if kind is null then raise exception'not found';end if;update word_lists set published_snapshot=case when p_approve then pending_snapshot else published_snapshot end,pending_snapshot=null,submission_kind=null,visibility=case when p_approve or kind='update'then'approved'else'rejected'end,is_public=p_approve or kind='update',approved_at=case when p_approve then now()else approved_at end,rejected_reason=case when p_approve then null else p_reason end,updated_at=now()where id=p_id;end if;
end$$;

drop policy if exists "material decks public read" on public.material_decks;
drop policy if exists "material nodes public read" on public.material_nodes;
drop policy if exists "word lists public read" on public.word_lists;
drop policy if exists "word cards public read" on public.word_cards;
drop policy if exists "material decks unlisted read" on public.material_decks;
drop policy if exists "material nodes unlisted read" on public.material_nodes;
drop policy if exists "word lists unlisted read" on public.word_lists;
drop policy if exists "word cards unlisted read" on public.word_cards;
create policy "material decks unlisted read" on public.material_decks for select using(visibility='unlisted');
create policy "material nodes unlisted read" on public.material_nodes for select using(exists(select 1 from material_decks d where d.id=deck_id and d.visibility='unlisted'));
create policy "word lists unlisted read" on public.word_lists for select using(visibility='unlisted');
create policy "word cards unlisted read" on public.word_cards for select using(exists(select 1 from word_lists l where l.id=list_id and l.visibility='unlisted'));

create or replace function public.shared_content(p_type text,p_token text)returns jsonb language plpgsql stable security definer set search_path=public as $$declare result jsonb;begin
 if p_type='material'then select(case when visibility='approved'then published_snapshot else public.content_snapshot('material',id)end)||jsonb_build_object('id',id,'visibility',visibility,'share_token',share_token)into result from material_decks where share_token=p_token and visibility in('unlisted','approved');
 else select(case when visibility='approved'then published_snapshot else public.content_snapshot('cards',id)end)||jsonb_build_object('id',id,'visibility',visibility,'share_token',share_token)into result from word_lists where share_token=p_token and visibility in('unlisted','approved');end if;return result;
end$$;

create or replace function public.copy_shared_material(p_token text)returns uuid language plpgsql security definer set search_path=public as $$declare source_id uuid;new_deck uuid;snap jsonb;n record;new_node uuid;node_map jsonb:='{}';begin
 if auth.uid()is null then raise exception'login required';end if;select id,case when visibility='approved'then published_snapshot else public.content_snapshot('material',id)end into source_id,snap from material_decks where share_token=p_token and visibility in('unlisted','approved');if source_id is null then raise exception'not found';end if;insert into material_decks(user_id,title,description,created_by_user_id,source_content_id)values(auth.uid(),snap->>'title',snap->>'description',auth.uid(),source_id)returning id into new_deck;
 for n in with recursive source as(select*from jsonb_to_recordset(snap->'nodes')as x(id uuid,parent_id uuid,node_type text,title text,memo text,order_index int)),tree as(select s.*,0 depth from source s where parent_id is null union all select s.*,t.depth+1 from source s join tree t on s.parent_id=t.id)select*from tree order by depth,order_index loop insert into material_nodes(deck_id,parent_id,node_type,title,memo,order_index)values(new_deck,case when n.parent_id is null then null else(node_map->>n.parent_id::text)::uuid end,n.node_type,n.title,n.memo,n.order_index)returning id into new_node;node_map:=node_map||jsonb_build_object(n.id::text,new_node::text);end loop;
 update material_decks set copy_count=copy_count+1,last_copied_at=now()where id=source_id;return new_deck;
end$$;
create or replace function public.copy_shared_cards(p_token text)returns uuid language plpgsql security definer set search_path=public as $$declare source_id uuid;new_list uuid;snap jsonb;begin
 if auth.uid()is null then raise exception'login required';end if;select id,case when visibility='approved'then published_snapshot else public.content_snapshot('cards',id)end into source_id,snap from word_lists where share_token=p_token and visibility in('unlisted','approved');if source_id is null then raise exception'not found';end if;insert into word_lists(user_id,title,description,created_by_user_id,source_content_id)values(auth.uid(),snap->>'title',snap->>'description',auth.uid(),source_id)returning id into new_list;insert into word_cards(list_id,card_id,front,back,memo,order_index)select new_list,x.card_id,x.front,x.back,x.memo,x.order_index from jsonb_to_recordset(snap->'cards')as x(card_id text,front text,back text,memo text,order_index int);update word_lists set copy_count=copy_count+1,last_copied_at=now()where id=source_id;return new_list;
end$$;

drop function if exists public.library_items(text,text);
create function public.library_items(p_query text default'',p_type text default'all')returns table(content_type text,id uuid,title text,creator_name text,item_count bigint,copy_count int,updated_at timestamptz,share_token text,clear_titles jsonb)language sql stable security definer set search_path=public as $$
 select*from(
  select'material'::text content_type,d.id,(d.published_snapshot->>'title')::text title,coalesce(p.display_name,'ユーザー')::text creator_name,(select count(*)from jsonb_array_elements(coalesce(d.published_snapshot->'nodes','[]'::jsonb))n where n->>'node_type'='item')::bigint item_count,d.copy_count::int,coalesce(d.approved_at,d.updated_at,d.created_at)::timestamptz updated_at,d.share_token::text,coalesce((select jsonb_agg(jsonb_build_object('name',q.display_name,'count',q.cnt)order by q.cnt desc)from(select t.display_name,count(*)::int cnt from user_titles ut join titles t on t.id=ut.title_id where t.title_type='deck_completion'and ut.source_type='material'and ut.source_id=d.id group by t.display_name having count(*)>=3)q),'[]'::jsonb)clear_titles from material_decks d left join profiles p on p.id=d.created_by_user_id where d.visibility='approved'and d.published_snapshot is not null and p_type in('all','material')and(p_query=''or d.published_snapshot->>'title'ilike'%'||p_query||'%')
  union all
  select'cards'::text content_type,l.id,(l.published_snapshot->>'title')::text title,coalesce(p.display_name,'ユーザー')::text creator_name,jsonb_array_length(coalesce(l.published_snapshot->'cards','[]'::jsonb))::bigint item_count,l.copy_count::int,coalesce(l.approved_at,l.updated_at,l.created_at)::timestamptz updated_at,l.share_token::text,coalesce((select jsonb_agg(jsonb_build_object('name',q.display_name,'count',q.cnt)order by q.cnt desc)from(select t.display_name,count(*)::int cnt from user_titles ut join titles t on t.id=ut.title_id where t.title_type='deck_completion'and ut.source_type='cards'and ut.source_id=l.id group by t.display_name having count(*)>=3)q),'[]'::jsonb)clear_titles from word_lists l left join profiles p on p.id=l.created_by_user_id where l.visibility='approved'and l.published_snapshot is not null and p_type in('all','cards')and(p_query=''or l.published_snapshot->>'title'ilike'%'||p_query||'%')
 )items order by items.updated_at desc
$$;

drop function if exists public.admin_submissions();
create function public.admin_submissions()returns table(content_type text,id uuid,title text,creator_name text,item_count bigint,copy_count int,updated_at timestamptz,share_token text,description text,submitted_at timestamptz,rejected_reason text,submission_kind text)language sql stable security definer set search_path=public as $$
 select'material'::text,d.id,(d.pending_snapshot->>'title')::text,coalesce(p.display_name,'ユーザー')::text,(select count(*)from jsonb_array_elements(coalesce(d.pending_snapshot->'nodes','[]'::jsonb))n where n->>'node_type'='item')::bigint,d.copy_count::int,coalesce(d.updated_at,d.created_at)::timestamptz,d.share_token::text,(d.pending_snapshot->>'description')::text,d.submitted_at::timestamptz,d.rejected_reason::text,d.submission_kind::text from material_decks d left join profiles p on p.id=d.created_by_user_id where d.pending_snapshot is not null and public.is_admin()
 union all
 select'cards'::text,l.id,(l.pending_snapshot->>'title')::text,coalesce(p.display_name,'ユーザー')::text,jsonb_array_length(coalesce(l.pending_snapshot->'cards','[]'::jsonb))::bigint,l.copy_count::int,coalesce(l.updated_at,l.created_at)::timestamptz,l.share_token::text,(l.pending_snapshot->>'description')::text,l.submitted_at::timestamptz,l.rejected_reason::text,l.submission_kind::text from word_lists l left join profiles p on p.id=l.created_by_user_id where l.pending_snapshot is not null and public.is_admin()order by submitted_at
$$;
create or replace function public.admin_submission_content(p_type text,p_id uuid)returns jsonb language plpgsql stable security definer set search_path=public as $$declare result jsonb;begin if not public.is_admin()then raise exception'admin only';end if;if p_type='material'then select pending_snapshot into result from material_decks where id=p_id;else select pending_snapshot into result from word_lists where id=p_id;end if;return result;end$$;

drop function if exists public.review_target(text,uuid,rating,boolean);
drop function if exists public.sync_exp_titles();
drop function if exists public.grant_exp(int,text,text);
create function public.grant_exp(p_amount int,p_reason text,p_reference text)returns boolean language plpgsql security definer set search_path=public as $$begin
 insert into exp_transactions(user_id,amount,reason,reference_key)values(auth.uid(),p_amount,p_reason,p_reference)on conflict do nothing;
 if found then update profiles set total_exp=total_exp+p_amount,level=1+((total_exp+p_amount)/100)where id=auth.uid();return true;end if;return false;
end$$;
revoke all on function public.grant_exp(int,text,text)from public,anon,authenticated;

create or replace function public.sync_exp_titles()returns jsonb language plpgsql security definer set search_path=public as $$declare total int;result jsonb:='[]'::jsonb;r record;inserted_id uuid;begin
 select total_exp into total from profiles where id=auth.uid();
 for r in select id,display_name,(condition_json->>'required_exp')::int required_exp from titles where title_type='level'and(condition_json->>'required_exp')::int<=total order by required_exp loop
  inserted_id:=null;insert into user_titles(user_id,title_id,source_type)values(auth.uid(),r.id,'level')on conflict do nothing returning id into inserted_id;if inserted_id is not null then update profiles set equipped_title_id=r.id where id=auth.uid();result:=result||jsonb_build_array(r.display_name);end if;
 end loop;return result;
end$$;
revoke all on function public.sync_exp_titles()from public,anon,authenticated;

drop function if exists public.review_target(text,uuid,rating,boolean);
create function public.review_target(p_type text,p_id uuid,p_rating rating,p_unknown boolean)returns jsonb language plpgsql security definer set search_path=public as $$
declare days int;prior_count int:=0;attempt_id uuid:=gen_random_uuid();v_deck_id uuid;v_source_id uuid;v_deck_title text;v_title_id uuid;all_count int;done_count int;exp_gained int:=0;new_titles jsonb:='[]'::jsonb;inserted_title uuid;begin
 if p_type='material'then
  select n.deck_id,coalesce(s.review_count,0)into v_deck_id,prior_count from material_nodes n join material_decks d on d.id=n.deck_id left join material_item_states s on s.material_node_id=n.id and s.user_id=auth.uid()where n.id=p_id and n.node_type='item'and d.user_id=auth.uid();if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then insert into material_item_states(user_id,material_node_id,unknown_flag)values(auth.uid(),p_id,p_unknown)on conflict(user_id,material_node_id)do update set unknown_flag=p_unknown,updated_at=now();insert into material_attempts(id,user_id,material_node_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,null,p_unknown,'check');
  else days:=case p_rating when'again'then 0 when'hard'then 1 when'good'then 3 else 7 end;insert into material_item_states(user_id,material_node_id,last_rating,unknown_flag,review_count,due_at,next_review_date)values(auth.uid(),p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)on conflict(user_id,material_node_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=material_item_states.review_count+1,due_at=now()+make_interval(days=>days),next_review_date=current_date+days,updated_at=now();insert into material_attempts(id,user_id,material_node_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,p_rating,p_unknown,'review');if grant_exp(5,'material_rating',attempt_id::text)then exp_gained:=exp_gained+5;end if;if prior_count>0 and grant_exp(5,'review_complete',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   select count(*)into all_count from material_nodes where material_nodes.deck_id=v_deck_id and node_type='item';select count(*)into done_count from material_item_states s join material_nodes n on n.id=s.material_node_id where n.deck_id=v_deck_id and s.user_id=auth.uid()and s.last_rating is not null;
   if all_count>0 and done_count=all_count and grant_exp(50,'deck_complete','material:'||v_deck_id::text)then exp_gained:=exp_gained+50;select coalesce(d.source_content_id,d.id),coalesce(src.published_snapshot->>'title',d.title)into v_source_id,v_deck_title from material_decks d left join material_decks src on src.id=d.source_content_id where d.id=v_deck_id;insert into titles(title_key,display_name,title_type,condition_json)values('deck_completion:material:'||v_source_id::text,v_deck_title||' 完走','deck_completion',jsonb_build_object('source_type','material','source_id',v_source_id))on conflict(title_key)do update set display_name=excluded.display_name,condition_json=excluded.condition_json returning id into v_title_id;inserted_title:=null;insert into user_titles(user_id,title_id,source_type,source_id)values(auth.uid(),v_title_id,'material',v_source_id)on conflict do nothing returning id into inserted_title;if inserted_title is not null then update profiles set equipped_title_id=v_title_id where id=auth.uid();new_titles:=new_titles||jsonb_build_array(v_deck_title||' 完走');end if;end if;
  end if;
 else
  select c.list_id,coalesce(s.review_count,0)into v_deck_id,prior_count from word_cards c join word_lists l on l.id=c.list_id left join word_card_states s on s.word_card_id=c.id and s.user_id=auth.uid()where c.id=p_id and l.user_id=auth.uid();if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then insert into word_card_states(user_id,word_card_id,unknown_flag)values(auth.uid(),p_id,p_unknown)on conflict(user_id,word_card_id)do update set unknown_flag=p_unknown,updated_at=now();insert into word_attempts(id,user_id,word_card_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,null,p_unknown,'check');
  else days:=case p_rating when'again'then 0 when'hard'then 1 when'good'then 3 else 7 end;insert into word_card_states(user_id,word_card_id,last_rating,unknown_flag,review_count,due_at,next_review_date)values(auth.uid(),p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)on conflict(user_id,word_card_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=word_card_states.review_count+1,due_at=now()+make_interval(days=>days),next_review_date=current_date+days,updated_at=now();insert into word_attempts(id,user_id,word_card_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,p_rating,p_unknown,'review');if grant_exp(3,'word_rating',attempt_id::text)then exp_gained:=exp_gained+3;end if;if prior_count>0 and grant_exp(5,'review_complete',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   select count(*)into all_count from word_cards where word_cards.list_id=v_deck_id;select count(*)into done_count from word_card_states s join word_cards c on c.id=s.word_card_id where c.list_id=v_deck_id and s.user_id=auth.uid()and s.last_rating is not null;
   if all_count>0 and done_count=all_count and grant_exp(50,'deck_complete','cards:'||v_deck_id::text)then exp_gained:=exp_gained+50;select coalesce(l.source_content_id,l.id),coalesce(src.published_snapshot->>'title',l.title)into v_source_id,v_deck_title from word_lists l left join word_lists src on src.id=l.source_content_id where l.id=v_deck_id;insert into titles(title_key,display_name,title_type,condition_json)values('deck_completion:cards:'||v_source_id::text,v_deck_title||' 完走','deck_completion',jsonb_build_object('source_type','cards','source_id',v_source_id))on conflict(title_key)do update set display_name=excluded.display_name,condition_json=excluded.condition_json returning id into v_title_id;inserted_title:=null;insert into user_titles(user_id,title_id,source_type,source_id)values(auth.uid(),v_title_id,'cards',v_source_id)on conflict do nothing returning id into inserted_title;if inserted_title is not null then update profiles set equipped_title_id=v_title_id where id=auth.uid();new_titles:=new_titles||jsonb_build_array(v_deck_title||' 完走');end if;end if;
  end if;
 end if;
 if p_rating is not null and(exists(select 1 from material_attempts where user_id=auth.uid()and rating is not null and reviewed_at::date=current_date-1)or exists(select 1 from word_attempts where user_id=auth.uid()and rating is not null and reviewed_at::date=current_date-1))and grant_exp(10,'daily_streak',current_date::text)then exp_gained:=exp_gained+10;end if;
 if p_rating is not null then new_titles:=new_titles||public.sync_exp_titles();end if;return jsonb_build_object('exp_gained',exp_gained,'new_titles',new_titles,'deck_completed',coalesce(all_count>0 and done_count=all_count,false));
end$$;

create or replace function public.start_study_session(p_related_type text,p_related_id uuid)returns uuid language plpgsql security definer set search_path=public as $$declare result uuid;begin insert into study_sessions(user_id,related_type,related_id)values(auth.uid(),p_related_type,p_related_id)returning id into result;return result;end$$;
create or replace function public.end_study_session(p_session_id uuid)returns void language plpgsql security definer set search_path=public as $$begin update study_sessions set ended_at=now(),duration_minutes=greatest(1,ceil(extract(epoch from(now()-started_at))/60)::int)where id=p_session_id and user_id=auth.uid()and ended_at is null;end$$;

drop function if exists public.rankings();
create function public.rankings()returns table(content_type text,id uuid,title text,creator_name text,copy_count int,sample_count bigint,average_progress numeric,completion_rate numeric,continuation_rate numeric,approved_at timestamptz,last_copied_at timestamptz)language sql stable security definer set search_path=public as $$
 with sources(content_type,id,title,creator_name,copy_count,approved_at,last_copied_at)as(
  select'material'::text,d.id,(d.published_snapshot->>'title')::text,coalesce(p.display_name,'ユーザー')::text,d.copy_count::int,coalesce(d.approved_at,d.updated_at,d.created_at)::timestamptz,d.last_copied_at::timestamptz from material_decks d left join profiles p on p.id=d.created_by_user_id where d.visibility='approved'
  union all
  select'cards'::text,l.id,(l.published_snapshot->>'title')::text,coalesce(p.display_name,'ユーザー')::text,l.copy_count::int,coalesce(l.approved_at,l.updated_at,l.created_at)::timestamptz,l.last_copied_at::timestamptz from word_lists l left join profiles p on p.id=l.created_by_user_id where l.visibility='approved'),
 instances(content_type,source_id,instance_id,user_id,total_count,done_count,study_days)as(
  select'material'::text,d.source_content_id,d.id,d.user_id,(select count(*)::bigint from material_nodes n where n.deck_id=d.id and n.node_type='item'),(select count(*)::bigint from material_item_states s join material_nodes n on n.id=s.material_node_id where n.deck_id=d.id and s.user_id=d.user_id and s.last_rating is not null),(select count(distinct a.reviewed_at::date)::bigint from material_attempts a join material_nodes n on n.id=a.material_node_id where n.deck_id=d.id and a.user_id=d.user_id and a.rating is not null)from material_decks d where d.source_content_id is not null
  union all
  select'cards'::text,l.source_content_id,l.id,l.user_id,(select count(*)::bigint from word_cards c where c.list_id=l.id),(select count(*)::bigint from word_card_states s join word_cards c on c.id=s.word_card_id where c.list_id=l.id and s.user_id=l.user_id and s.last_rating is not null),(select count(distinct a.reviewed_at::date)::bigint from word_attempts a join word_cards c on c.id=a.word_card_id where c.list_id=l.id and a.user_id=l.user_id and a.rating is not null)from word_lists l where l.source_content_id is not null),
 stats(content_type,source_id,sample_count,average_progress,completion_rate,continuation_rate)as(select i.content_type,i.source_id,count(*)::bigint,avg(case when i.total_count>0 then i.done_count::numeric/i.total_count*100 else 0::numeric end)::numeric,avg(case when i.total_count>0 and i.done_count=i.total_count then 100::numeric else 0::numeric end)::numeric,avg(case when i.study_days>=2 then 100::numeric else 0::numeric end)::numeric from instances i group by i.content_type,i.source_id)
 select s.content_type,s.id,s.title,s.creator_name,s.copy_count,coalesce(t.sample_count,0::bigint),case when t.sample_count>=3 then round(t.average_progress,1)else null::numeric end,case when t.sample_count>=3 then round(t.completion_rate,1)else null::numeric end,case when t.sample_count>=3 then round(t.continuation_rate,1)else null::numeric end,s.approved_at,s.last_copied_at from sources s left join stats t on t.content_type=s.content_type and t.source_id=s.id
$$;
