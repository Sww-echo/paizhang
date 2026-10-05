import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paizhang/infrastructure/backend/supabase_room_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

const actor = '10000000-0000-4000-8000-000000000001';
const roomId = '20000000-0000-4000-8000-000000000001';
const sessionId = '30000000-0000-4000-8000-000000000001';

class _Repository extends SupabaseRoomRepository {
  _Repository(super.client);
  @override
  String? get currentUserId => actor;
}

Map<String, Object?> wireRound(int number) => {
  'id': '40000000-0000-4000-8000-${number.toString().padLeft(12, '0')}',
  'session_id': sessionId,
  'round_number': number,
  'created_by': actor,
  'created_at': '2026-10-03T00:00:00Z',
  'version': 2,
  'score_changes': [
    {'player_id': actor, 'value': 10},
  ],
};

Map<String, Object?> wireRoom() => {
  'id': roomId,
  'name': '测试',
  'owner_id': actor,
  'game_type': 'test',
  'scoring_mode': 'points',
  'status': 'active',
  'input_permission': 'all',
  'created_at': '2026-10-03T00:00:00Z',
  'version': 1,
  'room_members': [
    {
      'user_id': actor,
      'role': 'owner',
      'input_permission': 'all',
      'joined_at': '2026-10-03T00:00:00Z',
    },
  ],
};

Map<String, Object?> wireSession() => {
  'id': sessionId,
  'room_id': roomId,
  'name': '第一场',
  'status': 'active',
  'created_at': '2026-10-03T00:00:00Z',
  'version': 1,
};

void main() {
  test('正式仓储向版本化 RPC 提交账号与基础版本，并直接使用 ACK', () async {
    final requests = <http.Request>[];
    final httpClient = MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode(wireRound(1)),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final client = SupabaseClient(
      'https://unit-test.invalid',
      'test-key',
      httpClient: httpClient,
    );
    addTearDown(client.dispose);
    final repository = _Repository(client);
    final result = await repository.writeRound(
      RoundMutation(
        operationId: 'op-test',
        actorId: actor,
        roomId: roomId,
        operation: 'update',
        expectedVersion: 1,
        round: roundFromJson(Map<String, dynamic>.from(wireRound(1))),
      ),
    );
    expect(requests, hasLength(1));
    expect(
      requests.single.url.path,
      '/rest/v1/rpc/upsert_round_with_scores_v2',
    );
    final body = jsonDecode(requests.single.body) as Map;
    expect(body['p_actor_id'], actor);
    expect(body['p_expected_version'], 1);
    expect(body['p_operation_id'], 'op-test');
    expect(result.version, 2);
  });

  test('当前房间回合分页使用稳定复合游标而非 offset', () async {
    final requests = <http.Request>[];
    final httpClient = MockClient((request) async {
      requests.add(request);
      final rows = requests.length == 1
          ? [for (var n = 1; n <= 500; n++) wireRound(n)]
          : [wireRound(501)];
      return http.Response(
        jsonEncode(rows),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final client = SupabaseClient(
      'https://unit-test.invalid',
      'test-key',
      httpClient: httpClient,
    );
    addTearDown(client.dispose);
    final values = await _Repository(client).listRoundsForSessions([sessionId]);
    expect(values, hasLength(501));
    expect(values.map((round) => round.id).toSet(), hasLength(501));
    expect(requests, hasLength(2));
    expect(
      requests.last.url.queryParameters['order'],
      'session_id.asc.nullslast,round_number.asc.nullslast,id.asc.nullslast',
    );
    expect(
      requests.last.url.queryParameters['or'],
      contains('round_number.gt.500'),
    );
    expect(requests.last.url.queryParameters.containsKey('offset'), isFalse);
  });

  test('历史详情沿用返回游标并汇总完整牌局供结算', () async {
    final bodies = <Map<String, dynamic>>[];
    final httpClient = MockClient((request) async {
      bodies.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
      return http.Response(
        jsonEncode({
          'room': wireRoom(),
          'sessions': [wireSession()],
          'profiles': [],
          'rounds': [wireRound(bodies.length)],
          'has_more': bodies.length == 1,
          'next_number': bodies.length,
          'next_id': wireRound(bodies.length)['id'],
        }),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final client = SupabaseClient(
      'https://unit-test.invalid',
      'test-key',
      httpClient: httpClient,
    );
    addTearDown(client.dispose);
    final value = await _Repository(client)
        .getHistorySession(roomId, sessionId);
    expect(value.rounds, hasLength(2));
    expect(bodies, hasLength(2));
    expect(bodies.last['p_after_number'], 1);
    expect(bodies.last['p_after_id'], wireRound(1)['id']);
  });
}
