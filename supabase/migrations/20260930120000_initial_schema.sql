create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null check (length(trim(nickname)) between 1 and 40),
  phone text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete restrict,
  name text not null check (length(trim(name)) between 1 and 80),
  game_type text not null check (length(trim(game_type)) between 1 and 40),
  scoring_mode text not null check (scoring_mode in ('points', 'money')),
  status text not null default 'waiting' check (status in ('waiting', 'active', 'finished', 'archived', 'dissolved')),
  input_permission text not null default 'all' check (input_permission in ('all', 'ownerOnly')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1
);

create table if not exists public.room_members (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  input_permission text not null default 'all' check (input_permission in ('all', 'ownerOnly')),
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table if not exists public.invite_tokens (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  token_hash text not null unique,
  invite_code text unique,
  kind text not null check (kind in ('qr', 'link', 'code')),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz
);

create table if not exists public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 80),
  status text not null default 'draft' check (status in ('draft', 'active', 'finished')),
  created_at timestamptz not null default now(),
  started_at timestamptz,
  finished_at timestamptz,
  updated_at timestamptz not null default now(),
  version bigint not null default 1
);

create table if not exists public.rounds (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.game_sessions(id) on delete cascade,
  round_number integer not null check (round_number > 0),
  created_by uuid not null references public.profiles(id) on delete restrict,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null default 1,
  unique (session_id, round_number)
);

