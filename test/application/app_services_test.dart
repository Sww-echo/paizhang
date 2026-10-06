import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/app_services.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';

import '../support/fakes.dart';

class _ControlledRoomsRepository extends FakeRoomRepository {
  _ControlledRoomsRepository(this.onList);

  final Future<List<Room>> Function() onList;

  @override
  Future<List<Room>> listMyRooms() => onList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('同一账号资料更新会同步到全局会话', () async {
    final auth = FakeAuth();
    final services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      rooms: FakeRoomRepository(),
      auth: auth,
      initialUser: auth.currentUser,
      eventsFactory: FakeRoomEvents.new,
      connection: FakeConnection(),
      startSync: false,
    );
    try {
      expect(services.currentUser!.nickname, '房主');
      auth.setUser(
        const User(id: ownerId, nickname: '新昵称', avatarKey: 'preset:sun'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(services.currentUser!.nickname, '新昵称');
      expect(services.currentUser!.avatarKey, 'preset:sun');
    } finally {
      await services.dispose();
    }
  });

  test('同一账号并发加载共享同一个完整请求', () async {
    final started = Completer<void>();
    final response = Completer<List<Room>>();
    var calls = 0;
    final repository = _ControlledRoomsRepository(() {
      calls++;
      started.complete();
      return response.future;
    });
    final services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      rooms: repository,
      initialUser: const User(id: ownerId, nickname: '房主'),
      connection: FakeConnection(),
      startSync: false,
    );
    try {
      final first = services.loadRooms();
      final second = services.loadRooms();
      expect(identical(first, second), isTrue);
      await started.future;
      response.complete([fixtureSnapshot().room]);
      expect(await first, hasLength(1));
      expect(await second, hasLength(1));
      expect(calls, 1);
      expect(services.roomsLoading.value, isFalse);
    } finally {
      await services.dispose();
    }
  });

  for (final nextActor in [memberId, ownerId]) {
    test('账号切换或重新登录 $nextActor 后不复用旧房间请求', () async {
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();
      final firstResponse = Completer<List<Room>>();
      final secondResponse = Completer<List<Room>>();
      var calls = 0;
      final repository = _ControlledRoomsRepository(() {
        calls++;
        if (calls == 1) {
          firstStarted.complete();
          return firstResponse.future;
        }
        if (calls == 2) {
          secondStarted.complete();
          return secondResponse.future;
        }
        throw StateError('旧账号的排队刷新不应影响新会话');
      });
      final auth = FakeAuth();
      final services = AppServices(
        database: AppDatabase(NativeDatabase.memory()),
        rooms: repository,
        auth: auth,
        connection: FakeConnection(),
        startSync: false,
      );
      try {
        final stale = services.loadRooms();
        final staleResult = expectLater(
          stale,
          throwsA(
            isA<AppError>().having(
              (error) => error.kind,
              'kind',
              AppErrorKind.sessionChanged,
            ),
          ),
        );
        await firstStarted.future;
        expect(identical(services.loadRooms(force: true), stale), isTrue);
        auth.setUser(null);
        repository.actor = nextActor;
        late Future<List<Room>> fresh;
        services.session.addListener(() {
          if (services.currentUser?.id == nextActor) {
            fresh = services.loadRooms();
          }
        });
        auth.setUser(User(id: nextActor, nickname: '新会话'));
        await secondStarted.future;
        expect(identical(fresh, stale), isFalse);

        firstResponse.complete([fixtureSnapshot().room]);
        await staleResult;
        expect(services.roomList.value, isEmpty);
        expect(services.roomsLoading.value, isTrue);
        expect(services.roomsError.value, isNull);
        expect(identical(services.loadRooms(), fresh), isTrue);

        secondResponse.complete([fixtureSnapshot(roomId: 'room-2').room]);
        expect((await fresh).single.id, 'room-2');
        expect(services.roomList.value.single.id, 'room-2');
        expect(
          (await services.cacheForActor(nextActor).listRooms()).single.id,
          'room-2',
        );
        expect(calls, 2);
      } finally {
        await services.dispose();
        await auth.changes.close();
      }
    });
  }

  test('应用销毁后旧房间请求不会返回数据或更新通知器', () async {
    final started = Completer<void>();
    final response = Completer<List<Room>>();
    final services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      rooms: _ControlledRoomsRepository(() {
        started.complete();
        return response.future;
      }),
      initialUser: const User(id: ownerId, nickname: '房主'),
      connection: FakeConnection(),
      startSync: false,
    );
    final pending = services.loadRooms();
    final result = expectLater(
      pending,
      throwsA(
        isA<AppError>().having(
          (error) => error.kind,
          'kind',
          AppErrorKind.sessionChanged,
        ),
      ),
    );
    await started.future;
    await services.dispose();
    response.complete([fixtureSnapshot().room]);
    await result;
  });
}
