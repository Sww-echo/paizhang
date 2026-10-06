import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/app_services.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/invite_service.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/presentation/auth_pages.dart';
import 'package:paizhang/presentation/history_pages.dart';
import 'package:paizhang/presentation/room_page.dart';
import 'package:paizhang/presentation/settlement_page.dart';

import '../support/fakes.dart';

void main() {
  AppServices servicesFor(FakeRoomRepository repository, {FakeAuth? auth}) =>
      AppServices(
        database: AppDatabase(NativeDatabase.memory()),
        rooms: repository,
        auth: auth,
        initialUser:
            auth?.currentUser ?? const User(id: ownerId, nickname: '房主'),
        eventsFactory: FakeRoomEvents.new,
        connection: FakeConnection(),
        startSync: false,
      );

  testWidgets('正式房间页面的录入确认接入本地队列并显示待同步状态', (tester) async {
    final repository = FakeRoomRepository();
    repository.onWrite = (_) async =>
        throw const AppError(AppErrorKind.network, '离线');
    final services = servicesFor(repository);
    try {
      debugPrint('checkpoint: mount room');
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectedRoomPage(
            services: services,
            room: repository.snapshot.room,
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('checkpoint: room ready');
      expect(repository.fetchCount, 1);
      await tester.ensureVisible(find.text('录入一局'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('录入一局'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '12');
      await tester.enterText(find.byType(TextField).at(1), '-12');
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();
      expect(find.text('确认提交'), findsNWidgets(2));
      await tester.tap(find.widgetWithText(FilledButton, '确认提交'));
      debugPrint('checkpoint: confirmed');
      await tester.pumpAndSettle();
      debugPrint('checkpoint: confirmed settled');
      // The status panel scrolls with the list; return to the top before
      // asserting it is shown.
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.textContaining('条本地修改待同步'), findsOneWidget);
      expect(
        await services.database.pendingOperations(actorId: ownerId),
        hasLength(1),
      );
      expect(repository.writes, hasLength(1));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      debugPrint('checkpoint: dispose services');
      await tester.runAsync(services.dispose);
      debugPrint('checkpoint: disposed');
    }
  });

  testWidgets('历史页只加载摘要，展开和查看结算才请求明细', (tester) async {
    final repository = FakeRoomRepository(
      snapshot: fixtureSnapshot(rounds: [fixtureRound()]),
    );
    final services = servicesFor(repository);
    try {
      await tester.pumpWidget(
        MaterialApp(home: ConnectedHistoryPage(services: services)),
      );
      await tester.pumpAndSettle();
      expect(repository.historyRoomCalls, 1);
      expect(repository.historySessionCalls, 0);
      expect(repository.historyDetailCalls, 0);
      await tester.tap(find.text('测试房间'));
      await tester.pumpAndSettle();
      expect(repository.historySessionCalls, 1);
      expect(repository.historyDetailCalls, 0);
      await tester.tap(find.text('第一场'));
      await tester.pumpAndSettle();
      expect(repository.historyDetailCalls, 1);
      expect(find.byType(SettlementPage), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      debugPrint('checkpoint: dispose services');
      await tester.runAsync(services.dispose);
      debugPrint('checkpoint: disposed');
    }
  });

  testWidgets('退出账号销毁旧房间路由，新账号不继承旧导航状态', (tester) async {
    final repository = FakeRoomRepository();
    final auth = FakeAuth();
    final services = servicesFor(repository, auth: auth);
    final links = StreamController<Uri>.broadcast(sync: true);
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            services: services,
            linkStream: links.stream,
            initialLink: () async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      links.add(Uri.parse(const InviteService().createWebLink('test-token')));
      await tester.pumpAndSettle();
      expect(find.byType(ConnectedRoomPage), findsOneWidget);
      auth.setUser(null);
      await tester.pumpAndSettle();
      expect(find.byType(ConnectedRoomPage), findsNothing);
      expect(find.byType(SignInPage), findsOneWidget);
      auth.setUser(const User(id: memberId, nickname: '成员'));
      repository.actor = memberId;
      await tester.pumpAndSettle();
      expect(find.byType(ConnectedRoomPage), findsNothing);
      expect(find.byType(SignInPage), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      debugPrint('checkpoint: dispose services');
      await tester.runAsync(services.dispose);
      debugPrint('checkpoint: disposed');
      await auth.changes.close();
      await links.close();
    }
  });
}
