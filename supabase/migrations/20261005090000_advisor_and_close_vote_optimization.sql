create or replace function public.cast_room_close_vote(
  target_room_id uuid,
  p_approved boolean,
  p_target_status text default 'archived',
  p_proposal_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_room public.rooms;
  proposal public.room_close_proposals;
  approved_count integer;
  member_count integer;
begin
  select * into target_room from public.rooms where id = target_room_id for update;
  if auth.uid() is null or not public.is_room_member(target_room_id) then
    raise exception 'room_member_required';
  end if;
  if target_room.status in ('archived', 'dissolved') then
    raise exception 'room_closed';
  end if;
  if p_approved is null or p_target_status not in ('archived', 'dissolved') then
    raise exception 'invalid_vote';
  end if;
  if exists (
    select 1 from public.game_sessions
    where room_id = target_room_id and status = 'active'
  ) then
    raise exception 'active_session_exists';
  end if;
  update public.room_close_proposals
  set status = 'cancelled'
  where room_id = target_room_id
    and status = 'pending'
    and expires_at <= now();
  select * into proposal
  from public.room_close_proposals
  where room_id = target_room_id and status = 'pending';
  if p_proposal_id is not null
     and (proposal.id is null or proposal.id <> p_proposal_id) then
    raise exception 'vote_expired';
  end if;
  if proposal.id is null then
    if not p_approved then raise exception 'vote_not_started'; end if;
    insert into public.room_close_proposals(room_id, created_by, target_status)
    values (target_room_id, auth.uid(), p_target_status)
    returning * into proposal;
    insert into public.room_close_votes(proposal_id, user_id)
    select proposal.id, user_id
    from public.room_members
    where room_id = target_room_id and left_at is null;
  elsif proposal.target_status <> p_target_status then
    raise exception 'another_close_vote_pending';
  end if;
  update public.room_close_votes
  set approved = p_approved, updated_at = now()
  where proposal_id = proposal.id and user_id = auth.uid();
  if not found then raise exception 'vote_expired'; end if;
  select count(*), count(*) filter (where approved)
  into member_count, approved_count
  from public.room_close_votes
  where proposal_id = proposal.id;
  if approved_count * 2 >= member_count then
    update public.room_close_proposals
    set status = 'passed'
    where id = proposal.id;
    update public.rooms
    set status = proposal.target_status, version = version + 1
    where id = target_room_id;
  end if;
  return proposal.id;
end;
$$;

drop policy if exists profiles_select_member on public.profiles;
create policy profiles_select_member on public.profiles
for select to authenticated
using (
  id = (select auth.uid()) or exists (
    select 1
    from public.room_members mine
    join public.room_members target on target.room_id = mine.room_id
    where mine.user_id = (select auth.uid())
      and mine.left_at is null
      and target.user_id = profiles.id
      and target.left_at is null
  )
);

drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
for insert to authenticated
with check (id = (select auth.uid()));

drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

drop policy if exists rooms_insert_owner on public.rooms;
create policy rooms_insert_owner on public.rooms
for insert to authenticated
with check (owner_id = (select auth.uid()));

drop policy if exists rooms_update_owner on public.rooms;
create policy rooms_update_owner on public.rooms
for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

drop policy if exists rounds_member_insert on public.rounds;
create policy rounds_member_insert on public.rounds
for insert to authenticated
with check (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.game_sessions s
    where s.id = session_id and public.can_input_room(s.room_id)
  )
);

drop policy if exists rounds_member_update on public.rounds;
create policy rounds_member_update on public.rounds
for update to authenticated
using (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.game_sessions s
    where s.id = session_id and public.can_input_room(s.room_id)
  )
)
with check (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.game_sessions s
    where s.id = session_id and public.can_input_room(s.room_id)
  )
);

drop policy if exists rounds_member_delete on public.rounds;
create policy rounds_member_delete on public.rounds
for delete to authenticated
using (
  created_by = (select auth.uid())
  and exists (
    select 1 from public.game_sessions s
    where s.id = session_id and public.can_input_room(s.room_id)
  )
);

drop policy if exists score_changes_member_insert on public.score_changes;
create policy score_changes_member_insert on public.score_changes
for insert to authenticated
with check (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.rounds r
    join public.game_sessions s on s.id = r.session_id
    join public.room_members player
      on player.room_id = s.room_id and player.user_id = score_changes.player_id
    where r.id = round_id
      and public.can_input_room(s.room_id)
      and player.left_at is null
  )
);

drop policy if exists score_changes_member_update on public.score_changes;
create policy score_changes_member_update on public.score_changes
for update to authenticated
using (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.rounds r
    join public.game_sessions s on s.id = r.session_id
    join public.room_members player
      on player.room_id = s.room_id and player.user_id = score_changes.player_id
    where r.id = round_id
      and public.can_input_room(s.room_id)
      and player.left_at is null
  )
)
with check (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.rounds r
    join public.game_sessions s on s.id = r.session_id
    join public.room_members player
      on player.room_id = s.room_id and player.user_id = score_changes.player_id
    where r.id = round_id
      and public.can_input_room(s.room_id)
      and player.left_at is null
  )
);

drop policy if exists score_changes_member_delete on public.score_changes;
create policy score_changes_member_delete on public.score_changes
for delete to authenticated
using (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.rounds r
    join public.game_sessions s on s.id = r.session_id
    join public.room_members player
      on player.room_id = s.room_id and player.user_id = score_changes.player_id
    where r.id = round_id
      and public.can_input_room(s.room_id)
      and player.left_at is null
  )
);

drop policy if exists sync_operations_self on public.sync_operations;
create policy sync_operations_self on public.sync_operations
for all to authenticated
using (actor_id = (select auth.uid()))
with check (actor_id = (select auth.uid()));

create index if not exists room_close_proposals_created_by_idx
on public.room_close_proposals(created_by);

create index if not exists room_close_votes_user_id_idx
on public.room_close_votes(user_id);

revoke all on function public.cast_room_close_vote(uuid, boolean, text, uuid)
from public, anon;
grant execute on function public.cast_room_close_vote(uuid, boolean, text, uuid)
to authenticated;
