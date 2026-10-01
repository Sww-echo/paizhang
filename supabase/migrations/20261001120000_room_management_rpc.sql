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

revoke execute on function public.set_room_input_permission(uuid, text) from public, anon;
grant execute on function public.set_room_input_permission(uuid, text) to authenticated;
revoke execute on function public.remove_room_member(uuid, uuid) from public, anon;
grant execute on function public.remove_room_member(uuid, uuid) to authenticated;
revoke execute on function public.transfer_room_ownership(uuid, uuid) from public, anon;
grant execute on function public.transfer_room_ownership(uuid, uuid) to authenticated;
revoke execute on function public.revoke_room_invite(uuid) from public, anon;
grant execute on function public.revoke_room_invite(uuid) to authenticated;
revoke execute on function public.refresh_room_invite(uuid, text, text, text, timestamptz) from public, anon;
grant execute on function public.refresh_room_invite(uuid, text, text, text, timestamptz) to authenticated;
