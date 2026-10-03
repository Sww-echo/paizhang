create or replace function public.assert_room_open(target_room_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  room_status text;
begin
  select status
    into room_status
  from public.rooms
  where id = target_room_id;

  if room_status is null then
    raise exception 'room_not_found';
  end if;
  if room_status in ('archived', 'dissolved') then
    raise exception 'room_closed';
  end if;
end;
$$;

create or replace function public.set_room_input_permission(
  target_room_id uuid,
  p_input_permission text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if p_input_permission not in ('all', 'ownerOnly') then
    raise exception 'invalid_input_permission';
  end if;
  if not public.is_room_owner(target_room_id) then
    raise exception 'room_owner_required';
  end if;
  perform public.assert_room_open(target_room_id);
  update public.rooms
  set input_permission = p_input_permission,
      version = version + 1
  where id = target_room_id;
end;
$$;

create or replace function public.remove_room_member(
  target_room_id uuid,
  target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if not public.is_room_owner(target_room_id) then
    raise exception 'room_owner_required';
  end if;
  perform public.assert_room_open(target_room_id);
  if exists (
    select 1
    from public.rooms
    where id = target_room_id and owner_id = target_user_id
  ) then
    raise exception 'owner_cannot_be_removed';
  end if;
  update public.room_members
  set left_at = now(), updated_at = now()
  where room_id = target_room_id
    and user_id = target_user_id
    and left_at is null;
  if not found then
    raise exception 'member_not_found';
  end if;
end;
$$;

create or replace function public.transfer_room_ownership(
  target_room_id uuid,
  new_owner_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_owner_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  perform public.assert_room_open(target_room_id);
  select owner_id
    into current_owner_id
  from public.rooms
  where id = target_room_id;
  if current_owner_id is null or current_owner_id <> auth.uid() then
    raise exception 'room_owner_required';
  end if;
  if not exists (
    select 1
    from public.room_members
    where room_id = target_room_id
      and user_id = new_owner_id
      and left_at is null
  ) then
    raise exception 'member_not_found';
  end if;
  if new_owner_id = current_owner_id then
    return;
  end if;
  update public.room_members
  set role = 'member', updated_at = now()
  where room_id = target_room_id and user_id = current_owner_id;
  update public.room_members
  set role = 'owner', left_at = null, updated_at = now()
  where room_id = target_room_id and user_id = new_owner_id;
  update public.rooms
  set owner_id = new_owner_id,
      version = version + 1
  where id = target_room_id;
end;
$$;

create or replace function public.revoke_room_invite(
  target_invite_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_room_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  select room_id
    into target_room_id
  from public.invite_tokens
  where id = target_invite_id and revoked_at is null;
  if target_room_id is null then
    raise exception 'invite_not_found';
  end if;
  if not public.is_room_owner(target_room_id) then
    raise exception 'room_owner_required';
  end if;
  perform public.assert_room_open(target_room_id);
  update public.invite_tokens
  set revoked_at = now()
  where id = target_invite_id;
end;
$$;

create or replace function public.refresh_room_invite(
  target_invite_id uuid,
  p_token_hash text,
  p_invite_code text,
  p_kind text,
  p_expires_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_room_id uuid;
  refreshed_invite_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;
  if p_kind not in ('qr', 'link', 'code') then
    raise exception 'invalid_invite_kind';
  end if;
  select room_id
    into target_room_id
  from public.invite_tokens
  where id = target_invite_id and revoked_at is null;
  if target_room_id is null then
    raise exception 'invite_not_found';
  end if;
  if not public.is_room_owner(target_room_id) then
    raise exception 'room_owner_required';
  end if;
  perform public.assert_room_open(target_room_id);
  update public.invite_tokens
  set revoked_at = now()
  where id = target_invite_id;
  insert into public.invite_tokens (
    room_id,
    token_hash,
    invite_code,
    kind,
    expires_at
  ) values (
    target_room_id,
    p_token_hash,
    p_invite_code,
    p_kind,
    p_expires_at
  ) returning id into refreshed_invite_id;
  return refreshed_invite_id;
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
  perform public.assert_room_open(target_room_id);
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

drop policy if exists room_members_insert_self_or_owner on public.room_members;
create policy room_members_insert_self_or_owner on public.room_members
for insert to authenticated
with check (
  public.is_room_owner(room_id)
  and exists (
    select 1
    from public.rooms
    where id = room_id and status not in ('archived', 'dissolved')
  )
);

drop policy if exists room_members_update_self_or_owner on public.room_members;
create policy room_members_update_self_or_owner on public.room_members
for update to authenticated
using (
  public.is_room_owner(room_id)
  and exists (
    select 1
    from public.rooms
    where id = room_id and status not in ('archived', 'dissolved')
  )
)
with check (
  public.is_room_owner(room_id)
  and exists (
    select 1
    from public.rooms
    where id = room_id and status not in ('archived', 'dissolved')
  )
);

revoke insert, update, delete on public.room_members from authenticated, anon;
revoke update, delete on public.invite_tokens from authenticated, anon;

drop policy if exists invites_owner_all on public.invite_tokens;
create policy invites_owner_select on public.invite_tokens
for select to authenticated
using (public.is_room_owner(room_id));
create policy invites_owner_insert on public.invite_tokens
for insert to authenticated
with check (
  public.is_room_owner(room_id)
  and exists (
    select 1
    from public.rooms
    where id = room_id and status not in ('archived', 'dissolved')
  )
);

alter table public.room_members replica identity full;
alter table public.game_sessions replica identity full;
alter table public.rounds replica identity full;
alter table public.score_changes replica identity full;

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
  existing_creator uuid;
  next_round_number integer;
  change jsonb;
  player_id uuid;
  scoring_mode text;
  change_total integer;
  existing_change record;
begin
  if actor_id is null then
    raise exception 'not_authenticated';
  end if;
  if p_operation not in ('create', 'update', 'delete') then
    raise exception 'invalid_operation';
  end if;
  if jsonb_typeof(p_changes) <> 'array' then
    raise exception 'changes_required';
  end if;
  if p_operation <> 'delete' and jsonb_array_length(p_changes) = 0 then
    raise exception 'changes_required';
  end if;
  if p_operation_id is not null then
    select (payload ->> 'round_id')::uuid
      into target_round_id
    from public.sync_operations
    where operation_id = p_operation_id;
    if target_round_id is not null then
      return target_round_id;
    end if;
  end if;

  select s.room_id, r.scoring_mode
    into target_room_id, scoring_mode
  from public.game_sessions s
  join public.rooms r on r.id = s.room_id
  where s.id = p_session_id and s.status = 'active'
  for update of s;
  if target_room_id is null or not public.can_input_room(target_room_id) then
    raise exception 'round_write_forbidden';
  end if;

  if p_operation = 'create' then
    select coalesce(max(round_number), 0) + 1
      into next_round_number
    from public.rounds
    where session_id = p_session_id;

    insert into public.rounds (
      id, session_id, round_number, created_by, note
    ) values (
      coalesce(p_round_id, gen_random_uuid()),
      p_session_id,
      next_round_number,
      actor_id,
      p_note
    ) returning id into target_round_id;
  else
    select id, created_by
      into target_round_id, existing_creator
    from public.rounds
    where session_id = p_session_id
      and (
        (p_round_id is not null and id = p_round_id)
        or (p_round_id is null and round_number = p_round_number)
      )
    limit 1;

    if target_round_id is null then
      raise exception 'round_not_found';
    end if;
    if existing_creator <> actor_id then
      raise exception 'round_edit_forbidden';
    end if;

    if p_operation = 'update' then
      for existing_change in
        select player_id, value
        from public.score_changes
        where round_id = target_round_id
      loop
        if not exists (
          select 1
          from public.room_members
          where room_id = target_room_id
            and user_id = existing_change.player_id
            and left_at is null
        ) and not exists (
          select 1
          from jsonb_array_elements(p_changes) as item
          where (item ->> 'player_id')::uuid = existing_change.player_id
        ) then
          p_changes := p_changes || jsonb_build_array(
            jsonb_build_object(
              'player_id', existing_change.player_id,
              'value', existing_change.value
            )
          );
        end if;
      end loop;
    end if;

    if p_operation = 'delete' then
      update public.rounds
      set deleted_at = now(), version = version + 1
      where id = target_round_id;
    else
      update public.rounds
      set note = p_note, deleted_at = null, version = version + 1
      where id = target_round_id;
    end if;
  end if;

  if p_operation <> 'delete' and scoring_mode = 'money' then
    select coalesce(sum((item ->> 'value')::integer), 0)
      into change_total
    from jsonb_array_elements(p_changes) as item;
    if change_total <> 0 then
      raise exception 'money_round_unbalanced';
    end if;
  end if;

  if p_operation <> 'delete' then
    for change in select * from jsonb_array_elements(p_changes) loop
      player_id := (change ->> 'player_id')::uuid;
      if not exists (
        select 1
        from public.room_members
        where room_id = target_room_id
          and user_id = player_id
          and left_at is null
      ) and not (
        p_operation = 'update'
        and exists (
          select 1
          from public.score_changes existing_score
          where existing_score.round_id = target_round_id
            and existing_score.player_id = player_id
        )
      ) then
        raise exception 'player_not_in_room';
      end if;
    end loop;
    delete from public.score_changes where round_id = target_round_id;
    for change in select * from jsonb_array_elements(p_changes) loop
      insert into public.score_changes (
        round_id, player_id, created_by, value
      ) values (
        target_round_id,
        (change ->> 'player_id')::uuid,
        actor_id,
        (change ->> 'value')::integer
      );
    end loop;
  end if;

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

revoke all on function public.assert_room_open(uuid) from public, anon;
revoke execute on function public.upsert_round_with_scores(
  uuid, uuid, integer, text, jsonb, text, text
) from public, anon;
grant execute on function public.upsert_round_with_scores(
  uuid, uuid, integer, text, jsonb, text, text
) to authenticated;
