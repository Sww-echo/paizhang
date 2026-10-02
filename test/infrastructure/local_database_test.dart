import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paizhang/domain/models.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/infrastructure/local/local_room_cache.dart';
import 'package:paizhang/infrastructure/local/sync_queue.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('房间和成员可以写入本地 SQL 缓存', () async {
    final cache = LocalRoomCache(database);
    final room = Room(
      id: 'room-1',
      name: '周末牌局',
      ownerId: 'user-1',
      gameType: '掼蛋',
      scoringMode: ScoringMode.points,
      createdAt: DateTime.utc(2026, 9, 30),
      members: [
        RoomMember(
          userId: 'user-1',
          role: RoomRole.owner,
          joinedAt: DateTime.utc(2026, 9, 30),
        ),
      ],
    );

    await cache.saveRoom(room);

    expect((await cache.findRoom('room-1'))?.name, '周末牌局');
    expect(await cache.findMembers('room-1'), hasLength(1));
  });

  test('刷新房间时会移除已经离开的旧成员缓存', () async {
    final cache = LocalRoomCache(database);
    final room = Room(
      id: 'room-1',
      name: '周末牌局',
      ownerId: 'user-1',
      gameType: '掼蛋',
      scoringMode: ScoringMode.points,
      createdAt: DateTime.utc(2026, 9, 30),
      members: [
        RoomMember(
          userId: 'user-1',
          role: RoomRole.owner,
          joinedAt: DateTime.utc(2026, 9, 30),
        ),
        RoomMember(
          userId: 'user-2',
          role: RoomRole.member,
          joinedAt: DateTime.utc(2026, 9, 30),
        ),
      ],
    );

    await cache.saveRoom(room);
    await cache.saveRoom(room.copyWith(members: [room.members.first]));

    expect(await cache.findMembers('room-1'), hasLength(1));
    expect((await cache.findMembers('room-1')).single.userId, 'user-1');
  });

  test('房间快照会同步牌局、回合和分数并清理旧数据', () async {
    final cache = LocalRoomCache(database);
    final room = Room(
      id: 'room-1',
      name: '周末牌局',
      ownerId: 'user-1',
      gameType: '掼蛋',
      scoringMode: ScoringMode.points,
      createdAt: DateTime.utc(2026, 9, 30),
      members: [
        RoomMember(
          userId: 'user-1',
          role: RoomRole.owner,
          joinedAt: DateTime.utc(2026, 9, 30),
        ),
        RoomMember(
          userId: 'user-2',
          role: RoomRole.member,
          joinedAt: DateTime.utc(2026, 9, 30),
        ),
      ],
    );
    final session = GameSession(
      id: 'session-1',
      roomId: room.id,
      name: '第一场',
      status: GameSessionStatus.active,
      createdAt: room.createdAt,
    );
    final round = Round(
      id: 'round-1',
      sessionId: session.id,
      number: 1,
      changes: const [
        ScoreChange(playerId: 'user-1', value: 20),
        ScoreChange(playerId: 'user-2', value: -20),
      ],
      createdBy: 'user-1',
      createdAt: room.createdAt,
    );

    await cache.saveRoomSnapshot(
      room: room,
      sessions: [session],
      rounds: [round],
    );
    expect(await cache.findGameSessions(room.id), hasLength(1));
    expect(await cache.findRounds(session.id), hasLength(1));
    expect(await cache.findScoreChanges(round.id), hasLength(2));

    await cache.saveRoomSnapshot(
      room: room,
      sessions: const [],
      rounds: const [],
    );
    expect(await cache.findGameSessions(room.id), isEmpty);
    expect(await cache.findRounds(session.id), isEmpty);
    expect(await cache.findScoreChanges(round.id), isEmpty);
  });

  test('同步队列支持成功确认和失败重试计数', () async {
    final queue = SyncQueue(database);
    await queue.enqueue(
      operationId: 'op-1',
      entityType: 'round',
      entityId: 'round-1',
      operation: 'create',
      payload: {'value': 20},
    );
    await queue.flush((entry) async {
      expect(entry.operationId, 'op-1');
    });
    expect(await database.pendingOperations(), isEmpty);

    await queue.enqueue(
      operationId: 'op-2',
      entityType: 'round',
      entityId: 'round-2',
      operation: 'create',
      payload: {'value': -20},
    );
    await queue.flush((_) async => throw StateError('network'));
    final pending = await database.pendingOperations();
    expect(pending.single.attemptCount, 1);
    expect(pending.single.lastError, contains('network'));
  });

  test('同步队列失败后会暂停后续操作，保持提交顺序', () async {
    final queue = SyncQueue(database);
    await queue.enqueue(
      operationId: 'op-failed',
      entityType: 'round',
      entityId: 'round-1',
      operation: 'create',
      payload: const {},
    );
    await queue.enqueue(
      operationId: 'op-next',
      entityType: 'round',
      entityId: 'round-2',
      operation: 'create',
      payload: const {},
    );

    final pushed = <String>[];
    await queue.flush((entry) async {
      pushed.add(entry.operationId);
      throw StateError('network');
    });

    expect(pushed, ['op-failed']);
    expect(await database.pendingOperations(), hasLength(2));
  });

  test('同步队列并发刷新只执行一次，避免重复提交', () async {
    final queue = SyncQueue(database);
    await queue.enqueue(
      operationId: 'op-concurrent',
      entityType: 'round',
      entityId: 'round-1',
      operation: 'create',
      payload: const {},
    );

    var pushCount = 0;
    final firstFlush = queue.flush((_) async {
      pushCount++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    final secondFlush = queue.flush((_) async {
      pushCount++;
    });

    await Future.wait([firstFlush, secondFlush]);

    expect(pushCount, 1);
    expect(await database.pendingOperations(), isEmpty);
  });

  test('回合同步队列可以保存可重放的分数负载', () async {
    final queue = SyncQueue(database);
    await queue.enqueue(
      operationId: 'op-round-1',
      entityType: 'round',
      entityId: 'round-1',
      operation: 'create',
      payload: {
        'round_id': 'round-1',
        'session_id': 'session-1',
        'round_number': 1,
        'changes': [
          {'player_id': 'user-1', 'value': 20},
          {'player_id': 'user-2', 'value': -20},
        ],
      },
    );

    final entry = (await database.pendingOperations()).single;
    expect(entry.payloadJson, contains('session-1'));
    expect(entry.payloadJson, contains('user-2'));
  });
}
