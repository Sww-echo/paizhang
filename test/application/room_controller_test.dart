import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/room_controller.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/room_snapshot.dart';
import 'package:paizhang/infrastructure/backend/supabase_sync_queue.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/infrastructure/local/local_room_cache.dart';
import 'package:paizhang/infrastructure/local/sync_queue.dart';

import '../support/fakes.dart';

void main() {
  late AppDatabase database;
  late LocalRoomCache cache;
  late SyncQueue queue;
  late FakeRoomRepository repository;
  late FakeRoomEvents events;
  late RoomController controller;
  late SupabaseSyncQueue remote;
  var id = 0;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    cache = LocalRoomCache(database, actorId: ownerId);
    queue = SyncQueue(database, currentActorId: () => ownerId);
    repository = FakeRoomRepository();
    events = FakeRoomEvents();
    remote = SupabaseSyncQueue(
      queue: queue,
      repository: repository,
      cacheForActor: (actor) => LocalRoomCache(database, actorId: actor),
    );
    controller = RoomController(
      roomId: 'room-1',
      actorId: ownerId,
      repository: repository,
      cache: cache,
      queue: queue,
      events: events,
      requestSync: () async {},
      idFactory: () => 'id-${id++}',
      clock: () => fixtureDate,
    );
  });
  tearDown(() async {
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    await database.close();
  });

  test('正式控制器首次进入只拉一次快照，并能本地录入后确认', () async {
    await controller.start();
    expect(repository.fetchCount, 1);
    expect(controller.canInput, isTrue);
    await controller.recordRound(
      'session-1',
      fixtureRound(value: 18).changes,
      note: '首局',
    );
    expect(controller.snapshot!.rounds.single.changes.first.value, 18);
    expect(await database.pendingOperations(actorId: ownerId), hasLength(1));
    await remote.flush();
    expect(await database.pendingOperations(actorId: ownerId), isEmpty);
    final restored = await cache.loadRoomSnapshot('room-1');
    expect(restored!.rounds.single.version, 1);
    expect(restored.rounds.single.note, '首局');
  });

  test('离线启动从缓存恢复，不因远端失败清空可用分数', () async {
    final snapshot = fixtureSnapshot(rounds: [fixtureRound(value: 15)]);
    await cache.saveRoomSnapshot(
      room: snapshot.room,
      sessions: snapshot.sessions,
      rounds: snapshot.rounds,
      profiles: snapshot.profiles,
    );
    repository.onFetch = (_) async =>
        throw const AppError(AppErrorKind.network, '离线');
    await controller.start();
    expect(controller.loading, isFalse);
    expect(controller.snapshot!.rounds.single.changes.first.value, 15);
    expect(controller.error!.kind, AppErrorKind.network);
  });

  test('编辑、撤销、恢复在本地立即生效，保留版本依赖', () async {
    repository.snapshot = fixtureSnapshot(rounds: [fixtureRound()]);
    await controller.start();
    await controller.updateRound(
      controller.snapshot!.rounds.single,
      fixtureRound(value: 22).changes,
      note: '修正',
    );
    await controller.deleteRound(controller.snapshot!.rounds.single);
    expect(controller.snapshot!.rounds.single.isDeleted, isTrue);
    await controller.updateRound(
      controller.snapshot!.rounds.single,
      fixtureRound(value: 22).changes,
      note: null,
    );
    expect(controller.snapshot!.rounds.single.isDeleted, isFalse);
    expect(controller.snapshot!.rounds.single.note, isNull);
    await remote.flush();
    expect(repository.writes.map((write) => write.expectedVersion), [1, 2, 3]);
    expect(repository.snapshot.rounds.single.version, 4);
  });

  test('冲突重新确认采用最新基础版本，并保留依赖链最后的草稿', () async {
    repository.snapshot = fixtureSnapshot(rounds: [fixtureRound()]);
    await controller.start();
    await controller.updateRound(
      controller.snapshot!.rounds.single,
      fixtureRound(value: 20).changes,
    );
    await controller.updateRound(
      controller.snapshot!.rounds.single,
      fixtureRound(value: 30).changes,
    );
    repository.snapshot = fixtureSnapshot(
      rounds: [fixtureRound(value: 40, version: 2)],
    );
    await remote.flush();
    final entries = await database.watchOperations(ownerId).first;
    final root = entries.firstWhere((entry) => entry.status == 'conflict');
    final draft = await controller.prepareReapply(root);
    expect(draft.current!.changes.first.value, 40);
    expect(draft.desired.changes.first.value, 30);
    await controller.applyRebased(draft);
    await remote.flush();
    expect(repository.snapshot.rounds.single.changes.first.value, 30);
    expect(repository.writes.last.expectedVersion, 2);
    expect(await database.pendingOperations(actorId: ownerId), isEmpty);
  });

  test('权限失效后不能继续展示可操作的缓存房间', () async {
    await controller.start();
    repository.onFetch = (_) async =>
        throw const AppError(AppErrorKind.forbidden, '已被移除');
    await controller.refresh();
    expect(controller.snapshot, isNull);
    expect(controller.canInput, isFalse);
    expect(await cache.loadRoomSnapshot('room-1'), isNull);
  });

  test('生命周期结束后慢请求不能发布旧房间快照', () async {
    final pending = Completer<RoomSnapshot>();
    final requested = Completer<void>();
    repository.onFetch = (_) {
      requested.complete();
      return pending.future;
    };
    final starting = controller.start();
    await requested.future;
    controller.dispose();
    pending.complete(fixtureSnapshot(rounds: [fixtureRound()]));
    await starting;
    expect(await cache.loadRoomSnapshot('room-1'), isNull);
  });

  test('同一时刻多个刷新合并，重连会再次对账', () async {
    await controller.start();
    final pending = Completer<RoomSnapshot>();
    var slow = true;
    repository.onFetch = (_) =>
        slow ? pending.future : Future.value(repository.snapshot);
    final first = controller.refresh();
    final second = controller.refresh();
    slow = false;
    pending.complete(repository.snapshot);
    await Future.wait([first, second]);
    expect(repository.fetchCount, 3);
    events.connectionController.add(false);
    events.connectionController.add(true);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    expect(repository.fetchCount, 4);
  });
}