create table if not exists public.score_changes (
  id uuid primary key default gen_random_uuid(),
  round_id uuid not null references public.rounds(id) on delete cascade,
  player_id uuid not null references public.profiles(id) on delete restrict,
  created_by uuid not null references public.profiles(id) on delete restrict,
  value integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sync_operations (
  operation_id text primary key,
  actor_id uuid not null references public.profiles(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  operation text not null check (operation in ('create', 'update', 'delete')),
  payload jsonb not null,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
drop trigger if exists rooms_set_updated_at on public.rooms;
create trigger rooms_set_updated_at before update on public.rooms
for each row execute function public.set_updated_at();
drop trigger if exists room_members_set_updated_at on public.room_members;
create trigger room_members_set_updated_at before update on public.room_members
for each row execute function public.set_updated_at();
drop trigger if exists game_sessions_set_updated_at on public.game_sessions;
create trigger game_sessions_set_updated_at before update on public.game_sessions
for each row execute function public.set_updated_at();
drop trigger if exists rounds_set_updated_at on public.rounds;
create trigger rounds_set_updated_at before update on public.rounds
for each row execute function public.set_updated_at();
drop trigger if exists score_changes_set_updated_at on public.score_changes;
create trigger score_changes_set_updated_at before update on public.score_changes
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  nickname text;
begin
  nickname := left(
    nullif(trim(new.raw_user_meta_data ->> 'nickname'), ''),
    40
  );
  if nickname is null then
    nickname := left(
      coalesce(
        nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
        nullif(new.phone, ''),
        '牌友'
      ),
      40
    );
  end if;
  insert into public.profiles (id, nickname, phone, email)
  values (new.id, nickname, new.phone, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.is_room_member(target_room_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.room_members
    where room_id = target_room_id
      and auth.uid() is not null
      and user_id = auth.uid()
      and left_at is null
  );
$$;

create or replace function public.is_room_owner(target_room_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.rooms
    where id = target_room_id and auth.uid() is not null and owner_id = auth.uid()
  );
$$;

create or replace function public.can_input_room(target_room_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.rooms
    where id = target_room_id
      and (
        input_permission = 'all'
        or owner_id = auth.uid()
      )
      and public.is_room_member(id)
  );
$$;

create or replace function public.create_room(
  p_name text,
  p_game_type text,
  p_scoring_mode text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  created_room_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if p_scoring_mode not in ('points', 'money') then
    raise exception 'invalid_scoring_mode';
  end if;
  if not exists (select 1 from public.profiles where id = auth.uid()) then
    raise exception 'profile_required';
  end if;
  insert into public.rooms (owner_id, name, game_type, scoring_mode)
  values (auth.uid(), trim(p_name), trim(p_game_type), p_scoring_mode)
  returning id into created_room_id;
  insert into public.room_members (room_id, user_id, role)
  values (created_room_id, auth.uid(), 'owner');
  return created_room_id;
end;
$$;

create or replace function public.join_room_by_invite(p_token_hash text)
returns uuid
language plpgsql security definer set search_path = public
as $$
 declare target_room_id uuid;
begin
   if auth.uid() is null then
     raise exception 'not_authenticated';
   end if;
   select room_id into target_room_id
   from public.invite_tokens
   where token_hash = p_token_hash
     and revoked_at is null
     and (expires_at is null or expires_at > now());
   if target_room_id is null then
     raise exception 'invite_invalid';
   end if;
   if exists (
     select 1 from public.rooms
     where id = target_room_id and status in ('archived', 'dissolved')
   ) then
     raise exception 'room_closed';
   end if;
   insert into public.room_members (room_id, user_id)
   values (target_room_id, auth.uid())
   on conflict (room_id, user_id) do update set left_at = null, updated_at = now();
   return target_room_id;
 end;
$$;

create or replace function public.join_room_by_invite_code(p_invite_code text)
returns uuid
language plpgsql security definer set search_path = public
as $$
 declare target_room_id uuid;
begin
   if auth.uid() is null then
     raise exception 'not_authenticated';
   end if;
   select room_id into target_room_id
   from public.invite_tokens
   where invite_code = upper(trim(p_invite_code))
     and revoked_at is null
     and (expires_at is null or expires_at > now());
   if target_room_id is null then
     raise exception 'invite_invalid';
   end if;
   if exists (
     select 1 from public.rooms
     where id = target_room_id and status in ('archived', 'dissolved')
   ) then
     raise exception 'room_closed';
   end if;
   insert into public.room_members (room_id, user_id)
   values (target_room_id, auth.uid())
   on conflict (room_id, user_id) do update set left_at = null, updated_at = now();
   return target_room_id;
end;
$$;

create or replace function public.leave_room(target_room_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if public.is_room_owner(target_room_id) then
    raise exception 'owner_cannot_leave';
  end if;
  update public.room_members
  set left_at = now()
  where room_id = target_room_id
    and user_id = auth.uid()
    and left_at is null;
end;
$$;

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.invite_tokens enable row level security;
alter table public.game_sessions enable row level security;
alter table public.rounds enable row level security;
alter table public.score_changes enable row level security;
alter table public.sync_operations enable row level security;

drop policy if exists profiles_select_member on public.profiles;
create policy profiles_select_member on public.profiles for select to authenticated
using (
  id = auth.uid() or exists (
    select 1 from public.room_members mine
    join public.room_members target on target.room_id = mine.room_id
    where mine.user_id = auth.uid() and mine.left_at is null
      and target.user_id = profiles.id and target.left_at is null
  )
);
drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists rooms_select_member on public.rooms;
create policy rooms_select_member on public.rooms for select to authenticated using (public.is_room_member(id));
drop policy if exists rooms_insert_owner on public.rooms;
create policy rooms_insert_owner on public.rooms for insert to authenticated with check (owner_id = auth.uid());
drop policy if exists rooms_update_owner on public.rooms;
create policy rooms_update_owner on public.rooms for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists room_members_select_member on public.room_members;
create policy room_members_select_member on public.room_members for select to authenticated using (public.is_room_member(room_id));
drop policy if exists room_members_insert_self_or_owner on public.room_members;
create policy room_members_insert_self_or_owner on public.room_members for insert to authenticated with check (public.is_room_owner(room_id));
drop policy if exists room_members_update_self_or_owner on public.room_members;
create policy room_members_update_self_or_owner on public.room_members for update to authenticated using (public.is_room_owner(room_id)) with check (public.is_room_owner(room_id));

drop policy if exists invites_owner_all on public.invite_tokens;
create policy invites_owner_all on public.invite_tokens for all to authenticated using (public.is_room_owner(room_id)) with check (public.is_room_owner(room_id));
drop policy if exists sessions_member_select on public.game_sessions;
create policy sessions_member_select on public.game_sessions for select to authenticated using (public.is_room_member(room_id));
drop policy if exists sessions_owner_write on public.game_sessions;
create policy sessions_owner_write on public.game_sessions for all to authenticated using (public.is_room_owner(room_id)) with check (public.is_room_owner(room_id));
drop policy if exists rounds_member_select on public.rounds;
create policy rounds_member_select on public.rounds for select to authenticated using (
  exists (select 1 from public.game_sessions s where s.id = session_id and public.is_room_member(s.room_id))
);
drop policy if exists rounds_member_insert on public.rounds;
create policy rounds_member_insert on public.rounds for insert to authenticated with check (
  created_by = auth.uid() and exists (select 1 from public.game_sessions s where s.id = session_id and public.can_input_room(s.room_id))
);
drop policy if exists rounds_member_update on public.rounds;
create policy rounds_member_update on public.rounds for update to authenticated using (
  created_by = auth.uid() and exists (
    select 1 from public.game_sessions s
    where s.id = session_id and public.can_input_room(s.room_id)
  )
) with check (
  created_by = auth.uid() and exists (
    select 1 from public.game_sessions s
    where s.id = session_id and public.can_input_room(s.room_id)
  )
);
drop policy if exists rounds_member_delete on public.rounds;
create policy rounds_member_delete on public.rounds for delete to authenticated using (
  created_by = auth.uid() and exists (
    select 1 from public.game_sessions s
    where s.id = session_id and public.can_input_room(s.room_id)
  )
);
drop policy if exists score_changes_member_select on public.score_changes;
create policy score_changes_member_select on public.score_changes for select to authenticated using (
  exists (
    select 1 from public.rounds r join public.game_sessions s on s.id = r.session_id
    where r.id = round_id and public.is_room_member(s.room_id)
  )
);
drop policy if exists score_changes_member_insert on public.score_changes;
create policy score_changes_member_insert on public.score_changes for insert to authenticated with check (
  created_by = auth.uid() and exists (
    select 1 from public.rounds r join public.game_sessions s on s.id = r.session_id
    join public.room_members player on player.room_id = s.room_id and player.user_id = score_changes.player_id
    where r.id = round_id and public.can_input_room(s.room_id) and player.left_at is null
  )
);
drop policy if exists score_changes_member_update on public.score_changes;
create policy score_changes_member_update on public.score_changes for update to authenticated using (
  created_by = auth.uid() and exists (
    select 1
    from public.rounds r
    join public.game_sessions s on s.id = r.session_id
    join public.room_members player on player.room_id = s.room_id and player.user_id = score_changes.player_id
    where r.id = round_id and public.can_input_room(s.room_id) and player.left_at is null
  )
) with check (
  created_by = auth.uid() and exists (
    select 1
    from public.rounds r
    join public.game_sessions s on s.id = r.session_id
    join public.room_members player on player.room_id = s.room_id and player.user_id = score_changes.player_id
    where r.id = round_id and public.can_input_room(s.room_id) and player.left_at is null
  )
);
drop policy if exists score_changes_member_delete on public.score_changes;
create policy score_changes_member_delete on public.score_changes for delete to authenticated using (
  created_by = auth.uid() and exists (
    select 1
    from public.rounds r
    join public.game_sessions s on s.id = r.session_id
    join public.room_members player on player.room_id = s.room_id and player.user_id = score_changes.player_id
    where r.id = round_id and public.can_input_room(s.room_id) and player.left_at is null
  )
);
drop policy if exists sync_operations_self on public.sync_operations;
create policy sync_operations_self on public.sync_operations for all to authenticated using (actor_id = auth.uid()) with check (
  actor_id = auth.uid()
);

revoke all on function public.create_room(text, text, text) from public;
grant execute on function public.create_room(text, text, text) to authenticated;
revoke all on function public.leave_room(uuid) from public;
grant execute on function public.leave_room(uuid) to authenticated;
revoke all on function public.join_room_by_invite(text) from public;
grant execute on function public.join_room_by_invite(text) to authenticated;
revoke all on function public.join_room_by_invite_code(text) from public;
grant execute on function public.join_room_by_invite_code(text) to authenticated;

create index if not exists room_members_user_idx on public.room_members(user_id) where left_at is null;
create index if not exists game_sessions_room_idx on public.game_sessions(room_id, updated_at desc);
create index if not exists rounds_session_idx on public.rounds(session_id, round_number);
create index if not exists score_changes_round_idx on public.score_changes(round_id);

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'rooms'
  ) then alter publication supabase_realtime add table public.rooms; end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'room_members'
  ) then alter publication supabase_realtime add table public.room_members; end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'game_sessions'
  ) then alter publication supabase_realtime add table public.game_sessions; end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'rounds'
  ) then alter publication supabase_realtime add table public.rounds; end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'score_changes'
  ) then alter publication supabase_realtime add table public.score_changes; end if;
end;
$$;
