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
}
