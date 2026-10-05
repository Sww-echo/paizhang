import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/invite_controller.dart';
import 'package:paizhang/domain/app_error.dart';

import '../support/fakes.dart';

void main() {
  test('相同邀请失败后可重试，成功后重复事件不重复导航', () async {
    final repository = FakeRoomRepository();
    final navigated = <String>[];
    final invites = InviteController(
      repository: repository,
      onRoomReady: (room) => navigated.add(room.id),
    );
    addTearDown(invites.dispose);
    invites.setActor(ownerId);
    repository.onJoin = (_) async =>
        throw const AppError(AppErrorKind.network, '离线');
    invites.receiveToken('test-invite');
    await invites.drain();
    await Future<void>.delayed(Duration.zero);
    expect(invites.canRetry, isTrue);
    expect(navigated, isEmpty);
    repository.onJoin = null;
    await invites.retryFailed();
    await Future<void>.delayed(Duration.zero);
    expect(navigated, ['room-1']);
    invites.receiveToken('test-invite');
    await invites.drain();
    expect(repository.joinCount, 2);
  });

  test('未登录邀请在登录后处理，连续邀请不会等待房间页面关闭', () async {
    final repository = FakeRoomRepository();
    var navigationCount = 0;
    final invites = InviteController(
      repository: repository,
      onRoomReady: (_) => navigationCount++,
    );
    addTearDown(invites.dispose);
    invites.receiveToken('first');
    expect(repository.joinCount, 0);
    invites.setActor(ownerId);
    invites.receiveToken('second');
    await invites.drain();
    await Future<void>.delayed(Duration.zero);
    expect(navigationCount, 2);
  });

  test('账号切换会丢弃旧账号在途邀请的导航结果', () async {
    final repository = FakeRoomRepository();
    final response = Completer<String>();
    repository.onJoin = (_) => response.future;
    var navigationCount = 0;
    final invites = InviteController(
      repository: repository,
      onRoomReady: (_) => navigationCount++,
    );
    addTearDown(invites.dispose);
    invites.setActor(ownerId);
    await invites.drain();
    invites.receiveToken('old-account-invite');
    await Future<void>.delayed(Duration.zero);
    invites.setActor(memberId);
    response.complete('room-1');
    await invites.drain();
    expect(navigationCount, 0);
  });
}
