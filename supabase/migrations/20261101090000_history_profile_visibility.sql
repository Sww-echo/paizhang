-- Historical viewers should not receive member profiles that became visible
-- after they left the room. Current members retain the full current directory.
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
  select * into membership
  from public.room_members
  where room_id = p_room_id and user_id = auth.uid();
  if not found then raise exception 'room_member_required'; end if;

  select * into session_row
  from public.game_sessions
  where id = p_session_id and room_id = p_room_id
    and (membership.left_at is null or created_at <= membership.left_at);
  if not found then raise exception 'room_not_found'; end if;

  select to_jsonb(room) || jsonb_build_object('room_members', coalesce((
    select jsonb_agg(to_jsonb(member) order by member.user_id)
    from public.room_members member
    where member.room_id = room.id
      and (
        membership.left_at is null
        or member.joined_at <= membership.left_at
      )
  ), '[]'::jsonb))
  into room_json
  from public.rooms room
  where room.id = p_room_id;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', profile.id,
    'nickname', profile.nickname,
    'avatar_key', profile.avatar_key,
    'avatar_url', profile.avatar_url
  ) order by profile.id), '[]'::jsonb)
  into profiles_json
  from public.profiles profile
  join public.room_members member on member.user_id = profile.id
  where member.room_id = p_room_id
    and (
      membership.left_at is null
      or member.joined_at <= membership.left_at
    );

  with candidates as (
    select round.*
    from public.rounds round
    where round.session_id = p_session_id
      and (
        membership.left_at is null
        or round.created_at <= membership.left_at
      )
      and (
        p_after_number is null
        or (round.round_number, round.id) > (p_after_number, p_after_id)
      )
    order by round.round_number, round.id
    limit page_limit + 1
  ), page as (
    select * from candidates order by round_number, id limit page_limit
  )
  select coalesce((
    select jsonb_agg(
      to_jsonb(round) || jsonb_build_object('score_changes', coalesce((
        select jsonb_agg(to_jsonb(score) order by score.player_id)
        from public.score_changes score
        where score.round_id = round.id
      ), '[]'::jsonb))
      order by round.round_number, round.id
    )
    from page round
  ), '[]'::jsonb),
  (select count(*) > page_limit from candidates),
  (select round_number from page order by round_number desc, id desc limit 1),
  (select id from page order by round_number desc, id desc limit 1)
  into rounds_json, has_more, next_number, next_id;

  return jsonb_build_object(
    'room', room_json,
    'sessions', jsonb_build_array(to_jsonb(session_row)),
    'rounds', rounds_json,
    'profiles', profiles_json,
    'has_more', has_more,
    'next_number', next_number,
    'next_id', next_id
  );
end;
$$;

revoke all on function public.get_room_history_snapshot(uuid, uuid, integer, integer, uuid)
  from public, anon;
grant execute on function public.get_room_history_snapshot(uuid, uuid, integer, integer, uuid)
  to authenticated;
