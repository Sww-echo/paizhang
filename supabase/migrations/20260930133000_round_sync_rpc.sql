drop function if exists public.upsert_round_with_scores(uuid, uuid, integer, text, jsonb);

create or replace function public.upsert_round_with_scores(
  p_round_id uuid,
  p_session_id uuid,
  p_round_number integer,
  p_note text,
  p_changes jsonb,
  p_operation_id text,
  p_operation text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  target_room_id uuid;
  target_round_id uuid;
  change jsonb;
  player_id uuid;
begin
  if actor_id is null then
    raise exception 'not_authenticated';
  end if;
  if jsonb_typeof(p_changes) <> 'array' or jsonb_array_length(p_changes) = 0 then
    raise exception 'changes_required';
  end if;
  if p_operation not in ('create', 'update') then
    raise exception 'invalid_operation';
  end if;
  if p_operation_id is not null then
    select (payload ->> 'round_id')::uuid into target_round_id
    from public.sync_operations
    where operation_id = p_operation_id;
    if target_round_id is not null then
      return target_round_id;
    end if;
  end if;

  select room_id into target_room_id
  from public.game_sessions
  where id = p_session_id and status = 'active';
  if target_room_id is null or not public.can_input_room(target_room_id) then
    raise exception 'round_write_forbidden';
  end if;

  select id into target_round_id
  from public.rounds
  where (p_round_id is not null and id = p_round_id)
     or (session_id = p_session_id and round_number = p_round_number)
  limit 1;

  if target_round_id is null then
    insert into public.rounds (id, session_id, round_number, created_by, note)
    values (coalesce(p_round_id, gen_random_uuid()), p_session_id, p_round_number, actor_id, p_note)
    returning id into target_round_id;
  else
    update public.rounds
    set note = p_note, deleted_at = null, version = version + 1
    where id = target_round_id;
  end if;

  delete from public.score_changes where round_id = target_round_id;
  for change in select * from jsonb_array_elements(p_changes) loop
    player_id := (change ->> 'player_id')::uuid;
    if not exists (
      select 1 from public.room_members
      where room_id = target_room_id and user_id = player_id and left_at is null
    ) then
      raise exception 'player_not_in_room';
    end if;
    insert into public.score_changes (round_id, player_id, created_by, value)
    values (target_round_id, player_id, actor_id, (change ->> 'value')::integer);
  end loop;
  if p_operation_id is not null then
    insert into public.sync_operations (
      operation_id, actor_id, entity_type, entity_id, operation, payload
    ) values (
      p_operation_id,
      actor_id,
      'round',
      target_round_id,
      p_operation,
      jsonb_build_object('round_id', target_round_id)
    ) on conflict (operation_id) do nothing;
  end if;
  return target_round_id;
end;
$$;

revoke execute on function public.upsert_round_with_scores(uuid, uuid, integer, text, jsonb, text, text) from public, anon;
grant execute on function public.upsert_round_with_scores(uuid, uuid, integer, text, jsonb, text, text) to authenticated;
