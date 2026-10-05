import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/domain/room_snapshot.dart';
import 'package:paizhang/infrastructure/backend/supabase_sync_queue.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/infrastructure/local/local_room_cache.dart';
import 'package:paizhang/infrastructure/local/sync_queue.dart';

import '../support/fakes.dart';

void main() {
  late AppDatabase database;
  late SyncQueue queue;
  late FakeRoomRepository repository;
  late SupabaseSyncQueue remote;
  late String actor;
  late DateTime now;

  LocalRoomCache cache(String actorId) => LocalRoomCache(database, actorId: actorId);
  Future<void> saveSnapshot(RoomSnapshot snapshot, {String actorId = ownerId}) =>
      cache(actorId).saveRoomSnapshot(room: snapshot.room, sessions: snapshot.sessions,
          rounds: snapshot.rounds, profiles: snapshot.profiles, closeVote: snapshot.closeVote);

  setUp(() {
    actor = ownerId;
    now = fixtureDate;
    database = AppDatabase(NativeDatabase.memory());
    queue = SyncQueue(database, currentActorId: () => actor, clock: () => now);
    repository = FakeRoomRepository();
    remote = SupabaseSyncQueue(queue: queue, repository: repository, cacheForActor: cache);
  });
  tearDown(() async => database.close());

  test('账号切换后只提交当前账号操作，原账号再次登录可恢复', () async {
    await saveSnapshot(fixtureSnapshot());
    await queue.enqueueRound(operationId: 'op-a', roomId: 'room-1', operation: 'create', round: fixtureRound());
    actor = memberId;
    repository.actor = actor;
    queue.invalidateSession();
    await remote.flush();
    expect(repository.writes, isEmpty);
    expect(await cache(memberId).loadRoomSnapshot('room-1'), isNull);
    expect(await database.pendingOperations(actorId: ownerId), hasLength(1));
    actor = ownerId;
    repository.actor = actor;
    queue.invalidateSession();
    await remote.flush();
    expect(repository.writes.single.actorId, ownerId);
    expect(await database.pendingOperations(actorId: ownerId), isEmpty);
    expect((await cache(ownerId).loadRoomSnapshot('room-1'))!.rounds, hasLength(1));
  });

  test('过期控制器不能把操作加入新账号队列', () async {
    final generation = queue.generation;
    actor = memberId;
    queue.invalidateSession();
    await expectLater(queue.enqueueRound(operationId: 'stale', roomId: 'room-1',
      operation: 'create', round: fixtureRound(), expectedActorId: ownerId,
      expectedGeneration: generation), throwsA(isA<AppError>()));
    expect(await database.pendingOperations(actorId: memberId), isEmpty);
  });

  test('在途响应遇到切换账号，不确认旧操作或写入新账号缓存', () async {
    await queue.enqueueRound(operationId: 'in-flight', roomId: 'room-1', operation: 'create', round: fixtureRound());
    final started = Completer<void>();
    final response = Completer<Round>();
    repository.onWrite = (_) { started.complete(); return response.future; };
    final flushing = remote.flush();
    await started.future;
    actor = memberId;
    repository.actor = actor;
    queue.invalidateSession();
    response.complete(fixtureRound());
    await flushing;
    expect((await database.operation(ownerId, 'in-flight'))!.status, 'pending');
    expect(await cache(memberId).findRounds('session-1'), isEmpty);
  });

  test('账号切换期间等待中的 flush 会继续提交新账号操作', () async {
    final started = Completer<void>();
    final oldResponse = Completer<Round>();
    var calls = 0;
    repository.onWrite = (mutation) {
      calls++;
      if (calls == 1) {
        started.complete();
        return oldResponse.future;
      }
      return Future.value(mutation.round);
    };
    await queue.enqueueRound(
      operationId: 'old-operation',
      roomId: 'room-1',
      operation: 'create',
      round: fixtureRound(),
    );
    final oldFlush = remote.flush();
    await started.future;

    actor = memberId;
    repository.actor = memberId;
    queue.invalidateSession();
    await queue.enqueueRound(
      operationId: 'new-operation',
      roomId: 'room-2',
      operation: 'create',
      round: fixtureRound(id: 'new-round', sessionId: 'new-session'),
    );
    final newFlush = remote.flush();
    oldResponse.complete(fixtureRound());
    await Future.wait([oldFlush, newFlush]);

    expect(calls, 2);
    expect((await database.operation(ownerId, 'old-operation'))!.status, 'pending');
    expect((await database.operation(memberId, 'new-operation'))!.status, 'synced');
  });

  test('远端快照刷新不会移除本地待确认变化', () async {
    final baseline = fixtureSnapshot(rounds: [fixtureRound()]);
    await saveSnapshot(baseline);
    await queue.enqueueRound(operationId: 'edit', roomId: 'room-1', operation: 'update',
      round: fixtureRound(value: 25, version: 2), baseVersion: 1);
    await saveSnapshot(baseline);
    final visible = await cache(ownerId).loadRoomSnapshot('room-1');
    final confirmed = await cache(ownerId).loadRoomSnapshot('room-1', includePending: false);
    expect(visible!.rounds.single.changes.first.value, 25);
    expect(confirmed!.rounds.single.changes.first.value, 10);
    expect(visible.profiles[ownerId]!.avatarKey, 'preset:tea');
  });

  test('滞后的快照不能覆盖已确认的新版本或移除新回合', () async {
    await saveSnapshot(fixtureSnapshot(rounds: [fixtureRound()]));
    await cache(ownerId).saveRound(fixtureRound(value: 30, version: 3));
    await cache(ownerId).saveRound(fixtureRound(id: 'round-2', number: 2, value: 40));
    await saveSnapshot(fixtureSnapshot(rounds: [fixtureRound()]));
    final restored = await cache(ownerId).loadRoomSnapshot('room-1');
    expect(restored!.rounds, hasLength(2));
    expect(restored.rounds.first.version, 3);
    expect(restored.rounds.first.changes.first.value, 30);
  });

  test('重复快照只更新新鲜度，不重建全部回合和分数', () async {
    final local = cache(ownerId);
    final snapshot = fixtureSnapshot(rounds: [for (var i = 0; i < 100; i++)
      fixtureRound(id: 'round-$i', number: i + 1)]);
    await local.saveRoomSnapshot(room: snapshot.room, sessions: snapshot.sessions,
      rounds: snapshot.rounds, profiles: snapshot.profiles);
    expect(local.lastWriteCount, greaterThan(300));
    await local.saveRoomSnapshot(room: snapshot.room, sessions: snapshot.sessions,
      rounds: snapshot.rounds, profiles: snapshot.profiles);
    expect(local.lastWriteCount, lessThanOrEqualTo(1));
  });

  test('永久业务拒绝不阻塞其他房间，依赖修改保持阻塞', () async {
    await queue.enqueueRound(operationId: 'bad', roomId: 'room-1', operation: 'create', round: fixtureRound());
    await queue.enqueueRound(operationId: 'dependent', roomId: 'room-1', operation: 'update',
      round: fixtureRound(value: 20, version: 2), baseVersion: 1);
    await queue.enqueueRound(operationId: 'other', roomId: 'room-2', operation: 'create',
      round: fixtureRound(id: 'other-round', sessionId: 'other-session'));
    repository.onWrite = (mutation) async {
      if (mutation.roomId == 'room-1') throw const AppError(AppErrorKind.forbidden, '牌局已结束');
      return mutation.round;
    };
    await remote.flush();
    expect(repository.writes.map((write) => write.operationId), ['bad', 'other']);
    expect((await database.operation(ownerId, 'bad'))!.status, 'rejected');
    expect((await database.operation(ownerId, 'dependent'))!.status, 'rejected');
    expect((await database.operation(ownerId, 'other'))!.status, 'synced');
  });

  test('网络失败按退避时间重试，不重复立即提交', () async {
    await queue.enqueueRound(operationId: 'retry', roomId: 'room-1', operation: 'create', round: fixtureRound());
    repository.onWrite = (_) async => throw const AppError(AppErrorKind.network, '离线');
    await remote.flush();
    await remote.flush();
    expect(repository.writes, hasLength(1));
    final entry = (await database.operation(ownerId, 'retry'))!;
    expect(entry.attemptCount, 1);
    expect(entry.nextAttemptAt!.toUtc(), now.add(const Duration(seconds: 2)));
    now = now.add(const Duration(seconds: 2));
    repository.onWrite = null;
    await remote.flush();
    expect(repository.writes, hasLength(2));
    expect((await database.operation(ownerId, 'retry'))!.status, 'synced');
  });

  test('连续离线编辑使用前驱实际 ACK 版本而不是猜测版本', () async {
    await queue.enqueueRound(operationId: 'create', roomId: 'room-1', operation: 'create', round: fixtureRound());
    await queue.enqueueRound(operationId: 'update', roomId: 'room-1', operation: 'update',
      round: fixtureRound(value: 20, version: 2), baseVersion: 1);
    repository.onWrite = (mutation) async => mutation.round.copyWith(
        version: mutation.operation == 'create' ? 7 : 8);
    await remote.flush();
    expect(repository.writes.map((write) => write.expectedVersion), [null, 7]);
    expect((await database.operation(ownerId, 'update'))!.status, 'synced');
  });

  test('版本冲突保留输入且阻止盲目重试', () async {
    repository.snapshot = fixtureSnapshot(rounds: [fixtureRound(value: 40, version: 2)]);
    await queue.enqueueRound(operationId: 'conflict', roomId: 'room-1', operation: 'update',
      round: fixtureRound(value: 20, version: 2), baseVersion: 1);
    await remote.flush();
    final entry = (await database.operation(ownerId, 'conflict'))!;
    expect(entry.status, 'conflict');
    expect(queue.mutationFromEntry(entry).round.changes.first.value, 20);
    await expectLater(queue.retry(entry.operationId), throwsA(isA<AppError>()));
    expect(repository.snapshot.rounds.single.changes.first.value, 40);
  });
}
