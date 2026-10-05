import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/app_services.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';

import '../support/fakes.dart';

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
}
