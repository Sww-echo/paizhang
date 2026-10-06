import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/app_services.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/presentation/home_pages.dart';

import '../support/fakes.dart';

class _RoomsRepository extends FakeRoomRepository {
  _RoomsRepository(this.rooms);

  final List<Room> rooms;
  int listCalls = 0;
  Future<List<Room>> Function()? onLoad;

  @override
  Future<List<Room>> listMyRooms() async {
    listCalls++;
    return onLoad == null ? rooms : await onLoad!();
  }
}

Room _room(String id, String name, RoomStatus status) => Room(
  id: id,
  name: name,
  ownerId: ownerId,
  gameType: '掼蛋',
  scoringMode: ScoringMode.points,
  createdAt: fixtureDate,
  status: status,
  members: [
    RoomMember(userId: ownerId, role: RoomRole.owner, joinedAt: fixtureDate),
  ],
);

void main() {
  testWidgets('首页展示最多三个进行中房间，冷启动只请求一次', (tester) async {
    final repository = _RoomsRepository([
      _room('room-1', '一号房', RoomStatus.active),
      _room('room-2', '二号房', RoomStatus.waiting),
      _room('room-3', '三号房', RoomStatus.active),
      _room('room-4', '四号房', RoomStatus.active),
      _room('room-5', '已归档房', RoomStatus.archived),
    ]);
    final services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      rooms: repository,
      initialUser: const User(id: ownerId, nickname: '房主'),
      eventsFactory: FakeRoomEvents.new,
      connection: FakeConnection(),
      startSync: false,
    );
    try {
      await tester.pumpWidget(
        MaterialApp(home: ConnectedHomeShell(services: services)),
      );
      await tester.pumpAndSettle();

      expect(repository.listCalls, 1);
      expect(find.text('进行中的房间'), findsOneWidget);
      expect(find.text('真实数据已启用'), findsNothing);
      expect(find.text('一号房'), findsOneWidget);
      expect(find.text('二号房'), findsOneWidget);
      expect(find.text('三号房'), findsOneWidget);
      expect(find.text('四号房'), findsNothing);
      expect(find.text('已归档房'), findsNothing);
      expect(find.text('还有 1 个房间'), findsOneWidget);

      await tester.tap(find.text('全部房间'));
      await tester.pumpAndSettle();
      expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
      expect(repository.listCalls, 1);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(services.dispose);
    }
  });

  testWidgets('没有进行中房间时展示创建与加入引导', (tester) async {
    final repository = _RoomsRepository([
      _room('room-1', '已归档房', RoomStatus.archived),
    ]);
    final services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      rooms: repository,
      initialUser: const User(id: ownerId, nickname: '房主'),
      eventsFactory: FakeRoomEvents.new,
      connection: FakeConnection(),
      startSync: false,
    );
    try {
      await tester.pumpWidget(
        MaterialApp(home: ConnectedHomeShell(services: services)),
      );
      await tester.pumpAndSettle();
      expect(find.text('还没有进行中的房间'), findsOneWidget);
      expect(find.text('创建房间'), findsWidgets);
      expect(find.text('加入房间'), findsWidgets);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(services.dispose);
    }
  });

  testWidgets('首页及时展示加载、失败与重试恢复且没有未处理异常', (tester) async {
    final started = Completer<void>();
    final response = Completer<List<Room>>();
    final repository = _RoomsRepository([])
      ..onLoad = () {
        started.complete();
        return response.future;
      };
    final services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      rooms: repository,
      initialUser: const User(id: ownerId, nickname: '房主'),
      eventsFactory: FakeRoomEvents.new,
      connection: FakeConnection(),
      startSync: false,
    );
    try {
      await tester.pumpWidget(
        MaterialApp(home: ConnectedHomeShell(services: services)),
      );
      await tester.runAsync(() => started.future);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('还没有进行中的房间'), findsNothing);

      response.completeError(const AppError(AppErrorKind.network, '读取房间失败'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('读取房间失败'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('还没有进行中的房间'), findsNothing);

      repository.onLoad = () async => [
        _room('room-1', '恢复后的房间', RoomStatus.active),
      ];
      await tester.ensureVisible(find.byIcon(Icons.refresh_rounded));
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();
      expect(repository.listCalls, 2);
      expect(find.text('恢复后的房间'), findsOneWidget);
      expect(find.text('加载失败'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(services.dispose);
    }
  });
}
