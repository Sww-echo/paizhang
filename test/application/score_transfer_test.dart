import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/room_controller.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/domain/room_snapshot.dart';
import 'package:paizhang/infrastructure/backend/supabase_sync_queue.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/infrastructure/local/local_room_cache.dart';
import 'package:paizhang/infrastructure/local/sync_queue.dart';

import '../support/fakes.dart';

const thirdId = 'user-3';

RoomMember _member(String id, {DateTime? leftAt}) => RoomMember(
  userId: id,
  role: id == ownerId ? RoomRole.owner : RoomRole.member,
  joinedAt: fixtureDate,
  leftAt: leftAt,
);

RoomSnapshot _snapshot({
  List<String> members = const [ownerId, memberId, thirdId],
  DateTime? ownerLeftAt,
  RoomStatus status = RoomStatus.active,
  GameSessionStatus sessionStatus = GameSessionStatus.active,
}) {
  final base = fixtureSnapshot();
  return RoomSnapshot(
    room: Room(
      id: base.room.id,
      name: base.room.name,
      ownerId: ownerId,
      gameType: base.room.gameType,
      scoringMode: ScoringMode.points,
      createdAt: base.room.createdAt,
      status: status,
      members: [
        for (final id in members)
          _member(id, leftAt: id == ownerId ? ownerLeftAt : null),
      ],
    ),
    sessions: [
      GameSession(
        id: 'session-1',
        roomId: base.room.id,
        name: '第一场',
        status: sessionStatus,
        createdAt: fixtureDate,
        version: 1,
      ),
    ],
    rounds: const [],
    profiles: const {
      ownerId: User(id: ownerId, nickname: '房主'),
      memberId: User(id: memberId, nickname: '成员'),
      thirdId: User(id: thirdId, nickname: '牌友三'),
    },
  );
}

void main() {
  late AppDatabase database;
  late SyncQueue queue;
  late FakeRoomRepository repository;
  late RoomController controller;
  late SupabaseSyncQueue remote;
  var id = 0;

  Future<void> startWith(RoomSnapshot snapshot) async {
    repository.snapshot = snapshot;
    await controller.start();
  }

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    queue = SyncQueue(database, currentActorId: () => ownerId);
    repository = FakeRoomRepository(snapshot: _snapshot());
    remote = SupabaseSyncQueue(
      queue: queue,
      repository: repository,
      cacheForActor: (actor) => LocalRoomCache(database, actorId: actor),
    );
    controller = RoomController(
      roomId: 'room-1',
      actorId: ownerId,
      repository: repository,
      cache: LocalRoomCache(database, actorId: ownerId),
      queue: queue,
      events: FakeRoomEvents(),
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

  test('多人转分只生成一条队列操作，变化为转出总额与各接收人分值', () async {
    await startWith(_snapshot());
    await controller.transferScores('session-1', {memberId: 10, thirdId: 20});
    final round = controller.snapshot!.rounds.single;
    expect(round.note, '多人转分');
    expect(round.changes, hasLength(3));
    expect(
      {for (final change in round.changes) change.playerId: change.value},
      {ownerId: -30, memberId: 10, thirdId: 20},
    );
    final pending = await database.pendingOperations(actorId: ownerId);
    expect(pending, hasLength(1));
    expect(pending.single.operation, 'create');
    final operationId = pending.single.operationId;
    await remote.flush();
    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.expectedVersion, isNull);
    expect(await database.pendingOperations(actorId: ownerId), isEmpty);
    expect((await database.operation(ownerId, operationId))!.status, 'synced');
  });

  test('单人转分沿用同一入口并保留原备注', () async {
    await startWith(_snapshot());
    await controller.transferScores('session-1', {memberId: 15});
    final round = controller.snapshot!.rounds.single;
    expect(round.note, '分数转换');
    expect(
      {for (final change in round.changes) change.playerId: change.value},
      {ownerId: -15, memberId: 15},
    );
  });

  for (final bad in <Map<String, int>>[
    <String, int>{},
    <String, int>{ownerId: 10},
    <String, int>{memberId: 0},
    <String, int>{memberId: -5},
    <String, int>{memberId: 2147483648},
    <String, int>{memberId: 2147483647, thirdId: 1},
  ]) {
    test('转分拒绝无效输入 $bad', () async {
      await startWith(_snapshot());
      await expectLater(
        controller.transferScores('session-1', bad),
        throwsA(isA<AppError>()),
      );
      expect(await database.pendingOperations(actorId: ownerId), isEmpty);
    });
  }

  test('转分拒绝已离开的成员并保留可修正状态', () async {
    await startWith(_snapshot(members: const [ownerId, memberId]));
    await expectLater(
      controller.transferScores('session-1', {thirdId: 10}),
      throwsA(
        isA<AppError>().having((e) => e.kind, 'kind', AppErrorKind.validation),
      ),
    );
    expect(await database.pendingOperations(actorId: ownerId), isEmpty);
  });

  test('提交期间重复动作只执行一次', () async {
    await startWith(_snapshot());
    var runs = 0;
    final pending = Completer<void>();
    final first = controller.runAction(() async {
      runs++;
      await pending.future;
    });
    final second = controller.runAction(() async {
      runs++;
    });
    pending.complete();
    await Future.wait([first, second]);
    expect(runs, 1);
    expect(controller.busy, isFalse);
  });

  test('禁用原因区分房间关闭、无牌局与成员失效', () async {
    await startWith(_snapshot());
    expect(controller.inputDisabledReason('session-1'), isNull);

    await startWith(_snapshot(status: RoomStatus.archived));
    expect(controller.inputDisabledReason('session-1'), '房间已关闭，当前仅可查看记录');

    await startWith(_snapshot(sessionStatus: GameSessionStatus.finished));
    expect(controller.inputDisabledReason('session-1'), '暂无进行中的牌局，请先开始一场');

    await startWith(_snapshot(members: const [memberId, thirdId]));
    expect(controller.inputDisabledReason('session-1'), contains('你已不再是房间成员'));
  });
}
