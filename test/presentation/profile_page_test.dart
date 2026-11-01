import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/app_services.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/presentation/profile_page.dart';

import '../support/fakes.dart';

class _ProfileAuth extends FakeAuth {
  _ProfileAuth()
    : super(
        user: const User(id: ownerId, nickname: '房主', avatarKey: 'preset:leaf'),
      );

  bool failNickname = false;
  bool failAvatar = false;
  int nicknameCalls = 0;
  int avatarCalls = 0;
  int clearCalls = 0;
  final previousAvatarKeys = <String?>[];
  Completer<void>? nicknameGate;

  @override
  Future<void> updateNickname({required String nickname}) async {
    nicknameCalls++;
    await nicknameGate?.future;
    if (failNickname) {
      throw const AppError(AppErrorKind.network, '昵称保存失败');
    }
    setUser(
      User(
        id: ownerId,
        nickname: nickname,
        avatarKey: currentUser!.avatarKey,
        avatarUrl: currentUser!.avatarUrl,
      ),
    );
  }

  @override
  Future<void> updateAvatar({
    required String avatarKey,
    String? avatarUrl,
    String? previousAvatarKey,
    String? previousAvatarUrl,
  }) async {
    avatarCalls++;
    previousAvatarKeys.add(previousAvatarKey);
    if (failAvatar) {
      throw const AppError(AppErrorKind.network, '头像保存失败');
    }
    setUser(
      User(
        id: ownerId,
        nickname: currentUser!.nickname,
        avatarKey: avatarKey,
        avatarUrl: avatarUrl,
      ),
    );
  }

  @override
  Future<void> clearAvatar({
    String? previousAvatarKey,
    String? previousAvatarUrl,
  }) async {
    clearCalls++;
    setUser(User(id: ownerId, nickname: currentUser!.nickname));
  }
}

class _ProfileRepository extends FakeRoomRepository {
  final removedKeys = <String?>[];
  @override
  Future<void> removeAvatarFile(String? key) async => removedKeys.add(key);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late _ProfileAuth auth;
  late _ProfileRepository repository;
  late AppServices services;

  setUp(() {
    auth = _ProfileAuth();
    repository = _ProfileRepository();
    services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      rooms: repository,
      auth: auth,
      initialUser: auth.currentUser,
      eventsFactory: FakeRoomEvents.new,
      connection: FakeConnection(),
      startSync: false,
    );
  });

  void testProfile(
    String description,
    Future<void> Function(WidgetTester) body,
  ) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        if (auth.nicknameGate != null && !auth.nicknameGate!.isCompleted) {
          auth.nicknameGate!.complete();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(services.dispose);
        await auth.changes.close();
      }
    });
  }

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: ConnectedProfilePage(services: services)),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('编辑'));
    await tester.enterText(find.byType(TextField), '新昵称');
  }

  Future<void> selectAvatar(WidgetTester tester, String emoji) async {
    await _tap(tester, find.text('选择预设'));
    await _tap(tester, find.text(emoji));
  }

  for (final nicknameFails in [true, false]) {
    testProfile('资料部分成功，仅重试失败项（昵称失败：$nicknameFails）', (tester) async {
      auth.failNickname = nicknameFails;
      auth.failAvatar = !nicknameFails;
      await open(tester);
      await selectAvatar(tester, '☀️');
      await _tap(tester, find.text('保存'));
      expect(
        find.text(
          nicknameFails ? '头像已保存，昵称未保存；请重试未成功项。' : '昵称已保存，头像未保存；请重试未成功项。',
        ),
        findsOneWidget,
      );
      auth.failNickname = false;
      auth.failAvatar = false;
      await _tap(tester, find.text('保存'));
      expect(auth.nicknameCalls, nicknameFails ? 2 : 1);
      expect(auth.avatarCalls, nicknameFails ? 1 : 2);
      expect(find.byType(EditProfilePage), findsNothing);
      expect(find.text('新昵称'), findsOneWidget);
      expect(repository.removedKeys, ['preset:leaf']);
    });
  }

  testProfile('移除头像成功后，重试昵称不会再次清空或删除头像', (tester) async {
    auth.failNickname = true;
    await open(tester);
    await _tap(tester, find.text('移除头像'));
    await _tap(tester, find.text('保存'));
    auth.failNickname = false;
    await _tap(tester, find.text('保存'));
    expect(auth.clearCalls, 1);
    expect(repository.removedKeys, ['preset:leaf']);
    expect(auth.currentUser!.avatarKey, isNull);
  });

  testProfile('部分保存后继续选头像，回滚基线使用刚保存的头像', (tester) async {
    auth.failNickname = true;
    await open(tester);
    await selectAvatar(tester, '☀️');
    await _tap(tester, find.text('保存'));
    await selectAvatar(tester, '🌙');
    auth.failNickname = false;
    auth.failAvatar = true;
    await _tap(tester, find.text('保存'));
    expect(auth.previousAvatarKeys, ['preset:leaf', 'preset:sun']);
    expect(auth.currentUser!.avatarKey, 'preset:sun');
    expect(repository.removedKeys, ['preset:leaf']);
  });

  testProfile('部分保存后取消，个人中心仍显示已成功保存的资料', (tester) async {
    auth.failAvatar = true;
    await open(tester);
    await selectAvatar(tester, '☀️');
    await _tap(tester, find.text('保存'));
    await _tap(tester, find.text('取消'));
    expect(find.byType(EditProfilePage), findsNothing);
    expect(find.text('新昵称'), findsOneWidget);
    expect(auth.avatarCalls, 1);
  });

  testProfile('保存中的系统返回不退出编辑页，也不能重复提交', (tester) async {
    auth.nicknameGate = Completer<void>();
    await open(tester);
    await _tap(tester, find.text('保存'));
    final context = tester.element(find.byType(EditProfilePage));
    await Navigator.of(context).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '取消'))
          .onPressed,
      isNull,
    );
    expect(auth.nicknameCalls, 1);
    auth.nicknameGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsNothing);
  });
}
