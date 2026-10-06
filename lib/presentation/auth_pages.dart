import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

enum _SignInMode { password, register, code }

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
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  _SignInMode _mode = _SignInMode.password;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  final _scrollController = ScrollController();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _codeRequested = false;
  bool _busy = false;
  String? _passwordAutofillEmail;
  String? _message;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    widget.services.session.addListener(_commitPasswordAutofill);
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
    widget.services.session.removeListener(_commitPasswordAutofill);
    _resendTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _scrollController.dispose();
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

  void _changeMode(_SignInMode mode) {
    if (_busy) return;
    _resendTimer?.cancel();
    setState(() {
      _mode = mode;
      _passwordFormKey = GlobalKey<FormState>();
      _codeRequested = false;
      _resendSeconds = 0;
      _codeController.clear();
      _passwordController.clear();
      _confirmationController.clear();
      _hidePassword = true;
      _hideConfirmation = true;
      _message = null;
    });
  }

  void _commitPasswordAutofill() {
    if (!mounted) return;
    final expectedEmail = _passwordAutofillEmail;
    if (expectedEmail == null ||
        widget.services.currentUser?.email?.trim().toLowerCase() !=
            expectedEmail) {
      return;
    }
    _passwordAutofillEmail = null;
    TextInput.finishAutofillContext();
  }

  Future<void> _submitPassword() async {
    if (_busy) return;
    if (_passwordFormKey.currentState?.validate() != true) {
      FocusScope.of(context).unfocus();
      _showAuthError('请检查标红的输入项');
      await _scrollToTop();
      return;
    }
    await _run(() async {
      _passwordAutofillEmail = _identifierController.text.trim().toLowerCase();
      try {
        if (_mode == _SignInMode.register) {
          await widget.services.auth!.registerWithPassword(
            email: _identifierController.text,
            password: _passwordController.text,
            nickname: _nicknameController.text,
          );
        } else {
          await widget.services.auth!.signInWithPassword(
            email: _identifierController.text,
            password: _passwordController.text,
          );
        }
        _commitPasswordAutofill();
      } finally {
        _passwordAutofillEmail = null;
      }
    });
  }

  Widget _buildPasswordForm() {
    final registering = _mode == _SignInMode.register;
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const ValueKey('auth-email'),
              controller: _identifierController,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return '请输入邮箱';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return '请输入有效邮箱地址';
                }
                return null;
              },
            ),
            if (registering) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('auth-nickname'),
                controller: _nicknameController,
                enabled: !_busy,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.nickname],
                decoration: const InputDecoration(
                  labelText: '昵称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final nickname = value?.trim() ?? '';
                  if (nickname.isEmpty) return '请输入昵称';
                  if (nickname.length > 40) return '昵称不能超过 40 个字符';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('auth-password'),
              controller: _passwordController,
              enabled: !_busy,
              obscureText: _hidePassword,
              enableSuggestions: false,
              autocorrect: false,
              textInputAction: registering
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: [
                registering
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              decoration: InputDecoration(
                labelText: '密码',
                helperText: registering ? '至少 6 位，请妥善保存密码' : null,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _hidePassword = !_hidePassword),
                  tooltip: _hidePassword ? '显示密码' : '隐藏密码',
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return '请输入密码';
                if (registering && value.length < 6) return '密码至少需要 6 位';
                return null;
              },
              onFieldSubmitted: registering ? null : (_) => _submitPassword(),
            ),
            if (registering) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('auth-confirm-password'),
                controller: _confirmationController,
                enabled: !_busy,
                obscureText: _hideConfirmation,
                enableSuggestions: false,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: '确认密码',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _busy
                        ? null
                        : () => setState(
                            () => _hideConfirmation = !_hideConfirmation,
                          ),
                    tooltip: _hideConfirmation ? '显示确认密码' : '隐藏确认密码',
                    icon: Icon(
                      _hideConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value != _passwordController.text
                    ? '两次输入的密码不一致'
                    : value == null || value.isEmpty
                    ? '请再次输入密码'
                    : null,
                onFieldSubmitted: (_) => _submitPassword(),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: const ValueKey('auth-password-submit'),
              onPressed: _busy ? null : _submitPassword,
              child: Text(
                _busy
                    ? '正在提交…'
                    : registering
                    ? '注册并登录'
                    : '登录',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _changeMode(
                      registering ? _SignInMode.password : _SignInMode.register,
                    ),
              child: Text(registering ? '已有账号？返回登录' : '没有账号？注册'),
            ),
          ],
        ),
      ),
    );
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
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final message = mapAppError(error).message;
      setState(() => _message = message);
      _showAuthError(message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAuthError(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
      );
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            controller: _scrollController,
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
                      if (_mode != _SignInMode.code) ...[
                        Text(
                          _mode == _SignInMode.register ? '邮箱密码注册' : '邮箱密码登录',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordForm(),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _changeMode(_SignInMode.code),
                          child: const Text('使用验证码登录'),
                        ),
                      ] else ...[
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
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _changeMode(_SignInMode.password),
                          child: const Text('返回密码登录'),
                        ),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
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
