import 'package:flutter/material.dart';

import 'dart:collection';

import '../application/app_services.dart';
import '../domain/models.dart';

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../application/invite_controller.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'home_pages.dart';
import 'room_page.dart';

class _PendingRoomNavigation {
  const _PendingRoomNavigation({required this.actorId, required this.room});

  final String actorId;
  final Room room;
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.services,
    this.linkStream,
    this.initialLink,
    super.key,
  });

  final AppServices services;
  final Stream<Uri>? linkStream;
  final Future<Uri?> Function()? initialLink;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final InviteController _invites;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState> _navigationKey = GlobalKey<NavigatorState>();
  String? _actorId;
  final Queue<_PendingRoomNavigation> _pendingRooms = Queue();

  @override
  void initState() {
    super.initState();
    _invites = InviteController(
      repository: widget.services.rooms!,
      onRoomReady: _queueRoomNavigation,
    );
    _invites.addListener(_showInviteError);
    widget.services.session.addListener(_sessionChanged);
    _sessionChanged();
    if (widget.linkStream == null) _appLinks = AppLinks();
    _linkSubscription = (widget.linkStream ?? _appLinks!.uriLinkStream).listen(
      _invites.receiveUri,
      onError: (Object error) {},
    );
    unawaited(_loadInitialLink());
  }

  void _sessionChanged() {
    final actor = widget.services.currentUser?.id;
    if (_actorId != actor) {
      _navigationKey = GlobalKey<NavigatorState>();
      _pendingRooms.clear();
    }
    _actorId = actor;
    _invites.setActor(actor);
  }

  void _queueRoomNavigation(Room room) {
    final actor = widget.services.currentUser?.id;
    if (actor == null) return;
    _pendingRooms.add(_PendingRoomNavigation(actorId: actor, room: room));
    _scheduleRoomNavigation();
  }

  void _scheduleRoomNavigation() {
    WidgetsBinding.instance.scheduleFrame();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingRooms.isEmpty) return;
      final next = _pendingRooms.first;
      if (next.actorId != widget.services.currentUser?.id) {
        _pendingRooms.removeFirst();
        _scheduleRoomNavigation();
        return;
      }
      final navigator = _navigationKey.currentState;
      if (navigator == null) {
        Future<void>.delayed(const Duration(milliseconds: 10), () {
          if (mounted) _scheduleRoomNavigation();
        });
        return;
      }
      _pendingRooms.removeFirst();
      unawaited(
        navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                ConnectedRoomPage(services: widget.services, room: next.room),
          ),
        ),
      );
      if (_pendingRooms.isNotEmpty) _scheduleRoomNavigation();
    });
  }

  Future<void> _loadInitialLink() async {
    if (kIsWeb) _invites.receiveUri(Uri.base);
    try {
      final link =
          await (widget.initialLink?.call() ?? _appLinks?.getInitialLink());
      if (mounted && link != null) _invites.receiveUri(link);
    } catch (_) {}
  }

  void _showInviteError() {
    if (!mounted || _invites.error == null) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_invites.error!.message),
          action: _invites.canRetry
              ? SnackBarAction(
                  label: '重试',
                  onPressed: () => unawaited(_invites.retryFailed()),
                )
              : null,
        ),
      );
  }

  @override
  void dispose() {
    widget.services.session.removeListener(_sessionChanged);
    _invites.dispose();
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<User?>(
    valueListenable: widget.services.session,
    builder: (context, user, _) {
      if (user == null) return SignInPage(services: widget.services);
      return Navigator(
        key: _navigationKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (_) => ConnectedHomeShell(services: widget.services),
        ),
      );
    },
  );
}

class SignInPage extends StatefulWidget {
  const SignInPage({required this.services, super.key});

  final AppServices services;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  static const _demoAccountsEnabled = bool.fromEnvironment(
    'PAIZHANG_ENABLE_DEMO_ACCOUNTS',
  );
  static const _demoAccountOneEmail = 'demo1@paizhang.test';
  static const _demoAccountOnePassword = 'PzDemo-2026-01!';
  static const _demoAccountTwoEmail = 'demo2@paizhang.test';
  static const _demoAccountTwoPassword = 'PzDemo-2026-02!';

  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _codeRequested = false;
  bool _busy = false;
  String? _message;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    final errorCode = Uri.base.queryParameters['error_code'];
    if (errorCode != null) {
      _message = switch (errorCode) {
        'otp_expired' => '验证码或邮件链接已过期，请重新获取最新验证码。',
        'access_denied' => '邮箱验证未完成，请使用最新邮件重新验证。',
        _ => '邮箱验证失败，请重新获取验证码。',
      };
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _identifierController.dispose();
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _requestCode({bool resend = false}) async {
    await _run(() async {
      final identifier = _identifierController.text.trim();
      await widget.services.auth!.requestCode(identifier);
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _message = resend ? '新的验证码已发送，请使用最新验证码' : '验证码已发送，请检查邮箱或短信';
      });
      _startResendTimer();
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  void _changeIdentifier() {
    _resendTimer?.cancel();
    setState(() {
      _codeRequested = false;
      _resendSeconds = 0;
      _codeController.clear();
      _message = null;
    });
  }

  Future<void> _verifyCode() async {
    await _run(() async {
      await widget.services.auth!.verifyCode(
        identifier: _identifierController.text,
        code: _codeController.text,
        nickname: _nicknameController.text,
      );
    });
  }

  Future<void> _signInDemo({required String email, required String password}) {
    return _run(() {
      return widget.services.auth!.signInWithPassword(
        email: email,
        password: password,
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _message = mapAppError(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '牌账',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('登录后，房间和牌局会自动同步。'),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _identifierController,
                        readOnly: _codeRequested,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: '邮箱或手机号',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_codeRequested) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '验证码',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _busy ? null : _changeIdentifier,
                              child: const Text('修改账号'),
                            ),
                            TextButton(
                              onPressed: _busy || _resendSeconds > 0
                                  ? null
                                  : () => _requestCode(resend: true),
                              child: Text(
                                _resendSeconds > 0
                                    ? '重新发送（$_resendSeconds）'
                                    : '重新发送',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            labelText: '昵称',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : (_codeRequested ? _verifyCode : _requestCode),
                        child: Text(_codeRequested ? '登录' : '获取验证码'),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _message!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      if (_demoAccountsEnabled) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          '开发测试账号',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => _signInDemo(
                                        email: _demoAccountOneEmail,
                                        password: _demoAccountOnePassword,
                                      ),
                                child: const Text('演示账号一'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => _signInDemo(
                                        email: _demoAccountTwoEmail,
                                        password: _demoAccountTwoPassword,
                                      ),
                                child: const Text('演示账号二'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
