-- Streak titles and deck-completion title cleanup.
-- Deck completion titles are displayed under a "デッキ完走称号" heading, so the title itself should be the deck name only.

alter table public.titles drop constraint if exists titles_title_type_check;
alter table public.titles add constraint titles_title_type_check check(title_type in('level','deck_completion','streak'));

insert into public.titles(title_key,display_name,title_type,condition_json)values
 ('exp:100','見習い学習者','level','{"required_exp":100}'),
 ('exp:500','学びの軌道','level','{"required_exp":500}'),
 ('exp:1000','基礎固め','level','{"required_exp":1000}'),
 ('exp:2000','努力の証','level','{"required_exp":2000}'),
 ('exp:5000','知識の収集家','level','{"required_exp":5000}'),
 ('exp:10000','探究者','level','{"required_exp":10000}'),
 ('exp:20000','学者','level','{"required_exp":20000}'),
 ('exp:40000','賢者','level','{"required_exp":40000}'),
 ('streak:7','継続の芽','streak','{"required_days":7}'),
 ('streak:30','習慣化ビギナー','streak','{"required_days":30}'),
 ('streak:100','継続の達人','streak','{"required_days":100}'),
 ('streak:365','継続マスター','streak','{"required_days":365}'),
 ('streak:1000','継続の化身','streak','{"required_days":1000}')
on conflict(title_key)do update set display_name=excluded.display_name,title_type=excluded.title_type,condition_json=excluded.condition_json;

update public.titles
set display_name=regexp_replace(display_name,'\s+完走$','')
where title_type='deck_completion'and display_name like '% 完走';

drop function if exists public.sync_streak_titles();
create function public.sync_streak_titles()returns jsonb language plpgsql security definer set search_path=public as $$
declare streak_days int:=0;result jsonb:='[]'::jsonb;r record;inserted_id uuid;begin
 with active_days as(
  select reviewed_at::date as active_day from material_attempts where user_id=auth.uid()and rating is not null
  union
  select reviewed_at::date as active_day from word_attempts where user_id=auth.uid()and rating is not null
 ), calendar as(
  select generate_series(current_date-1100,current_date,interval'1 day')::date as calendar_day
 ), last_gap as(
  select max(c.calendar_day) as gap_day from calendar c where not exists(select 1 from active_days a where a.active_day=c.calendar_day)
 )
 select current_date-coalesce((select gap_day from last_gap),current_date-1101) into streak_days;

 for r in select id,display_name,(condition_json->>'required_days')::int required_days from titles where title_type='streak'and(condition_json->>'required_days')::int<=streak_days order by required_days loop
  inserted_id:=null;
  insert into user_titles(user_id,title_id,source_type)values(auth.uid(),r.id,'streak')on conflict do nothing returning id into inserted_id;
  if inserted_id is not null then
   update profiles set equipped_title_id=r.id where id=auth.uid();
   result:=result||jsonb_build_array(r.display_name);
  end if;
 end loop;
 return result;
end$$;
revoke all on function public.sync_streak_titles()from public,anon,authenticated;

