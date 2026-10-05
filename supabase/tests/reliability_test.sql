begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

insert into auth.users(id, email, raw_user_meta_data) values
  ('10000000-0000-4000-8000-000000000001', 'owner@example.invalid', '{"nickname":"owner"}'),
  ('10000000-0000-4000-8000-000000000002', 'member@example.invalid', '{"nickname":"member"}'),
  ('10000000-0000-4000-8000-000000000003', 'former@example.invalid', '{"nickname":"former"}'),
  ('10000000-0000-4000-8000-000000000004', 'outsider@example.invalid', '{"nickname":"outsider"}');
insert into public.rooms(id, owner_id, name, game_type, scoring_mode, status)
values ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'test room', 'test', 'money', 'active');
insert into public.room_members(room_id, user_id, role, joined_at, left_at) values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 'owner', now() - interval '2 days', null),
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'member', now() - interval '2 days', null),
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', 'member', now() - interval '2 days', now() - interval '1 hour');
insert into public.game_sessions(id, room_id, name, status, created_at, started_at) values
  ('30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'old session', 'active', now() - interval '1 day', now() - interval '1 day'),
  ('30000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 'later session', 'active', now() - interval '30 minutes', now() - interval '30 minutes');
insert into public.rounds(id, session_id, round_number, created_by, created_at) values
  ('40000000-0000-4000-8000-000000000099', '30000000-0000-4000-8000-000000000001', 1, '10000000-0000-4000-8000-000000000001', now() - interval '1 day'),
  ('40000000-0000-4000-8000-000000000098', '30000000-0000-4000-8000-000000000002', 1, '10000000-0000-4000-8000-000000000001', now() - interval '20 minutes');
insert into public.score_changes(round_id, player_id, created_by, value)
select round.id, member.user_id, round.created_by,
  case when member.role = 'owner' then 5 else -5 end
from public.rounds round join public.room_members member
  on member.room_id = '20000000-0000-4000-8000-000000000001' and member.left_at is null
where round.id in ('40000000-0000-4000-8000-000000000099', '40000000-0000-4000-8000-000000000098');

set local role authenticated;
set local "request.jwt.claim.sub" = '10000000-0000-4000-8000-000000000001';
set local "request.jwt.claims" = '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}';

select is((public.upsert_round_with_scores_v2(
  '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 999, null,
  '[{"player_id":"10000000-0000-4000-8000-000000000001","value":10},{"player_id":"10000000-0000-4000-8000-000000000002","value":-10}]',
  'test-create', 'create', null, '10000000-0000-4000-8000-000000000001') ->> 'round_number')::integer,
  2, 'server assigns the next round number');
select is((public.upsert_round_with_scores_v2(
  '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 2, null,
  '[{"player_id":"10000000-0000-4000-8000-000000000001","value":20},{"player_id":"10000000-0000-4000-8000-000000000002","value":-20}]',
  'test-edit', 'update', 1, '10000000-0000-4000-8000-000000000001') ->> 'version')::bigint,
  2::bigint, 'matching version updates atomically');
select is((public.upsert_round_with_scores_v2(
  '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 999, null,
  '[{"player_id":"10000000-0000-4000-8000-000000000001","value":10},{"player_id":"10000000-0000-4000-8000-000000000002","value":-10}]',
  'test-create', 'create', null, '10000000-0000-4000-8000-000000000001') ->> 'version')::bigint,
  1::bigint, 'idempotent replay returns original ACK rather than current version');
select is((select count(*) from public.rounds where session_id = '30000000-0000-4000-8000-000000000001'),
  2::bigint, 'replay does not create another round');
select throws_ok($sql$
  select public.upsert_round_with_scores_v2(
    '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 2, null,
    '[{"player_id":"10000000-0000-4000-8000-000000000001","value":30},{"player_id":"10000000-0000-4000-8000-000000000002","value":-30}]',
    'stale-edit', 'update', 1, '10000000-0000-4000-8000-000000000001')
$sql$, '40001', 'version_conflict', 'stale edits do not overwrite new data');
select throws_ok($sql$
  select public.upsert_round_with_scores_v2(
    '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 2, null, '[]',
    'missing-version', 'delete', null, '10000000-0000-4000-8000-000000000001')
$sql$, '40001', 'version_required', 'delete also requires a version');
select throws_ok($sql$
  select public.upsert_round_with_scores_v2(
    '40000000-0000-4000-8000-000000000088', '30000000-0000-4000-8000-000000000001', 3, null,
    '[{"player_id":"10000000-0000-4000-8000-000000000001","value":30}]',
    'unbalanced', 'create', null, '10000000-0000-4000-8000-000000000001')
$sql$, 'P0001', 'money_round_unbalanced', 'money balancing is enforced on the server');
select throws_ok($sql$
  select public.upsert_round_with_scores('40000000-0000-4000-8000-000000000001',
    '30000000-0000-4000-8000-000000000001', 2, null, '[]', 'legacy', 'delete')
$sql$, 'P0001', 'client_upgrade_required', 'legacy RPC cannot bypass version checks');
select ok(not has_table_privilege('authenticated', 'public.sync_operations', 'INSERT'),
  'clients cannot forge server acknowledgements');
select throws_ok($sql$ update public.rounds set note = 'direct write' where id = '40000000-0000-4000-8000-000000000001' $sql$,
  '42501', null, 'direct table writes remain forbidden');

set local "request.jwt.claim.sub" = '10000000-0000-4000-8000-000000000002';
set local "request.jwt.claims" = '{"sub":"10000000-0000-4000-8000-000000000002","role":"authenticated"}';
select throws_ok($sql$
  select public.upsert_round_with_scores_v2(
    '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 999, null,
    '[{"player_id":"10000000-0000-4000-8000-000000000001","value":10},{"player_id":"10000000-0000-4000-8000-000000000002","value":-10}]',
    'test-create', 'create', null, '10000000-0000-4000-8000-000000000002')
$sql$, 'P0001', 'operation_conflict', 'operation IDs cannot be replayed by another account');
select throws_ok($sql$
  select public.upsert_round_with_scores_v2(
    '40000000-0000-4000-8000-000000000077', '30000000-0000-4000-8000-000000000001', 3, null,
    '[{"player_id":"10000000-0000-4000-8000-000000000001","value":10}]',
    'wrong-actor', 'create', null, '10000000-0000-4000-8000-000000000001')
$sql$, 'P0001', 'not_authenticated', 'expected actor rejects an in-flight account switch');

set local "request.jwt.claim.sub" = '10000000-0000-4000-8000-000000000001';
set local "request.jwt.claims" = '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}';
select is((public.upsert_round_with_scores_v2(
  '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 2, null, '[]',
  'test-delete', 'delete', 2, '10000000-0000-4000-8000-000000000001') ->> 'version')::bigint,
  3::bigint, 'delete advances the version');
select is((public.upsert_round_with_scores_v2(
  '40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 2, null,
  '[{"player_id":"10000000-0000-4000-8000-000000000001","value":20},{"player_id":"10000000-0000-4000-8000-000000000002","value":-20}]',
  'test-restore', 'update', 3, '10000000-0000-4000-8000-000000000001') ->> 'version')::bigint,
  4::bigint, 'restore advances the version and preserves scores');
select is((select count(*) from public.get_room_history_sessions('20000000-0000-4000-8000-000000000001')),
  2::bigint, 'current members can list both sessions');
select is((public.get_room_history_snapshot('20000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001', 1) ->> 'has_more')::boolean,
  true, 'history detail exposes a continuation cursor');
select is(jsonb_array_length(public.get_room_history_snapshot('20000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001', 1, 1, '40000000-0000-4000-8000-000000000099') -> 'rounds'),
  1, 'continuation returns the next round without duplicating the first');
select ok(not exists(select 1 from jsonb_array_elements(public.get_room_history_snapshot(
  '20000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001') -> 'profiles') profile
  where profile ? 'phone' or profile ? 'email'), 'history profiles do not expose contact information');

set local "request.jwt.claim.sub" = '10000000-0000-4000-8000-000000000003';
set local "request.jwt.claims" = '{"sub":"10000000-0000-4000-8000-000000000003","role":"authenticated"}';
select is((select count(*) from public.get_room_history_sessions('20000000-0000-4000-8000-000000000001')),
  1::bigint, 'former members cannot see sessions created after leaving');
select is(jsonb_array_length(public.get_room_history_snapshot('20000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001') -> 'rounds'), 1, 'former members cannot see later rounds');
select throws_ok($sql$ select public.get_room_history_snapshot('20000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000002') $sql$, 'P0001', 'room_not_found', 'detail enforces the same cutoff');

set local "request.jwt.claim.sub" = '10000000-0000-4000-8000-000000000004';
set local "request.jwt.claims" = '{"sub":"10000000-0000-4000-8000-000000000004","role":"authenticated"}';
select is((select count(*) from public.get_room_history_page()), 0::bigint, 'outsiders cannot list another room');
select throws_ok($sql$ select public.get_room_history_snapshot('20000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000001') $sql$, 'P0001', 'room_member_required', 'outsiders cannot load details');

reset role;
select * from finish();
rollback;
