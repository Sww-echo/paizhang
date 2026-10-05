-- Versioned writes return the original acknowledgement, not a later round version.
create or replace function public.upsert_round_with_scores_v2(
  p_round_id uuid,
  p_session_id uuid,
  p_round_number integer,
  p_note text,
  p_changes jsonb,
  p_operation_id text,
  p_operation text,
  p_expected_version bigint,
  p_actor_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  target_room uuid;
  mode text;
  current_round public.rounds%rowtype;
  previous_operation public.sync_operations%rowtype;
  request_payload jsonb;
  result_payload jsonb;
  changes jsonb := p_changes;
  item jsonb;
  old_score record;
  next_number integer;
  total bigint;
begin
  if actor is null then raise exception 'not_authenticated'; end if;
  if p_actor_id is distinct from actor then raise exception 'not_authenticated'; end if;
  if p_round_id is null or p_operation_id is null or length(p_operation_id) = 0 then
    raise exception 'operation_id_required';
  end if;
  if p_operation not in ('create', 'update', 'delete') or p_operation is null then
    raise exception 'invalid_operation';
  end if;
  if jsonb_typeof(changes) is distinct from 'array' then raise exception 'changes_required'; end if;
  if p_operation <> 'delete' and jsonb_array_length(changes) = 0 then raise exception 'changes_required'; end if;
  if character_length(p_note) > 120 then raise exception 'note_too_long'; end if;
  request_payload := jsonb_build_object(
    'round_id', p_round_id, 'session_id', p_session_id, 'operation', p_operation,
    'note', p_note, 'changes', p_changes, 'expected_version', p_expected_version
  );
  perform pg_advisory_xact_lock(hashtextextended(p_operation_id, 0));
  select * into previous_operation from public.sync_operations where operation_id = p_operation_id;
  if found then
    if previous_operation.actor_id is distinct from actor
      or previous_operation.entity_id is distinct from p_round_id
      or previous_operation.operation is distinct from p_operation
      or previous_operation.payload -> 'request' is distinct from request_payload then
      raise exception 'operation_conflict';
    end if;
    if previous_operation.payload -> 'result' is null then raise exception 'client_upgrade_required'; end if;
    return previous_operation.payload -> 'result';
  end if;

  select session.room_id, room.scoring_mode into target_room, mode
  from public.game_sessions session join public.rooms room on room.id = session.room_id
  where session.id = p_session_id and session.status = 'active'
  for update of session;
  if target_room is null or not public.can_input_room(target_room) then
    raise exception 'round_write_forbidden';
  end if;

  if p_operation <> 'create' then
    select * into current_round from public.rounds
    where id = p_round_id and session_id = p_session_id for update;
    if not found then raise exception 'round_not_found'; end if;
    if current_round.created_by <> actor then raise exception 'round_edit_forbidden'; end if;
    if p_expected_version is null then raise exception using errcode = '40001', message = 'version_required'; end if;
    if p_expected_version <> current_round.version then
      raise exception using errcode = '40001', message = 'version_conflict';
    end if;
    if p_operation = 'update' then
      for old_score in select player_id, value from public.score_changes where round_id = p_round_id loop
        if not exists (select 1 from public.room_members
          where room_id = target_room and user_id = old_score.player_id and left_at is null)
          and not exists (select 1 from jsonb_array_elements(changes) entry
            where (entry ->> 'player_id')::uuid = old_score.player_id) then
          changes := changes || jsonb_build_array(jsonb_build_object(
            'player_id', old_score.player_id, 'value', old_score.value));
        end if;
      end loop;
    end if;
  elsif p_expected_version is not null then
    raise exception 'invalid_create_version';
  end if;

  if p_operation <> 'delete' then
    if exists (select 1 from jsonb_array_elements(changes) entry
      group by entry ->> 'player_id' having count(*) > 1) then raise exception 'duplicate_player'; end if;
    select coalesce(sum((entry ->> 'value')::integer), 0) into total
    from jsonb_array_elements(changes) entry;
    if mode = 'money' and total <> 0 then raise exception 'money_round_unbalanced'; end if;
    if not exists (select 1 from jsonb_array_elements(changes) entry
      where (entry ->> 'value')::integer <> 0) then raise exception 'changes_required'; end if;
    for item in select * from jsonb_array_elements(changes) loop
      if item ->> 'player_id' is null or item ->> 'value' is null then raise exception 'changes_required'; end if;
      if not exists (select 1 from public.room_members
        where room_id = target_room and user_id = (item ->> 'player_id')::uuid and left_at is null)
        and not (p_operation = 'update' and exists (select 1 from public.score_changes
          where round_id = p_round_id and player_id = (item ->> 'player_id')::uuid)) then
        raise exception 'player_not_in_room';
      end if;
    end loop;
  end if;

  if p_operation = 'create' then
    select coalesce(max(round_number), 0) + 1 into next_number
    from public.rounds where session_id = p_session_id;
    insert into public.rounds(id, session_id, round_number, created_by, note)
    values (p_round_id, p_session_id, next_number, actor, p_note);
  elsif p_operation = 'delete' then
    update public.rounds set deleted_at = now(), version = version + 1 where id = p_round_id;
  else
    update public.rounds set note = p_note, deleted_at = null, version = version + 1 where id = p_round_id;
  end if;
  if p_operation <> 'delete' then
    delete from public.score_changes where round_id = p_round_id;
    insert into public.score_changes(round_id, player_id, created_by, value)
    select p_round_id, (entry ->> 'player_id')::uuid, actor, (entry ->> 'value')::integer
    from jsonb_array_elements(changes) entry;
  end if;
  select to_jsonb(round) || jsonb_build_object('score_changes',
    coalesce((select jsonb_agg(to_jsonb(score) order by score.player_id)
      from public.score_changes score where score.round_id = round.id), '[]'::jsonb))
    into result_payload from public.rounds round where round.id = p_round_id;
  insert into public.sync_operations(operation_id, actor_id, entity_type, entity_id, operation, payload)
  values (p_operation_id, actor, 'round', p_round_id, p_operation,
    jsonb_build_object('round_id', p_round_id, 'request', request_payload, 'result', result_payload));
  return result_payload;
end;
$$;

-- Do not retain an unversioned update path for older clients.
create or replace function public.upsert_round_with_scores(
  p_round_id uuid, p_session_id uuid, p_round_number integer, p_note text,
  p_changes jsonb, p_operation_id text, p_operation text
)
returns uuid language plpgsql security definer set search_path = public as $$
begin
  raise exception 'client_upgrade_required';
end;
$$;

create or replace function public.get_room_history_page(
  p_limit integer default 20,
  p_before_at timestamptz default null,
  p_before_id uuid default null
)
returns table(room_id uuid, room_name text, game_type text, scoring_mode text,
  is_current_member boolean, session_count bigint, last_activity_at timestamptz)
language sql stable security definer set search_path = public as $$
  with visible as (
    select room.id as room_id, room.name as room_name, room.game_type, room.scoring_mode,
      mine.left_at is null as is_current_member, count(session.id) as session_count,
      max(least(coalesce(session.finished_at, session.started_at, session.created_at),
        coalesce(mine.left_at, 'infinity'::timestamptz))) as last_activity_at
    from public.room_members mine
    join public.rooms room on room.id = mine.room_id
    join public.game_sessions session on session.room_id = room.id
      and (mine.left_at is null or session.created_at <= mine.left_at)
    where mine.user_id = auth.uid() and exists (
      select 1 from public.rounds round where round.session_id = session.id
        and (mine.left_at is null or round.created_at <= mine.left_at))
    group by room.id, room.name, room.game_type, room.scoring_mode, mine.left_at
  )
  select * from visible
  where p_before_at is null or (visible.last_activity_at, visible.room_id) < (p_before_at, p_before_id)
  order by visible.last_activity_at desc, visible.room_id desc
  limit greatest(1, least(coalesce(p_limit, 20), 100));
$$;

create or replace function public.get_room_history_sessions(
  p_room_id uuid,
  p_limit integer default 20,
  p_before_at timestamptz default null,
  p_before_id uuid default null
)
returns table(id uuid, room_id uuid, name text, status text, created_at timestamptz,
  started_at timestamptz, finished_at timestamptz, version bigint,
  round_count bigint, last_activity_at timestamptz)
language sql stable security definer set search_path = public as $$
  with visible as (
    select session.id, session.room_id, session.name, session.status, session.created_at,
      session.started_at, session.finished_at, session.version,
      count(round.id) filter (where round.deleted_at is null) as round_count,
      least(coalesce(session.finished_at, session.started_at, session.created_at),
        coalesce(mine.left_at, 'infinity'::timestamptz)) as last_activity_at
    from public.room_members mine
    join public.game_sessions session on session.room_id = mine.room_id
    join public.rounds round on round.session_id = session.id
      and (mine.left_at is null or round.created_at <= mine.left_at)
    where mine.user_id = auth.uid() and mine.room_id = p_room_id
      and (mine.left_at is null or session.created_at <= mine.left_at)
    group by session.id, mine.left_at
  )
  select * from visible
  where p_before_at is null or (visible.last_activity_at, visible.id) < (p_before_at, p_before_id)
  order by visible.last_activity_at desc, visible.id desc
  limit greatest(1, least(coalesce(p_limit, 20), 100));
$$;

create or replace function public.get_room_history_snapshot(
  p_room_id uuid,
  p_session_id uuid,
  p_limit integer default 500,
  p_after_number integer default null,
  p_after_id uuid default null
)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  membership public.room_members%rowtype;
  session_row public.game_sessions%rowtype;
  room_json jsonb;
  profiles_json jsonb;
  rounds_json jsonb;
  has_more boolean;
  next_number integer;
  next_id uuid;
  page_limit integer := greatest(1, least(coalesce(p_limit, 500), 500));
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  select * into membership from public.room_members where room_id = p_room_id and user_id = auth.uid();
  if not found then raise exception 'room_member_required'; end if;
  select * into session_row from public.game_sessions where id = p_session_id and room_id = p_room_id
    and (membership.left_at is null or created_at <= membership.left_at);
  if not found then raise exception 'room_not_found'; end if;
  select to_jsonb(room) || jsonb_build_object('room_members', coalesce((
    select jsonb_agg(to_jsonb(member) order by member.user_id)
    from public.room_members member where member.room_id = room.id), '[]'::jsonb))
    into room_json from public.rooms room where room.id = p_room_id;
  select coalesce(jsonb_agg(jsonb_build_object('id', profile.id, 'nickname', profile.nickname,
    'avatar_key', profile.avatar_key, 'avatar_url', profile.avatar_url) order by profile.id), '[]'::jsonb)
    into profiles_json from public.profiles profile join public.room_members member on member.user_id = profile.id
    where member.room_id = p_room_id;
  with candidates as (
    select round.* from public.rounds round
    where round.session_id = p_session_id
      and (membership.left_at is null or round.created_at <= membership.left_at)
      and (p_after_number is null or (round.round_number, round.id) > (p_after_number, p_after_id))
    order by round.round_number, round.id limit page_limit + 1
  ), page as (
    select * from candidates order by round_number, id limit page_limit
  )
  select coalesce((select jsonb_agg(to_jsonb(round) || jsonb_build_object('score_changes',
      coalesce((select jsonb_agg(to_jsonb(score) order by score.player_id)
        from public.score_changes score where score.round_id = round.id), '[]'::jsonb))
      order by round.round_number, round.id) from page round), '[]'::jsonb),
    (select count(*) > page_limit from candidates),
    (select round_number from page order by round_number desc, id desc limit 1),
    (select id from page order by round_number desc, id desc limit 1)
    into rounds_json, has_more, next_number, next_id;
  return jsonb_build_object('room', room_json, 'sessions', jsonb_build_array(to_jsonb(session_row)),
    'rounds', rounds_json, 'profiles', profiles_json, 'has_more', has_more,
    'next_number', next_number, 'next_id', next_id);
end;
$$;

-- Acknowledgements are trusted server records, not client-writable payloads.
revoke insert, update, delete on public.sync_operations from authenticated, anon;

create index if not exists history_sessions_room_created on public.game_sessions(room_id, created_at, id);
create index if not exists history_rounds_session_cursor on public.rounds(session_id, round_number, id);

revoke all on function public.upsert_round_with_scores_v2(uuid, uuid, integer, text, jsonb, text, text, bigint, uuid) from public, anon;
revoke all on function public.get_room_history_page(integer, timestamptz, uuid) from public, anon;
revoke all on function public.get_room_history_sessions(uuid, integer, timestamptz, uuid) from public, anon;
revoke all on function public.get_room_history_snapshot(uuid, uuid, integer, integer, uuid) from public, anon;
grant execute on function public.upsert_round_with_scores_v2(uuid, uuid, integer, text, jsonb, text, text, bigint, uuid) to authenticated;
grant execute on function public.get_room_history_page(integer, timestamptz, uuid) to authenticated;
grant execute on function public.get_room_history_sessions(uuid, integer, timestamptz, uuid) to authenticated;
grant execute on function public.get_room_history_snapshot(uuid, uuid, integer, integer, uuid) to authenticated;
