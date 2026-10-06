import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/application/app_services.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/presentation/auth_pages.dart';
import 'package:paizhang/presentation/home_pages.dart';

import '../support/fakes.dart';

class _PasswordAuth extends FakeAuth {
  _PasswordAuth() {
    setUser(null);
  }

  final registrations = <({String email, String password, String nickname})>[];
  final signIns = <({String email, String password})>[];
  var codeRequests = 0;
  var codeVerifications = 0;
  var establishSession = false;
  AppError? registrationError;
  Completer<void>? registrationPending;
  Completer<void>? profilePending;

  @override
  Future<User> registerWithPassword({
    required String email,
    required String password,
    required String nickname,
  }) async {
    registrations.add((email: email, password: password, nickname: nickname));
    await registrationPending?.future;
    if (registrationError != null) throw registrationError!;
    final user = User(id: ownerId, nickname: nickname, email: email);
    if (establishSession) setUser(user);
    await profilePending?.future;
    return user;
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signIns.add((email: email, password: password));
    if (establishSession) {
      setUser(User(id: ownerId, nickname: '玩家', email: email));
    }
    await profilePending?.future;
  }

  @override
  Future<void> requestCode(String identifier) async => codeRequests++;

  @override
  Future<User> verifyCode({
    required String identifier,
    required String code,
    required String nickname,
  }) async {
    codeVerifications++;
    return User(id: ownerId, nickname: nickname);
  }
}