drop function if exists public.review_target(text,uuid,rating,boolean);
create function public.review_target(p_type text,p_id uuid,p_rating rating,p_unknown boolean)returns jsonb language plpgsql security definer set search_path=public as $$
declare days int;prior_count int:=0;attempt_id uuid:=gen_random_uuid();v_deck_id uuid;v_source_id uuid;v_deck_title text;v_title_id uuid;all_count int;done_count int;exp_gained int:=0;new_titles jsonb:='[]'::jsonb;inserted_title uuid;begin
 if p_type='material'then
  select n.deck_id,coalesce(s.review_count,0)into v_deck_id,prior_count from material_nodes n join material_decks d on d.id=n.deck_id left join material_item_states s on s.material_node_id=n.id and s.user_id=auth.uid()where n.id=p_id and n.node_type='item'and d.user_id=auth.uid();if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then
   insert into material_item_states(user_id,material_node_id,unknown_flag)values(auth.uid(),p_id,p_unknown)on conflict(user_id,material_node_id)do update set unknown_flag=p_unknown,updated_at=now();
   insert into material_attempts(id,user_id,material_node_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,null,p_unknown,'check');
  else
   days:=case p_rating when'again'then 0 when'hard'then 1 when'good'then 3 else 7 end;
   insert into material_item_states(user_id,material_node_id,last_rating,unknown_flag,review_count,due_at,next_review_date)values(auth.uid(),p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)on conflict(user_id,material_node_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=material_item_states.review_count+1,due_at=now()+make_interval(days=>days),next_review_date=current_date+days,updated_at=now();
   insert into material_attempts(id,user_id,material_node_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,p_rating,p_unknown,'review');
   if grant_exp(5,'material_rating',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   if prior_count>0 and grant_exp(5,'review_complete',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   select count(*)into all_count from material_nodes where material_nodes.deck_id=v_deck_id and node_type='item';
   select count(*)into done_count from material_item_states s join material_nodes n on n.id=s.material_node_id where n.deck_id=v_deck_id and s.user_id=auth.uid()and s.last_rating is not null;
   if all_count>0 and done_count=all_count and grant_exp(50,'deck_complete','material:'||v_deck_id::text)then
    exp_gained:=exp_gained+50;
    select coalesce(d.source_content_id,d.id),coalesce(src.published_snapshot->>'title',d.title)into v_source_id,v_deck_title from material_decks d left join material_decks src on src.id=d.source_content_id where d.id=v_deck_id;
    insert into titles(title_key,display_name,title_type,condition_json)values('deck_completion:material:'||v_source_id::text,v_deck_title,'deck_completion',jsonb_build_object('source_type','material','source_id',v_source_id))on conflict(title_key)do update set display_name=excluded.display_name,condition_json=excluded.condition_json returning id into v_title_id;
    inserted_title:=null;insert into user_titles(user_id,title_id,source_type,source_id)values(auth.uid(),v_title_id,'material',v_source_id)on conflict do nothing returning id into inserted_title;
    if inserted_title is not null then update profiles set equipped_title_id=v_title_id where id=auth.uid();new_titles:=new_titles||jsonb_build_array(v_deck_title);end if;
   end if;
  end if;
 else
  select c.list_id,coalesce(s.review_count,0)into v_deck_id,prior_count from word_cards c join word_lists l on l.id=c.list_id left join word_card_states s on s.word_card_id=c.id and s.user_id=auth.uid()where c.id=p_id and l.user_id=auth.uid();if v_deck_id is null then raise exception'not allowed';end if;
  if p_rating is null then
   insert into word_card_states(user_id,word_card_id,unknown_flag)values(auth.uid(),p_id,p_unknown)on conflict(user_id,word_card_id)do update set unknown_flag=p_unknown,updated_at=now();
   insert into word_attempts(id,user_id,word_card_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,null,p_unknown,'check');
  else
   days:=case p_rating when'again'then 0 when'hard'then 1 when'good'then 3 else 7 end;
   insert into word_card_states(user_id,word_card_id,last_rating,unknown_flag,review_count,due_at,next_review_date)values(auth.uid(),p_id,p_rating,p_unknown,1,now()+make_interval(days=>days),current_date+days)on conflict(user_id,word_card_id)do update set last_rating=p_rating,unknown_flag=p_unknown,review_count=word_card_states.review_count+1,due_at=now()+make_interval(days=>days),next_review_date=current_date+days,updated_at=now();
   insert into word_attempts(id,user_id,word_card_id,rating,unknown_flag,action)values(attempt_id,auth.uid(),p_id,p_rating,p_unknown,'review');
   if grant_exp(3,'word_rating',attempt_id::text)then exp_gained:=exp_gained+3;end if;
   if prior_count>0 and grant_exp(5,'review_complete',attempt_id::text)then exp_gained:=exp_gained+5;end if;
   select count(*)into all_count from word_cards where word_cards.list_id=v_deck_id;
   select count(*)into done_count from word_card_states s join word_cards c on c.id=s.word_card_id where c.list_id=v_deck_id and s.user_id=auth.uid()and s.last_rating is not null;
   if all_count>0 and done_count=all_count and grant_exp(50,'deck_complete','cards:'||v_deck_id::text)then
    exp_gained:=exp_gained+50;
    select coalesce(l.source_content_id,l.id),coalesce(src.published_snapshot->>'title',l.title)into v_source_id,v_deck_title from word_lists l left join word_lists src on src.id=l.source_content_id where l.id=v_deck_id;
    insert into titles(title_key,display_name,title_type,condition_json)values('deck_completion:cards:'||v_source_id::text,v_deck_title,'deck_completion',jsonb_build_object('source_type','cards','source_id',v_source_id))on conflict(title_key)do update set display_name=excluded.display_name,condition_json=excluded.condition_json returning id into v_title_id;
    inserted_title:=null;insert into user_titles(user_id,title_id,source_type,source_id)values(auth.uid(),v_title_id,'cards',v_source_id)on conflict do nothing returning id into inserted_title;
    if inserted_title is not null then update profiles set equipped_title_id=v_title_id where id=auth.uid();new_titles:=new_titles||jsonb_build_array(v_deck_title);end if;
   end if;
  end if;
 end if;
 if p_rating is not null and(exists(select 1 from material_attempts where user_id=auth.uid()and rating is not null and reviewed_at::date=current_date-1)or exists(select 1 from word_attempts where user_id=auth.uid()and rating is not null and reviewed_at::date=current_date-1))and grant_exp(10,'daily_streak',current_date::text)then exp_gained:=exp_gained+10;end if;
 if p_rating is not null then new_titles:=new_titles||public.sync_exp_titles()||public.sync_streak_titles();end if;
 return jsonb_build_object('exp_gained',exp_gained,'new_titles',new_titles,'deck_completed',coalesce(all_count>0 and done_count=all_count,false));
end$$;
