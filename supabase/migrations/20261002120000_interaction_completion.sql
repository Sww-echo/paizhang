alter table public.profiles add column if not exists avatar_key text;
alter table public.profiles add column if not exists avatar_url text;

create table public.room_close_proposals (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id),
  created_by uuid not null references public.profiles(id),
  target_status text not null check (target_status in ('archived', 'dissolved')),
  status text not null default 'pending' check (status in ('pending', 'passed', 'cancelled')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours'
);
create unique index if not exists room_close_pending_idx on public.room_close_proposals(room_id) where status = 'pending';
create table public.room_close_votes (
  proposal_id uuid not null references public.room_close_proposals(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  approved boolean,
  updated_at timestamptz not null default now(),
  primary key (proposal_id, user_id)
);
alter table public.room_close_proposals enable row level security;
alter table public.room_close_votes enable row level security;
create policy close_proposals_read on public.room_close_proposals for select to authenticated
using (public.is_room_member(room_id));
create policy close_votes_read on public.room_close_votes for select to authenticated
using (exists (select 1 from public.room_close_proposals proposal where proposal.id = proposal_id and public.is_room_member(proposal.room_id)));
grant select on public.room_close_proposals, public.room_close_votes to authenticated;
revoke insert, update, delete on public.room_close_proposals, public.room_close_votes from authenticated, anon;

create function public.cast_room_close_vote(target_room_id uuid, p_approved boolean, p_target_status text default 'archived', p_proposal_id uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  target_room public.rooms;
  proposal public.room_close_proposals;
  approved_count integer;
  member_count integer;
begin
  select * into target_room from public.rooms where id = target_room_id for update;
  if auth.uid() is null or not public.is_room_member(target_room_id) then raise exception 'room_member_required'; end if;
  if target_room.status in ('archived', 'dissolved') then raise exception 'room_closed'; end if;
  if p_approved is null or p_target_status not in ('archived', 'dissolved') then raise exception 'invalid_vote'; end if;
  if exists (select 1 from public.game_sessions where room_id = target_room_id and status = 'active') then raise exception 'active_session_exists'; end if;
  update public.room_close_proposals set status = 'cancelled' where room_id = target_room_id and status = 'pending' and expires_at <= now();
  select * into proposal from public.room_close_proposals where room_id = target_room_id and status = 'pending';
  if p_proposal_id is not null and (proposal.id is null or proposal.id <> p_proposal_id) then raise exception 'vote_expired'; end if;
  if proposal.id is null then
    if not p_approved then raise exception 'vote_not_started'; end if;
    insert into public.room_close_proposals(room_id, created_by, target_status) values (target_room_id, auth.uid(), p_target_status) returning * into proposal;
    insert into public.room_close_votes(proposal_id, user_id) select proposal.id, user_id from public.room_members where room_id = target_room_id and left_at is null;
  elsif proposal.target_status <> p_target_status then
    raise exception 'another_close_vote_pending';
  end if;
  update public.room_close_votes set approved = p_approved, updated_at = now() where proposal_id = proposal.id and user_id = auth.uid();
  if not found then raise exception 'vote_expired'; end if;
  select count(*), count(*) filter (where approved) into member_count, approved_count from public.room_close_votes where proposal_id = proposal.id;
  if approved_count * 2 > member_count then
    update public.room_close_proposals set status = 'passed' where id = proposal.id;
    update public.rooms set status = proposal.target_status, version = version + 1 where id = target_room_id;
  end if;
  return proposal.id;
end;
$$;

create function public.cancel_room_close_vote(target_room_id uuid, p_proposal_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform 1 from public.rooms where id = target_room_id for update;
  if not public.is_room_member(target_room_id) then raise exception 'room_member_required'; end if;
  update public.room_close_proposals set status = 'cancelled'
  where id = p_proposal_id and room_id = target_room_id and status = 'pending'
    and (created_by = auth.uid() or public.is_room_owner(target_room_id));
  if not found then raise exception 'vote_cancel_forbidden'; end if;
end;
$$;

create function public.invalidate_room_close_vote()
returns trigger language plpgsql security definer set search_path = public as $$
declare target_room_id uuid;
begin
  target_room_id := coalesce(new.room_id, old.room_id);
  perform 1 from public.rooms where id = target_room_id for update;
  update public.room_close_proposals set status = 'cancelled' where room_id = target_room_id and status = 'pending';
  return coalesce(new, old);
end;
$$;
drop trigger if exists member_changed_cancel_vote on public.room_members;
create trigger member_changed_cancel_vote after insert or delete or update of left_at on public.room_members for each row execute function public.invalidate_room_close_vote();

create function public.manage_game_session(p_session_id uuid, p_action text, p_name text default null, p_expected_version bigint default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare session public.game_sessions; target_room public.rooms;
begin
  select * into session from public.game_sessions where id = p_session_id;
  if session.id is null then raise exception 'session_not_found'; end if;
  select * into target_room from public.rooms where id = session.room_id for update;
  if not public.is_room_owner(target_room.id) then raise exception 'room_owner_required'; end if;
  if target_room.status in ('archived', 'dissolved') then raise exception 'room_closed'; end if;
  select * into session from public.game_sessions where id = p_session_id for update;
  if p_expected_version is not null and session.version <> p_expected_version then raise exception 'version_conflict'; end if;
  if p_action = 'rename' then
    if length(trim(p_name)) not between 1 and 80 or p_name is null then raise exception 'invalid_session_name'; end if;
    if session.status = 'finished' then raise exception 'session_finished'; end if;
    update public.game_sessions set name = trim(p_name), version = version + 1 where id = p_session_id;
  elsif p_action = 'delete' then
    if session.status <> 'draft' then raise exception 'only_draft_can_delete'; end if;
    delete from public.game_sessions where id = p_session_id;
  elsif p_action = 'start' or p_action = 'reopen' then
    if (p_action = 'start' and session.status <> 'draft') or (p_action = 'reopen' and session.status <> 'finished') then raise exception 'invalid_session_transition'; end if;
    update public.room_close_proposals set status = 'cancelled' where room_id = target_room.id and status = 'pending';
    update public.game_sessions set status = 'active', started_at = coalesce(started_at, now()), finished_at = null, version = version + 1 where id = p_session_id;
  elsif p_action = 'finish' then
    if session.status <> 'active' then raise exception 'invalid_session_transition'; end if;
    update public.game_sessions set status = 'finished', finished_at = now(), version = version + 1 where id = p_session_id;
  else raise exception 'invalid_session_action';
  end if;
  return p_session_id;
end;
$$;

create function public.create_game_draft(target_room_id uuid, p_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare session_id uuid;
begin
  perform 1 from public.rooms where id = target_room_id for update;
  if not public.is_room_owner(target_room_id) then raise exception 'room_owner_required'; end if;
  if exists (select 1 from public.rooms where id = target_room_id and status in ('archived', 'dissolved')) then raise exception 'room_closed'; end if;
  if p_name is null or length(trim(p_name)) not between 1 and 80 then raise exception 'invalid_session_name'; end if;
  insert into public.game_sessions(room_id, name) values (target_room_id, trim(p_name)) returning id into session_id;
  return session_id;
end;
$$;

create function public.update_room_details(target_room_id uuid, p_name text, p_game_type text, p_scoring_mode text, p_expected_version bigint)
returns void language plpgsql security definer set search_path = public as $$
declare target_room public.rooms;
begin
  select * into target_room from public.rooms where id = target_room_id for update;
  if not public.is_room_owner(target_room_id) then raise exception 'room_owner_required'; end if;
  if target_room.status in ('archived', 'dissolved') then raise exception 'room_closed'; end if;
  if target_room.version <> p_expected_version then raise exception 'version_conflict'; end if;
  if p_name is null or length(trim(p_name)) not between 1 and 80 or p_game_type is null or length(trim(p_game_type)) not between 1 and 40 or p_scoring_mode not in ('points', 'money') or p_scoring_mode is null then raise exception 'invalid_room_details'; end if;
  if p_scoring_mode <> target_room.scoring_mode and exists (select 1 from public.rounds round join public.game_sessions session on session.id = round.session_id where session.room_id = target_room_id) then raise exception 'scoring_mode_locked'; end if;
  update public.rooms set name = trim(p_name), game_type = trim(p_game_type), scoring_mode = p_scoring_mode, version = version + 1 where id = target_room_id;
end;
$$;

create function public.guard_closed_room_changes()
returns trigger language plpgsql set search_path = public as $$
begin
  if old.status in ('archived', 'dissolved') then raise exception 'room_closed'; end if;
  return new;
end;
$$;
drop trigger if exists closed_room_guard on public.rooms;
create trigger closed_room_guard before update on public.rooms for each row execute function public.guard_closed_room_changes();

create or replace function public.can_input_room(target_room_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_room_member(target_room_id) and exists (
    select 1 from public.rooms where id = target_room_id and status not in ('archived', 'dissolved')
      and (input_permission = 'all' or owner_id = auth.uid())
  );
$$;

create function public.get_my_room_history()
returns table(room jsonb, sessions jsonb, rounds jsonb, profiles jsonb)
language sql stable security definer set search_path = public as $$
  select
    to_jsonb(target_room) || jsonb_build_object('room_members', coalesce((select jsonb_agg(to_jsonb(member)) from public.room_members member where member.room_id = target_room.id), '[]'::jsonb)),
    coalesce((select jsonb_agg(to_jsonb(session)) from public.game_sessions session where session.room_id = target_room.id and (mine.left_at is null or session.created_at <= mine.left_at)), '[]'::jsonb),
    coalesce((select jsonb_agg(to_jsonb(round) || jsonb_build_object('score_changes', coalesce((select jsonb_agg(to_jsonb(change)) from public.score_changes change where change.round_id = round.id), '[]'::jsonb))) from public.rounds round join public.game_sessions session on session.id = round.session_id where session.room_id = target_room.id and (mine.left_at is null or round.created_at <= mine.left_at)), '[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('id', profile.id, 'nickname', profile.nickname, 'avatar_key', profile.avatar_key, 'avatar_url', profile.avatar_url)) from public.profiles profile join public.room_members member on member.user_id = profile.id where member.room_id = target_room.id), '[]'::jsonb)
  from public.room_members mine join public.rooms target_room on target_room.id = mine.room_id
  where mine.user_id = auth.uid();
$$;

drop policy profiles_select_member on public.profiles;
create policy profiles_select_member on public.profiles for select to authenticated using (
  id = auth.uid() or exists (select 1 from public.room_members mine join public.room_members target on target.room_id = mine.room_id where mine.user_id = auth.uid() and mine.left_at is null and target.user_id = profiles.id)
);

revoke insert, update, delete on public.game_sessions, public.rooms, public.rounds, public.score_changes from authenticated, anon;
revoke all on function public.cast_room_close_vote(uuid, boolean, text, uuid), public.cancel_room_close_vote(uuid, uuid), public.manage_game_session(uuid, text, text, bigint), public.create_game_draft(uuid, text), public.update_room_details(uuid, text, text, text, bigint), public.get_my_room_history(), public.invalidate_room_close_vote(), public.guard_closed_room_changes() from public, anon;
grant execute on function public.cast_room_close_vote(uuid, boolean, text, uuid), public.cancel_room_close_vote(uuid, uuid), public.manage_game_session(uuid, text, text, bigint), public.create_game_draft(uuid, text), public.update_room_details(uuid, text, text, text, bigint), public.get_my_room_history() to authenticated;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;
create policy avatar_insert_self on storage.objects for insert to authenticated with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatar_update_self on storage.objects for update to authenticated using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text) with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatar_delete_self on storage.objects for delete to authenticated using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatar_read_self on storage.objects for select to authenticated using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

do $$
declare
  target_table text;
begin
  foreach target_table in array array[
    'room_close_proposals',
    'room_close_votes',
    'profiles'
  ] loop
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = target_table
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        target_table
      );
    end if;
  end loop;
end;
$$;
