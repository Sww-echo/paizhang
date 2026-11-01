import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/app_services.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/domain/room_snapshot.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/presentation/design.dart';
import 'package:paizhang/presentation/room_management_page.dart';
import 'package:paizhang/presentation/room_page.dart';
import 'package:paizhang/presentation/score_entry_panel.dart';

import '../support/fakes.dart';

const _thirdId = 'user-3';

RoomSnapshot _twoSessions({List<Round> rounds = const []}) {
  final base = fixtureSnapshot(rounds: rounds);
  return RoomSnapshot(
    room: base.room,
    sessions: [
      ...base.sessions,
      GameSession(
        id: 'session-2',
        roomId: base.room.id,
        name: '第二场',
        createdAt: fixtureDate,
        status: GameSessionStatus.active,
      ),
    ],
    rounds: rounds,
    profiles: base.profiles,
  );
}

AppServices _services(FakeRoomRepository repository) => AppServices(
  database: AppDatabase(NativeDatabase.memory()),
  rooms: repository,
  initialUser: const User(id: ownerId, nickname: '房主'),
  eventsFactory: FakeRoomEvents.new,
  connection: FakeConnection(),
  startSync: false,
);

Future<void> _mount(
  WidgetTester tester,
  AppServices services,
  FakeRoomRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PzTheme.light(),
      home: ConnectedRoomPage(
        services: services,
        room: repository.snapshot.room,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _dispose(WidgetTester tester, AppServices services) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(services.dispose);
}

void _offline(FakeRoomRepository repository) {
  repository.onWrite = (_) async =>
      throw const AppError(AppErrorKind.network, '离线');
}

Future<void> _switchSession(WidgetTester tester, String name) async {
  await _tap(tester, find.byType(DropdownButtonFormField<String>).last);
  await _tap(tester, find.text(name).last);
}

class _ManagementRepository extends FakeRoomRepository {
  Completer<void>? createGate;
  final expectedVersions = <int?>[];

  void _replace({Room? room, List<GameSession>? sessions}) {
    snapshot = RoomSnapshot(
      room: room ?? snapshot.room,
      sessions: sessions ?? snapshot.sessions,
      rounds: snapshot.rounds,
      profiles: snapshot.profiles,
    );
  }

  @override
  Future<Room> setInputPermission({
    required String roomId,
    required InputPermission permission,
  }) async {
    _replace(room: snapshot.room.copyWith(inputPermission: permission));
    return snapshot.room;
  }

  @override
  Future<GameSession> createGameSession({
    required String roomId,
    required String name,
  }) async {
    await createGate?.future;
    final session = GameSession(
      id: 'new-session',
      roomId: roomId,
      name: name,
      createdAt: fixtureDate,
    );
    _replace(sessions: [...snapshot.sessions, session]);
    return session;
  }

  GameSession _update(
    String id,
    int? expectedVersion, {
    GameSessionStatus? status,
    String? name,
  }) {
    final old = snapshot.sessions.singleWhere((session) => session.id == id);
    expect(expectedVersion, old.version);
    expectedVersions.add(expectedVersion);
    final next = GameSession(
      id: old.id,
      roomId: old.roomId,
      name: name ?? old.name,
      createdAt: old.createdAt,
      status: status ?? old.status,
      version: old.version + 1,
    );
    _replace(
      sessions: [
        for (final session in snapshot.sessions)
          session.id == id ? next : session,
      ],
    );
    return next;
  }

  @override
  Future<GameSession> startGameSession(
    String sessionId, {
    int? expectedVersion,
  }) async =>
      _update(sessionId, expectedVersion, status: GameSessionStatus.active);

  @override
  Future<GameSession> finishGameSession(
    String sessionId, {
    int? expectedVersion,
  }) async =>
      _update(sessionId, expectedVersion, status: GameSessionStatus.finished);

  @override
  Future<void> manageGameSession(
    String sessionId,
    String action, {
    String? name,
    int? expectedVersion,
  }) async {
    expect(action, 'rename');
    _update(sessionId, expectedVersion, name: name);
  }
}

void main() {
  testWidgets('取消转分不报成功，保留草稿；保存成功后清理金额', (tester) async {
    final repository = FakeRoomRepository();
    _offline(repository);
    final services = _services(repository);
    try {
      await _mount(tester, services, repository);
      await _tap(tester, find.text('成员'));
      await _tap(tester, find.text('20'));
      await _tap(tester, find.text('取消'));
      expect(find.text('转分已保存到本机 · 待同步'), findsNothing);
      expect(
        await services.database.pendingOperations(actorId: ownerId),
        isEmpty,
      );
      await _tap(tester, find.text('成员'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '20',
      );
      await _tap(tester, find.text('确认转分'));
      expect(
        await services.database.pendingOperations(actorId: ownerId),
        hasLength(1),
      );
      await _tap(tester, find.text('成员'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    } finally {
      await _dispose(tester, services);
    }
  });

  for (final mode in ScoreEntryMode.values) {
    testWidgets('$mode 保存 B 只清理 B，保留 A 的未提交输入', (tester) async {
      final repository = FakeRoomRepository(snapshot: _twoSessions());
      _offline(repository);
      final services = _services(repository);
      final label = mode == ScoreEntryMode.full ? '记一局' : '多人转分';
      final key = ValueKey(
        mode == ScoreEntryMode.full
            ? 'full-$ownerId'
            : 'transfer-amount-$memberId',
      );
      Future<void> enter(String amount) async {
        if (mode == ScoreEntryMode.multi) {
          await _tap(tester, find.byKey(const ValueKey('recipient-$memberId')));
        }
        await tester.enterText(find.byKey(key), amount);
        await tester.pumpAndSettle();
      }

      try {
        await _mount(tester, services, repository);
        await _tap(tester, find.text(label));
        await enter('10');
        await _switchSession(tester, '第二场');
        await enter('20');
        await _tap(tester, find.text('核对'));
        await _tap(tester, find.text('确认保存'));
        expect(repository.writes.single.round.sessionId, 'session-2');
        await _tap(tester, find.text(label));
        expect(
          tester.widget<TextField>(find.byKey(key)).controller!.text,
          '10',
        );
        await _switchSession(tester, '第二场');
        expect(
          tester.widget<TextField>(find.byKey(key)).controller!.text,
          isEmpty,
        );
      } finally {
        await _dispose(tester, services);
      }
    });
  }

  for (final hasMemberMetadata in [true, false]) {
    testWidgets('编辑锁定原牌局，并保留离开成员（成员资料：$hasMemberMetadata）', (tester) async {
      final base = _twoSessions(rounds: [fixtureRound()]);
      final repository = FakeRoomRepository(
        snapshot: RoomSnapshot(
          room: base.room.copyWith(
            members: [
              base.room.members.first,
              if (hasMemberMetadata)
                base.room.members.last.copyWith(leftAt: fixtureDate),
              RoomMember(
                userId: _thirdId,
                role: RoomRole.member,
                joinedAt: fixtureDate,
              ),
            ],
          ),
          sessions: base.sessions,
          rounds: base.rounds,
          profiles: {
            ...base.profiles,
            _thirdId: const User(id: _thirdId, nickname: '牌友三'),
          },
        ),
      );
      _offline(repository);
      final services = _services(repository);
      try {
        await _mount(tester, services, repository);
        await _tap(tester, find.byTooltip('管理'));
        expect(tester.takeException(), isNull);
        await _tap(tester, find.text('历史').first);
        await _tap(tester, find.text('编辑'));
        final panel = tester.widget<ScoreEntryPanel>(
          find.byType(ScoreEntryPanel),
        );
        expect(panel.sessions.single.id, 'session-1');
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        final departed = tester.widget<TextField>(
          find.byKey(const ValueKey('full-$memberId')),
        );
        expect(departed.readOnly, isTrue);
        expect(departed.controller!.text, '-10');
        await tester.enterText(
          find.byKey(const ValueKey('full-$ownerId')),
          '30',
        );
        await tester.enterText(
          find.byKey(const ValueKey('full-$_thirdId')),
          '-20',
        );
        await tester.pumpAndSettle();
        await _tap(tester, find.text('核对'));
        expect(find.text('预计累计 +30'), findsOneWidget);
        expect(find.text('预计累计 −10'), findsOneWidget);
        expect(find.text('预计累计 −20'), findsOneWidget);
        await _tap(tester, find.text('确认保存'));
        final mutation = repository.writes.single;
        expect(mutation.operation, 'update');
        expect(mutation.round.sessionId, 'session-1');
        expect(
          {for (final c in mutation.round.changes) c.playerId: c.value},
          {ownerId: 30, memberId: -10, _thirdId: -20},
        );
      } finally {
        await _dispose(tester, services);
      }
    });
  }

  testWidgets('管理页更新权限和牌局，操作中禁用，连续操作使用新版本', (tester) async {
    final repository = _ManagementRepository();
    final services = _services(repository);
    RoomManagementPage page() => tester.widget(find.byType(RoomManagementPage));
    Finder card(String name) =>
        find.byWidgetPredicate((w) => w is PzBoard && w.title == name);
    try {
      await _mount(tester, services, repository);
      await _tap(tester, find.byTooltip('管理'));
      expect(tester.takeException(), isNull);
      await _tap(tester, find.text('录入权限'));
      await _tap(
        tester,
        find.descendant(of: find.byType(Dialog), matching: find.text('仅房主')),
      );
      expect(page().room.inputPermission, InputPermission.ownerOnly);
      repository.createGate = Completer<void>();
      await _tap(tester, find.text('新建牌局'));
      await tester.enterText(find.byType(TextField), '新牌局');
      await _tap(tester, find.text('创建'));
      expect(page().busy, isTrue);
      expect(find.text('新建牌局'), findsNothing);
      repository.createGate!.complete();
      await tester.pumpAndSettle();
      expect(page().busy, isFalse);
      expect(page().sessions.any((s) => s.name == '新牌局'), isTrue);
      await _tap(
        tester,
        find.descendant(of: card('新牌局'), matching: find.text('开始')),
      );
      expect(
        page().sessions.singleWhere((s) => s.id == 'new-session').status,
        GameSessionStatus.active,
      );
      await _tap(
        tester,
        find.descendant(of: card('新牌局'), matching: find.text('重命名')),
      );
      await tester.enterText(find.byType(TextField), '改名牌局');
      await _tap(tester, find.text('保存'));
      expect(
        page().sessions.singleWhere((s) => s.id == 'new-session').version,
        3,
      );
      await _tap(
        tester,
        find.descendant(of: card('改名牌局'), matching: find.text('结束')),
      );
      await _tap(tester, find.text('结束牌局'));
      expect(
        page().sessions.singleWhere((s) => s.id == 'new-session').status,
        GameSessionStatus.finished,
      );
      expect(repository.expectedVersions, [1, 2, 3]);
      expect(tester.takeException(), isNull);
    } finally {
      await _dispose(tester, services);
    }
  });

  testWidgets('撤销后从提示条恢复用最新版本，不产生版本冲突', (tester) async {
    final repository = FakeRoomRepository(
      snapshot: fixtureSnapshot(rounds: [fixtureRound()]),
    );
    final services = _services(repository);
    try {
      await _mount(tester, services, repository);
      await _tap(tester, find.byTooltip('管理'));
      await _tap(tester, find.text('历史'));
      await _tap(tester, find.text('撤销'));
      await _tap(
        tester,
        find.descendant(of: find.byType(Dialog), matching: find.text('撤销')),
      );
      expect(find.text('已撤销第 1 回合'), findsOneWidget);
      expect(find.text('已撤销'), findsOneWidget);

      // 提示条里的「恢复」捕获的是删除前的旧回合，必须自行取最新版本再写。
      await _tap(
        tester,
        find.descendant(of: find.byType(SnackBar), matching: find.text('恢复')),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('版本冲突'), findsNothing);
      expect(
        [for (final write in repository.writes) write.expectedVersion],
        [1, 2],
        reason: '撤销以 v1 为底，恢复必须以撤销后的 v2 为底，否则服务端必然 40001',
      );
      expect(repository.snapshot.rounds.single.deletedAt, isNull);
    } finally {
      await _dispose(tester, services);
    }
  });
}
