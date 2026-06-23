alter table public.profiles add column if not exists grade_level text;
alter table public.profiles add column if not exists grade_updated_year int;
alter table public.profiles add column if not exists onboarding_completed boolean not null default false;
alter table public.profiles drop constraint if exists profiles_grade_level_check;
alter table public.profiles add constraint profiles_grade_level_check check(grade_level is null or grade_level in('中学1年生','中学2年生','中学3年生','高校1年生','高校2年生','高校3年生','浪人生'));
alter table public.profiles drop column if exists exam_year;
alter table public.profiles drop column if exists study_goal;

create or replace function public.current_academic_year()returns int language sql stable as $$select case when extract(month from current_date)>=4 then extract(year from current_date)::int else extract(year from current_date)::int-1 end$$;

create or replace function public.complete_onboarding(p_grade_level text,p_target_school text)returns void language plpgsql security definer set search_path=public as $$begin
 if p_grade_level not in('中学1年生','中学2年生','中学3年生','高校1年生','高校2年生','高校3年生','浪人生')then raise exception'学年を選択してください';end if;
 if nullif(trim(p_target_school),'')is null then raise exception'志望校を選択してください';end if;
 update profiles set grade_level=p_grade_level,target_school=p_target_school,grade_updated_year=public.current_academic_year(),onboarding_completed=true where id=auth.uid();
 if not found then raise exception'profile not found';end if;
end$$;

create or replace function public.update_learning_profile(p_display_name text,p_grade_level text,p_target_school text)returns void language plpgsql security definer set search_path=public as $$begin
 if p_grade_level not in('中学1年生','中学2年生','中学3年生','高校1年生','高校2年生','高校3年生','浪人生')then raise exception'学年を選択してください';end if;
 if nullif(trim(p_target_school),'')is null then raise exception'志望校を選択してください';end if;
 update profiles set display_name=trim(p_display_name),grade_level=p_grade_level,target_school=p_target_school,grade_updated_year=public.current_academic_year()where id=auth.uid();
 if not found then raise exception'profile not found';end if;
end$$;

create or replace function public.advance_grade_if_needed()returns void language plpgsql security definer set search_path=public as $$declare current_year int:=public.current_academic_year();saved_year int;grade text;steps int;begin
 select grade_updated_year,grade_level into saved_year,grade from profiles where id=auth.uid()and onboarding_completed;
 if grade is null then return;end if;
 steps:=greatest(0,current_year-coalesce(saved_year,current_year));
 while steps>0 loop
  grade:=case grade when'中学1年生'then'中学2年生'when'中学2年生'then'中学3年生'when'中学3年生'then'高校1年生'when'高校1年生'then'高校2年生'when'高校2年生'then'高校3年生'else'浪人生'end;
  steps:=steps-1;
 end loop;
 update profiles set grade_level=grade,grade_updated_year=current_year where id=auth.uid()and onboarding_completed and grade_updated_year is distinct from current_year;
end$$;

revoke update on public.profiles from authenticated;
grant update(display_name,target_school,grade_level,grade_updated_year,onboarding_completed)on public.profiles to authenticated;
