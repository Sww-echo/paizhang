revoke all on function public.handle_new_user() from public;
revoke all on function public.is_room_member(uuid) from public;
revoke all on function public.is_room_owner(uuid) from public;
revoke all on function public.can_input_room(uuid) from public;
revoke all on function public.create_room(text, text, text) from public;
revoke all on function public.join_room_by_invite(text) from public;
revoke all on function public.join_room_by_invite_code(text) from public;
revoke all on function public.leave_room(uuid) from public;

grant execute on function public.is_room_member(uuid) to authenticated;
grant execute on function public.is_room_owner(uuid) to authenticated;
grant execute on function public.can_input_room(uuid) to authenticated;
grant execute on function public.create_room(text, text, text) to authenticated;
grant execute on function public.join_room_by_invite(text) to authenticated;
grant execute on function public.join_room_by_invite_code(text) to authenticated;
grant execute on function public.leave_room(uuid) to authenticated;

drop policy if exists sessions_owner_write on public.game_sessions;
create policy sessions_owner_insert on public.game_sessions
for insert to authenticated
with check (public.is_room_owner(room_id));
create policy sessions_owner_update on public.game_sessions
for update to authenticated
using (public.is_room_owner(room_id))
with check (public.is_room_owner(room_id));
create policy sessions_owner_delete on public.game_sessions
for delete to authenticated
using (public.is_room_owner(room_id));

create index if not exists invite_tokens_room_idx
  on public.invite_tokens(room_id);
create index if not exists rooms_owner_idx
  on public.rooms(owner_id);
create index if not exists rounds_created_by_idx
  on public.rounds(created_by);
create index if not exists score_changes_player_idx
  on public.score_changes(player_id);
create index if not exists score_changes_created_by_idx
  on public.score_changes(created_by);
create index if not exists sync_operations_actor_idx
  on public.sync_operations(actor_id);
