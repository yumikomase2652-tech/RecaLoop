create or replace function public.delete_owned_content(p_type text,p_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if auth.uid() is null then
    raise exception 'login required';
  end if;

  if p_type='material' then
    if not exists(select 1 from public.material_decks where id=p_id and user_id=auth.uid()) then
      raise exception 'not allowed';
    end if;
    delete from public.material_decks where id=p_id and user_id=auth.uid();
  elsif p_type='word' or p_type='cards' then
    if not exists(select 1 from public.word_lists where id=p_id and user_id=auth.uid()) then
      raise exception 'not allowed';
    end if;
    delete from public.word_lists where id=p_id and user_id=auth.uid();
  else
    raise exception 'invalid content type';
  end if;
end
$$;

grant execute on function public.delete_owned_content(text,uuid) to authenticated;
