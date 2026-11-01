import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/app_services.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/presentation/design.dart';
import 'package:paizhang/presentation/home_pages.dart';
import 'package:paizhang/presentation/profile_page.dart';
import 'package:paizhang/presentation/room_management_page.dart';
import 'package:paizhang/presentation/room_page.dart';
import 'package:paizhang/presentation/round_history_page.dart';
import 'package:paizhang/presentation/score_entry_panel.dart';
import 'package:paizhang/presentation/settlement_page.dart';
import 'package:paizhang/presentation/sync_queue_page.dart';
import 'package:paizhang/presentation/transfer_dialog.dart';

import '../support/fakes.dart';

AppServices _services(FakeRoomRepository repository) => AppServices(
  database: AppDatabase(NativeDatabase.memory()),
  rooms: repository,
  initialUser: const User(id: ownerId, nickname: '房主'),
  eventsFactory: FakeRoomEvents.new,
  connection: FakeConnection(),
  startSync: false,
);

void main() {
  void testWithServices(
    String description,
    Future<void> Function(WidgetTester, FakeRoomRepository, AppServices) body,
  ) {
    testWidgets(description, (tester) async {
      final repository = FakeRoomRepository();
      final services = _services(repository);
      try {
        await body(tester, repository, services);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(services.dispose);
      }
    });
  }

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(390, 844),
    List<double> scales = const [1.0, 1.3],
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final brightness in [Brightness.light, Brightness.dark]) {
      for (final scale in scales) {
        await tester.pumpWidget(
          MaterialApp(
            theme: PzTheme.light(),
            darkTheme: PzTheme.dark(),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: page,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$size $brightness at text scale $scale',
        );
      }
    }
  }

  testWithServices('记分台不报布局错误', (tester, repository, services) async {
    await pumpPage(
      tester,
      ConnectedRoomPage(services: services, room: repository.snapshot.room),
    );
  });

  testWithServices('房间管理页不报布局错误', (tester, repository, services) async {
    final snapshot = repository.snapshot;
    await pumpPage(
      tester,
      RoomManagementPage(
        room: snapshot.room,
        sessions: snapshot.sessions,
        roundCounts: const {'session-1': 3},
        profiles: snapshot.profiles,
        currentUserId: ownerId,
        closeVote: null,
        canManage: true,
        canInput: true,
        readOnly: false,
        hasActiveSession: true,
        busy: false,
        onEditRoom: () async {},
        onPermissionChanged: (_) async {},
        onInvite: () async {},
        onCreateSession: () async {},
        onStartSession: (_) async {},
        onDeleteSession: (_) async {},
        onRenameSession: (_) async {},
        onFinishSession: (_) async {},
        onReopenSession: (_) async {},
        onOpenHistory: (_) async {},
        onOpenSettlement: (_) async {},
        onRecordSession: (_) async {},
        onCastCloseVote: (_, _) async {},
        onCancelCloseVote: () async {},
        onRemoveMember: (_) async {},
        onTransferOwnership: (_) async {},
        onLeaveRoom: () async {},
      ),
    );
  });

  testWithServices('回合记录页不报布局错误', (tester, repository, services) async {
    final snapshot = repository.snapshot;
    await pumpPage(
      tester,
      RoundHistoryPage(
        roomName: snapshot.room.name,
        session: snapshot.sessions.single,
        rounds: [
          fixtureRound(),
          fixtureRound(id: 'round-2', number: 2, value: -5),
        ],
        profiles: snapshot.profiles,
        currentUserId: ownerId,
        canEdit: true,
        onEdit: (_) async {},
        onDelete: (_) async {},
        onRestore: (_) async {},
      ),
    );
  });

  testWithServices('结算页不报布局错误', (tester, repository, services) async {
    final snapshot = repository.snapshot;
    await pumpPage(
      tester,
      SettlementPage(
        room: snapshot.room,
        session: snapshot.sessions.single,
        rounds: [fixtureRound()],
        profiles: snapshot.profiles,
        currentUserId: ownerId,
        pendingCount: 1,
      ),
    );
  });

  testWithServices('最窄 320 宽 + 2.0 倍字号不报布局错误', (
    tester,
    repository,
    services,
  ) async {
    const narrow = Size(320, 568);
    const huge = [2.0];
    final snapshot = repository.snapshot;
    await pumpPage(
      tester,
      SettlementPage(
        room: snapshot.room,
        session: snapshot.sessions.single,
        rounds: [fixtureRound()],
        profiles: snapshot.profiles,
        currentUserId: ownerId,
        pendingCount: 1,
      ),
      size: narrow,
      scales: huge,
    );
    await pumpPage(
      tester,
      RoundHistoryPage(
        roomName: snapshot.room.name,
        session: snapshot.sessions.single,
        rounds: [
          fixtureRound(),
          fixtureRound(id: 'round-2', number: 2, value: -5),
        ],
        profiles: snapshot.profiles,
        currentUserId: ownerId,
        canEdit: true,
        onEdit: (_) async {},
        onDelete: (_) async {},
        onRestore: (_) async {},
      ),
      size: narrow,
      scales: huge,
    );
  });
  testWithServices('同步记录页不报布局错误', (tester, repository, services) async {
    await pumpPage(tester, SyncQueuePage(services: services));
  });

  testWithServices('我的与编辑资料不报布局错误', (tester, repository, services) async {
    await pumpPage(tester, ConnectedProfilePage(services: services));
    await pumpPage(
      tester,
      EditProfilePage(services: services, initialNickname: '房主'),
    );
  });

  testWithServices('首页与房间列表不报布局错误', (tester, repository, services) async {
    await pumpPage(tester, ConnectedHomeShell(services: services));
  });

  testWidgets('整局录入与多人转分面板不报布局错误', (tester) async {
    for (final mode in ScoreEntryMode.values) {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: PzTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => ScoreEntryPanel(
                    mode: mode,
                    actorId: ownerId,
                    roomId: 'room-1',
                    roomName: '测试房间',
                    members: [
                      RoomMember(
                        userId: ownerId,
                        role: RoomRole.owner,
                        joinedAt: fixtureDate,
                      ),
                      RoomMember(
                        userId: memberId,
                        role: RoomRole.member,
                        joinedAt: fixtureDate,
                      ),
                    ],
                    profiles: const {
                      ownerId: User(id: ownerId, nickname: '房主'),
                      memberId: User(id: memberId, nickname: '成员'),
                    },
                    scoringMode: ScoringMode.money,
                    sessions: const [
                      ScoreEntrySession(
                        id: 'session-1',
                        name: '第一场',
                        nextRoundNumber: 4,
                        totals: {ownerId: 30, memberId: -30},
                      ),
                    ],
                    initialSessionId: 'session-1',
                    drafts: ScoreDraftStore(),
                    onSave: (_, _) async {},
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'mode=$mode');
      await tester.tap(find.text('返回记分台'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('转分弹窗不报布局错误', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PzTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => ScoreTransferDialog(
                  actorId: ownerId,
                  toPlayerId: memberId,
                  members: [
                    RoomMember(
                      userId: ownerId,
                      role: RoomRole.owner,
                      joinedAt: fixtureDate,
                    ),
                    RoomMember(
                      userId: memberId,
                      role: RoomRole.member,
                      joinedAt: fixtureDate,
                    ),
                  ],
                  profiles: const {
                    ownerId: User(id: ownerId, nickname: '房主'),
                    memberId: User(id: memberId, nickname: '成员'),
                  },
                  totals: const {ownerId: 30, memberId: -30},
                  scoringMode: ScoringMode.money,
                  roomName: '测试房间',
                  sessionName: '第一场',
                  nextRoundNumber: 4,
                  onSubmit: (_) async {},
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