void main() {
  late _PasswordAuth auth;
  late AppServices services;

  Future<void> mount(WidgetTester tester, {bool gate = false}) async {
    auth = _PasswordAuth();
    services = AppServices(
      database: AppDatabase(NativeDatabase.memory()),
      auth: auth,
      rooms: FakeRoomRepository(),
      connection: FakeConnection(),
      eventsFactory: FakeRoomEvents.new,
      startSync: false,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(services.dispose);
      await auth.changes.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: gate
            ? AuthGate(
                services: services,
                linkStream: const Stream.empty(),
                initialLink: () async => null,
              )
            : SignInPage(services: services),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fill(
    WidgetTester tester, {
    bool registering = false,
    String confirmation = 'Password123',
  }) async {
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'player@example.com',
    );
    if (registering) {
      await tester.enterText(find.byKey(const ValueKey('auth-nickname')), '玩家');
    }
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'Password123',
    );
    if (registering) {
      await tester.enterText(
        find.byKey(const ValueKey('auth-confirm-password')),
        confirmation,
      );
    }
  }

  testWidgets('默认邮箱密码登录，密码遮挡且不请求验证码', (tester) async {
    await mount(tester);
    expect(find.text('邮箱密码登录'), findsOneWidget);
    expect(find.text('获取验证码'), findsNothing);
    final password = tester.widget<TextFormField>(
      find.byKey(const ValueKey('auth-password')),
    );
    expect(password.controller!.text, isEmpty);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('auth-password')),
              matching: find.byType(TextField),
            ),
          )
          .obscureText,
      isTrue,
    );
    await fill(tester);
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(auth.signIns, [
      (email: 'player@example.com', password: 'Password123'),
    ]);
    expect(auth.codeRequests, 0);
    expect(auth.codeVerifications, 0);
  });

  testWidgets('注册校验确认密码，不一致不调用后端', (tester) async {
    await mount(tester);
    await tap(tester, find.text('没有账号？注册'));
    await fill(tester, registering: true, confirmation: 'OtherPassword');
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(find.text('两次输入的密码不一致'), findsOneWidget);
    expect(auth.registrations, isEmpty);
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm-password')),
      'Password123',
    );
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(auth.registrations, [
      (email: 'player@example.com', password: 'Password123', nickname: '玩家'),
    ]);
    expect(auth.codeRequests, 0);
    expect(auth.codeVerifications, 0);
  });

  testWidgets('注册拒绝无效邮箱和短密码，不向后端发送', (tester) async {
    await mount(tester);
    await tap(tester, find.text('没有账号？注册'));
    await fill(tester, registering: true, confirmation: '123');
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'not-email',
    );
    await tester.enterText(find.byKey(const ValueKey('auth-password')), '123');
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(find.text('请输入有效邮箱地址'), findsOneWidget);
    expect(find.text('密码至少需要 6 位'), findsOneWidget);
    expect(auth.registrations, isEmpty);
  });

  testWidgets('注册提交期间禁用重复提交和登录方式切换', (tester) async {
    await mount(tester);
    await tap(tester, find.text('没有账号？注册'));
    await fill(tester, registering: true);
    final pending = Completer<void>();
    auth.registrationPending = pending;
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(auth.registrations, hasLength(1));
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('auth-password-submit')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '已有账号？返回登录'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '使用验证码登录'))
          .onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(auth.registrations, hasLength(1));
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('auth-password-submit')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('注册失败提示原因并保留表单，允许重试', (tester) async {
    await mount(tester);
    await tap(tester, find.text('没有账号？注册'));
    await fill(tester, registering: true);
    auth.registrationError = const AppError(AppErrorKind.network, '网络暂不可用');
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    // The message appears both inline and in the snackbar.
    expect(find.text('网络暂不可用'), findsWidgets);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('auth-email')))
          .controller!
          .text,
      'player@example.com',
    );
    auth.registrationError = null;
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(auth.registrations, hasLength(2));
    ScaffoldMessenger.of(tester.element(find.byType(SignInPage)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.text('网络暂不可用'), findsNothing);
  });

  testWidgets('注册成功由 AuthGate 导航，退出后可用密码再次登录', (tester) async {
    await mount(tester, gate: true);
    auth.establishSession = true;
    await tap(tester, find.text('没有账号？注册'));
    await fill(tester, registering: true);
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(find.byType(SignInPage), findsNothing);
    expect(find.byType(ConnectedHomeShell), findsOneWidget);
    expect(services.currentUser!.id, ownerId);
    await auth.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsOneWidget);
    await fill(tester);
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(find.byType(ConnectedHomeShell), findsOneWidget);
    expect(auth.signIns, hasLength(1));
    expect(auth.codeRequests, 0);
  });

  testWidgets('原验证码入口保留，切回密码登录清理验证码和重发计时器', (tester) async {
    await mount(tester);
    await tap(tester, find.text('使用验证码登录'));
    await tester.enterText(find.byType(TextField).first, 'player@example.com');
    await tap(tester, find.text('获取验证码'));
    expect(auth.codeRequests, 1);
    expect(find.text('验证码'), findsOneWidget);
    await tap(tester, find.text('返回密码登录'));
    expect(find.text('邮箱密码登录'), findsOneWidget);
    expect(find.text('验证码'), findsNothing);
    await tester.pump(const Duration(seconds: 61));
    expect(tester.takeException(), isNull);
  });

  for (final registering in [false, true]) {
    testWidgets('密码认证成功后在资料同步完成前保存凭据 $registering', (tester) async {
      await mount(tester, gate: true);
      auth.establishSession = true;
      final profilePending = Completer<void>();
      auth.profilePending = profilePending;
      addTearDown(() {
        if (!profilePending.isCompleted) profilePending.complete();
      });
      if (registering) await tap(tester, find.text('没有账号？注册'));
      await fill(tester, registering: registering);
      tester.testTextInput.log.clear();

      await tester.ensureVisible(
        find.byKey(const ValueKey('auth-password-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('auth-password-submit')));
      await tester.pump();
      final finishing = tester.testTextInput.log
          .where((call) => call.method == 'TextInput.finishAutofillContext')
          .toList();
      expect(finishing, isNotEmpty);
      expect(finishing.first.arguments, isTrue);
      expect(finishing.where((call) => call.arguments == true), hasLength(1));
      expect(profilePending.isCompleted, isFalse);
      expect(find.byType(SignInPage), findsNothing);
      expect(find.byType(ConnectedHomeShell), findsOneWidget);

      profilePending.complete();
      await tester.pumpAndSettle();
      expect(
        tester.testTextInput.log.where(
          (call) =>
              call.method == 'TextInput.finishAutofillContext' &&
              call.arguments == true,
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('密码认证失败不会请求保存密码', (tester) async {
    await mount(tester);
    await tap(tester, find.text('没有账号？注册'));
    await fill(tester, registering: true);
    auth.registrationError = const AppError(AppErrorKind.validation, '注册失败');
    tester.testTextInput.log.clear();
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    expect(
      tester.testTextInput.log.where(
        (call) =>
            call.method == 'TextInput.finishAutofillContext' &&
            call.arguments == true,
      ),
      isEmpty,
    );
    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets('其他账号登录不会保存当前表单的密码', (tester) async {
    await mount(tester);
    await fill(tester);
    final profilePending = Completer<void>();
    auth.profilePending = profilePending;
    addTearDown(() {
      if (!profilePending.isCompleted) profilePending.complete();
    });
    tester.testTextInput.log.clear();
    await tap(tester, find.byKey(const ValueKey('auth-password-submit')));
    auth.setUser(
      const User(id: memberId, nickname: '其他账号', email: 'other@example.com'),
    );
    await tester.pump();
    expect(
      tester.testTextInput.log.where(
        (call) =>
            call.method == 'TextInput.finishAutofillContext' &&
            call.arguments == true,
      ),
      isEmpty,
    );
    profilePending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
