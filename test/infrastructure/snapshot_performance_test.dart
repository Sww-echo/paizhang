import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paizhang/infrastructure/backend/supabase_room_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

const _actor = '10000000-0000-4000-8000-000000000001';
const _roomId = '20000000-0000-4000-8000-000000000001';
const _sessionId = '30000000-0000-4000-8000-000000000001';
const _createdAt = '2026-10-03T00:00:00Z';

class _Repository extends SupabaseRoomRepository {
  _Repository(super.client);

  @override
  String? get currentUserId => _actor;
}

Map<String, Object?> _round(int number) => {
  'id': '40000000-0000-4000-8000-${number.toString().padLeft(12, '0')}',
  'session_id': _sessionId,
  'round_number': number,
  'created_by': _actor,
  'created_at': _createdAt,
  'version': 1,
  'score_changes': [
    {'player_id': _actor, 'value': 10},
  ],
};

void main() {
  test('5001 回合快照请求按页增长，不按回合逐条请求', () async {
    const count = 5001;
    const pageSize = 500;
    final requests = <Uri>[];
    var roundPages = 0;
    var responseBytes = 0;
    final client = SupabaseClient(
      'https://unit-test.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request.url);
        final Object body;
        switch (request.url.path.split('/').last) {
          case 'rooms':
            body = {
              'id': _roomId,
              'name': '大数据量测试房间',
              'owner_id': _actor,
              'game_type': 'test',
              'scoring_mode': 'points',
              'status': 'active',
              'input_permission': 'all',
              'created_at': _createdAt,
              'version': 1,
              'room_members': [
                {
                  'user_id': _actor,
                  'role': 'owner',
                  'input_permission': 'all',
                  'joined_at': _createdAt,
                },
              ],
            };
          case 'game_sessions':
            body = [
              {
                'id': _sessionId,
                'room_id': _roomId,
                'name': '测试牌局',
                'status': 'active',
                'created_at': _createdAt,
                'version': 1,
              },
            ];
          case 'profiles':
            body = [
              {'id': _actor, 'nickname': '测试用户'},
            ];
          case 'room_close_proposals':
            body = [];
          case 'rounds':
            expect(request.url.queryParameters['limit'], '$pageSize');
            expect(request.url.queryParameters.containsKey('offset'), isFalse);
            if (roundPages > 0) {
              expect(
                request.url.queryParameters['or'],
                contains('round_number.gt.${roundPages * pageSize}'),
              );
            }
            final start = roundPages++ * pageSize + 1;
            body = [
              for (var n = start; n < start + pageSize && n <= count; n++)
                _round(n),
            ];
          default:
            fail('Unexpected request: ${request.url.path}');
        }
        final encoded = jsonEncode(body);
        responseBytes += utf8.encode(encoded).length;
        return http.Response(
          encoded,
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);

    final watch = Stopwatch()..start();
    final snapshot = await _Repository(client).getRoomSnapshot(_roomId);
    watch.stop();

    expect(snapshot.rounds, hasLength(count));
    expect(snapshot.rounds.map((round) => round.id).toSet(), hasLength(count));
    expect(snapshot.rounds.last.number, count);
    expect(roundPages, 11);
    expect(requests, hasLength(15));
    expect(snapshot.profiles.keys, [_actor]);
    // Local HTTP fixtures measure parsing and request shape, not network latency.
    // No wall-clock threshold: timings vary across developer and CI machines.
    debugPrint(
      jsonEncode({
        'benchmark': 'snapshot-fixture',
        'rounds': count,
        'requests': requests.length,
        'responseBytes': responseBytes,
        'elapsedUs': watch.elapsedMicroseconds,
      }),
    );
  });

  test('历史首屏只取摘要，不下载牌局回合明细', () async {
    final requests = <Uri>[];
    var responseBytes = 0;
    final client = SupabaseClient(
      'https://unit-test.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request.url);
        expect(request.url.path, '/rest/v1/rpc/get_room_history_page');
        expect((jsonDecode(request.body) as Map)['p_limit'], 20);
        final body = jsonEncode([
          for (var n = 1; n <= 20; n++)
            {
              'room_id':
                  '20000000-0000-4000-8000-${n.toString().padLeft(12, '0')}',
              'room_name': '历史房间 $n',
              'game_type': 'test',
              'scoring_mode': 'points',
              'is_current_member': true,
              'session_count': 100,
              'last_activity_at': _createdAt,
            },
        ]);
        responseBytes += utf8.encode(body).length;
        return http.Response(
          body,
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);

    final watch = Stopwatch()..start();
    final summaries = await _Repository(client).listHistoryRooms();
    watch.stop();

    expect(summaries, hasLength(20));
    expect(summaries.every((room) => room.sessionCount == 100), isTrue);
    expect(requests, hasLength(1));
    debugPrint(
      jsonEncode({
        'benchmark': 'history-summary-fixture',
        'rooms': summaries.length,
        'sessionsPerRoom': 100,
        'requests': requests.length,
        'responseBytes': responseBytes,
        'elapsedUs': watch.elapsedMicroseconds,
      }),
    );
  });
}
