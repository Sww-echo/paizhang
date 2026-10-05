import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/room_snapshot.dart';
import 'package:paizhang/infrastructure/backend/room_sync_coordinator.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/infrastructure/local/local_room_cache.dart';

import '../support/fakes.dart';

void main() {
  test('悬挂快照超时后释放刷新入口，晚响应不能覆盖恢复后的快照', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final cache = LocalRoomCache(database, actorId: ownerId);
    final repository = FakeRoomRepository(
      snapshot: fixtureSnapshot(rounds: [fixtureRound()]),
    );
    final errors = <AppError>[];
    final coordinator = RoomSyncCoordinator(
      repository: repository,
      realtime: FakeRoomEvents(),
      cache: cache,
      isCurrent: () => true,
      refreshTimeout: const Duration(milliseconds: 20),
      onError: (error) async => errors.add(error as AppError),
    );
    addTearDown(() async {
      await coordinator.dispose();
      await database.close();
    });
    await coordinator.start('room-1');

    final hanging = Completer<RoomSnapshot>();
    repository.onFetch = (_) => hanging.future;
    await coordinator.refresh();
    expect(errors.single.kind, AppErrorKind.network);
    expect((await cache.loadRoomSnapshot('room-1'))!.rounds.single.version, 1);

    repository.onFetch = null;
    repository.snapshot = fixtureSnapshot(
      rounds: [fixtureRound(value: 40, version: 2)],
    );
    await coordinator.refresh();
    expect(repository.fetchCount, 3);
    expect(
      (await cache.loadRoomSnapshot('room-1'))!
          .rounds
          .single
          .changes
          .first
          .value,
      40,
    );

    hanging.complete(
      fixtureSnapshot(rounds: [fixtureRound(value: 90, version: 3)]),
    );
    await Future<void>.delayed(Duration.zero);
    final restored = await cache.loadRoomSnapshot('room-1');
    expect(restored!.rounds.single.version, 2);
    expect(restored.rounds.single.changes.first.value, 40);
  });
}
