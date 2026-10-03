import 'dart:async';
import 'dart:ui' as ui;

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../application/app_services.dart';
import '../domain/invite_service.dart';
import '../domain/models.dart';
import '../domain/settlement_calculator.dart';
import '../infrastructure/backend/room_sync_coordinator.dart';
import '../infrastructure/backend/supabase_room_repository.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({required this.services, super.key});

  final AppServices services;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AppLinks _appLinks = AppLinks();
  final Set<String> _handledInviteTokens = <String>{};
  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingInviteToken;
  String? _processingInviteToken;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {},
    );
    unawaited(_loadInitialLink());
  }

  Future<void> _loadInitialLink() async {
    if (kIsWeb) _handleUri(Uri.base);
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handleUri(initialLink);
    } catch (_) {}
  }

  void _handleUri(Uri uri) {
    final token = const InviteService().extractToken(uri.toString());
    if (token == null ||
        _handledInviteTokens.contains(token) ||
        _processingInviteToken == token) {
      return;
    }
    _pendingInviteToken = token;
    _scheduleInviteConsumption();
  }

  void _scheduleInviteConsumption() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_consumePendingInvite());
    });
  }

  Future<void> _consumePendingInvite() async {
    final token = _pendingInviteToken;
    final currentUser = widget.services.client?.auth.currentUser;
    if (token == null ||
        currentUser == null ||
        _processingInviteToken != null) {
      return;
    }

    _pendingInviteToken = null;
    _processingInviteToken = token;
    try {
      final roomId = await widget.services.rooms!.joinByToken(token);
      final room = await widget.services.rooms!.getRoom(roomId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
    } catch (error) {
      _showInviteError(error);
    } finally {
      _handledInviteTokens.add(token);
      _processingInviteToken = null;
    }
  }

  void _showInviteError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  void dispose() {
    unawaited(_linkSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.services.auth;
    final client = widget.services.client;
    if (auth == null || client == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        final user = client.auth.currentUser;
        if (user == null) return SignInPage(services: widget.services);
        _scheduleInviteConsumption();
        return ConnectedHomeShell(services: widget.services);
      },
    );
  }
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
      if (mounted) setState(() => _message = error.toString());
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

class ConnectedHomeShell extends StatefulWidget {
  const ConnectedHomeShell({required this.services, super.key});

  final AppServices services;

  @override
  State<ConnectedHomeShell> createState() => _ConnectedHomeShellState();
}

class _ConnectedHomeShellState extends State<ConnectedHomeShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.services.flushSyncQueue());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.services.flushSyncQueue());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ConnectedHomePage(
        services: widget.services,
        onMessage: _showMessage,
        onRoomsChanged: () => setState(() {}),
      ),
      ConnectedRoomsPage(services: widget.services, onMessage: _showMessage),
      ConnectedProfilePage(services: widget.services),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: '牌局',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: '房间',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class ConnectedHomePage extends StatefulWidget {
  const ConnectedHomePage({
    required this.services,
    required this.onMessage,
    required this.onRoomsChanged,
    super.key,
  });

  final AppServices services;
  final ValueChanged<String> onMessage;
  final VoidCallback onRoomsChanged;

  @override
  State<ConnectedHomePage> createState() => _ConnectedHomePageState();
}

class _ConnectedHomePageState extends State<ConnectedHomePage> {
  bool _busy = false;

  Future<void> _createRoom(BuildContext context) async {
    if (_busy) return;
    final values = await showDialog<_RoomFormValue>(
      context: context,
      builder: (context) => const _RoomFormDialog(),
    );
    if (values == null || !context.mounted) return;
    setState(() => _busy = true);
    try {
      final room = await widget.services.rooms!.createRoom(
        name: values.name,
        gameType: values.gameType,
        scoringMode: values.scoringMode,
      );
      widget.onRoomsChanged();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
    } catch (error) {
      widget.onMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom(BuildContext context) async {
    if (_busy) return;
    final input = await showDialog<String>(
      context: context,
      builder: (context) => const _JoinRoomDialog(),
    );
    if (input == null || !context.mounted) return;
    setState(() => _busy = true);
    try {
      final token = const InviteService().extractToken(input);
      final roomId = token == null
          ? await widget.services.rooms!.joinByCode(input)
          : await widget.services.rooms!.joinByToken(token);
      final room = await widget.services.rooms!.getRoom(roomId);
      widget.onRoomsChanged();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
    } catch (error) {
      widget.onMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openHistory(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConnectedHistoryPage(services: widget.services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.services.client!.auth.currentUser;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      children: [
        Text(
          '晚上好，${user?.userMetadata?['nickname'] ?? user?.email ?? '牌友'}',
          style: const TextStyle(fontSize: 15, color: Color(0xFF6B766F)),
        ),
        const SizedBox(height: 6),
        const Text(
          '今天也把账记清楚。',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _ConnectedActionButton(
                icon: Icons.add_rounded,
                label: '创建房间',
                primary: true,
                onPressed: _busy ? null : () => _createRoom(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ConnectedActionButton(
                icon: Icons.login_rounded,
                label: '加入房间',
                onPressed: _busy ? null : () => _joinRoom(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Text(
          '真实数据已启用',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(Icons.cloud_done_rounded),
            title: Text('Supabase + Drift 同步'),
            subtitle: Text('在线实时更新，离线操作进入同步队列'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openHistory(context),
          icon: const Icon(Icons.history_rounded),
          label: const Text('查看历史记录'),
        ),
      ],
    );
  }
}

class ConnectedRoomsPage extends StatefulWidget {
  const ConnectedRoomsPage({
    required this.services,
    required this.onMessage,
    super.key,
  });

  final AppServices services;
  final ValueChanged<String> onMessage;

  @override
  State<ConnectedRoomsPage> createState() => _ConnectedRoomsPageState();
}

class _ConnectedRoomsPageState extends State<ConnectedRoomsPage> {
  late Future<List<Room>> _roomsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _roomsFuture = widget.services.rooms!.listMyRooms();
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _roomsFuture;
    } catch (error) {
      if (mounted) widget.onMessage(error.toString());
    }
  }

  Future<void> _createRoom() async {
    if (_busy) return;
    final values = await showDialog<_RoomFormValue>(
      context: context,
      builder: (context) => const _RoomFormDialog(),
    );
    if (values == null) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final room = await widget.services.rooms!.createRoom(
        name: values.name,
        gameType: values.gameType,
        scoringMode: values.scoringMode,
      );
      if (!mounted) return;
      setState(_reload);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
      if (mounted) setState(_reload);
    } catch (error) {
      widget.onMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_busy) return;
    final input = await showDialog<String>(
      context: context,
      builder: (context) => const _JoinRoomDialog(),
    );
    if (input == null) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final token = const InviteService().extractToken(input);
      final roomId = token == null
          ? await widget.services.rooms!.joinByCode(input)
          : await widget.services.rooms!.joinByToken(token);
      final room = await widget.services.rooms!.getRoom(roomId);
      if (!mounted) return;
      setState(_reload);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
      if (mounted) setState(_reload);
    } catch (error) {
      widget.onMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            title: Text(
              '我的房间',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: _ConnectedActionButton(
                        icon: Icons.add_rounded,
                        label: '创建房间',
                        primary: true,
                        onPressed: _busy ? null : _createRoom,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ConnectedActionButton(
                        icon: Icons.login_rounded,
                        label: '加入房间',
                        onPressed: _busy ? null : _joinRoom,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<Room>>(
                  future: _roomsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorCard(
                        message: snapshot.error.toString(),
                        onRetry: () => setState(_reload),
                      );
                    }
                    final rooms = snapshot.data ?? const <Room>[];
                    if (rooms.isEmpty) {
                      return const Card(
                        elevation: 0,
                        child: ListTile(
                          leading: Icon(Icons.groups_outlined),
                          title: Text('还没有房间'),
                          subtitle: Text('创建一个房间，开始记录牌局'),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var index = 0; index < rooms.length; index++) ...[
                          _ConnectedRoomTile(
                            room: rooms[index],
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ConnectedRoomPage(
                                    services: widget.services,
                                    room: rooms[index],
                                  ),
                                ),
                              );
                              if (mounted) setState(_reload);
                            },
                          ),
                          if (index != rooms.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectedRoomPage extends StatefulWidget {
  const ConnectedRoomPage({
    required this.services,
    required this.room,
    super.key,
  });

  final AppServices services;
  final Room room;

  @override
  State<ConnectedRoomPage> createState() => _ConnectedRoomPageState();
}

class _ConnectedRoomPageState extends State<ConnectedRoomPage> {
  late Future<RemoteRoomSnapshot> _snapshotFuture;
  late final RoomSyncCoordinator _sync;
  String? _selectedSessionId;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.services.rooms!.getRoomSnapshot(widget.room.id);
    _sync = widget.services.createRoomSyncCoordinator(
      onRefresh: (snapshot) async {
        if (!mounted) return;
        setState(() => _snapshotFuture = Future.value(snapshot));
      },
      onError: (error) async {
        _handleSyncError(error);
      },
    );
    unawaited(_startSync());
  }

  Future<void> _startSync() async {
    try {
      await _sync.start(widget.room.id);
    } catch (error) {
      _handleSyncError(error);
    }
  }

  void _reloadSnapshot() {
    if (!mounted) return;
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  Future<RemoteRoomSnapshot> _loadSnapshot() async {
    final snapshot = await widget.services.rooms!.getRoomSnapshot(
      widget.room.id,
    );
    await widget.services.cache.saveRoomSnapshot(
      room: snapshot.room,
      sessions: snapshot.sessions,
      rounds: snapshot.rounds,
    );
    return snapshot;
  }

  GameSession? _selectedActiveSession(RemoteRoomSnapshot snapshot) {
    for (final session in snapshot.sessions) {
      if (session.id == _selectedSessionId &&
          session.status == GameSessionStatus.active) {
        return session;
      }
    }
    for (final session in snapshot.sessions) {
      if (session.status == GameSessionStatus.active) return session;
    }
    return null;
  }

  bool _canInputRoom(Room room) {
    final currentUserId = widget.services.client?.auth.currentUser?.id;
    if (currentUserId == null ||
        !room.hasActiveMember(currentUserId) ||
        room.isClosed) {
      return false;
    }
    if (room.inputPermission == InputPermission.all) return true;
    return currentUserId == room.ownerId;
  }

  bool _isRoomOwner(Room room) {
    final currentUserId = widget.services.client?.auth.currentUser?.id;
    return currentUserId != null &&
        room.hasActiveMember(currentUserId) &&
        !room.isClosed &&
        currentUserId == room.ownerId;
  }

  Future<void> _runRoomAction(Future<void> Function() action) async {
    if (!mounted || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await action();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  bool _canEditRound(RemoteRoomSnapshot snapshot, Round round) {
    final currentUserId = widget.services.client?.auth.currentUser?.id;
    final session = snapshot.sessions.where(
      (item) => item.id == round.sessionId,
    );
    return currentUserId != null &&
        round.createdBy == currentUserId &&
        session.isNotEmpty &&
        session.first.status == GameSessionStatus.active &&
        _canInputRoom(snapshot.room);
  }

  void _showLocalRound(RemoteRoomSnapshot snapshot, Round round) {
    final rounds = [
      ...snapshot.rounds.where((item) => item.id != round.id),
      round,
    ];
    if (!mounted) return;
    setState(() {
      _snapshotFuture = Future.value(
        RemoteRoomSnapshot(
          room: snapshot.room,
          sessions: snapshot.sessions,
          rounds: List.unmodifiable(rounds),
          profiles: snapshot.profiles,
          closeVote: snapshot.closeVote,
        ),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_sync.stop());
    super.dispose();
  }

  Future<void> _createInvite() async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final snapshot = await _snapshotFuture;
      if (!_isRoomOwner(snapshot.room)) {
        _showError('只有房主可以生成邀请码');
        return;
      }
      final invite = await widget.services.rooms!.createInvite(
        roomId: snapshot.room.id,
        kind: InviteKind.code,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('房间邀请码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('邀请码'),
              const SizedBox(height: 6),
              if (invite.shareLink.isNotEmpty) ...[
                Center(
                  child: QrImageView(
                    data: invite.shareLink,
                    size: 220,
                    backgroundColor: Colors.white,
                    semanticsLabel: '房间邀请二维码',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SelectableText(
                invite.code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text('分享链接'),
              const SizedBox(height: 6),
              SelectableText(invite.shareLink),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: invite.code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('邀请码已复制')));
                }
              },
              child: const Text('复制邀请码'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: invite.shareLink));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('分享链接已复制')));
                }
              },
              child: const Text('复制链接'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _createSession(RemoteRoomSnapshot snapshot) async {
    if (_actionBusy) return;
    if (!_isRoomOwner(snapshot.room)) {
      _showError('只有房主可以创建牌局');
      return;
    }
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _TextInputDialog(
        title: '创建牌局',
        label: '牌局名称',
        confirmLabel: '创建',
      ),
    );
    if (name == null) return;
    setState(() => _actionBusy = true);
    try {
      await widget.services.rooms!.createGameSession(
        roomId: snapshot.room.id,
        name: name,
      );
      _reloadSnapshot();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _startSession(GameSession session) async {
    await _runRoomAction(() async {
      final snapshot = await _snapshotFuture;
      if (!_isRoomOwner(snapshot.room)) {
        throw const PaizhangException('只有房主可以开始牌局');
      }
      await widget.services.rooms!.startGameSession(
        session.id,
        expectedVersion: session.version,
      );
      _reloadSnapshot();
    });
  }

  Future<void> _deleteDraftSession(GameSession session) async {
    final confirmed = await _confirmAction(
      title: '删除草稿牌局？',
      message: '删除后不会产生任何记分记录，且无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    await _runRoomAction(() async {
      final snapshot = await _snapshotFuture;
      if (!_isRoomOwner(snapshot.room)) {
        throw const PaizhangException('只有房主可以删除草稿牌局');
      }
      await widget.services.rooms!.manageGameSession(session.id, 'delete');
      _reloadSnapshot();
    });
  }

  Future<void> _renameSession(GameSession session) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog(
        title: '重命名牌局',
        label: '牌局名称',
        confirmLabel: '保存',
        initialValue: session.name,
      ),
    );
    if (name == null) return;
    await _runRoomAction(() async {
      final snapshot = await _snapshotFuture;
      if (!_isRoomOwner(snapshot.room)) {
        throw const PaizhangException('只有房主可以重命名牌局');
      }
      await widget.services.rooms!.manageGameSession(
        session.id,
        'rename',
        name: name,
        expectedVersion: session.version,
      );
      _reloadSnapshot();
    });
  }

  Future<void> _reopenSession(GameSession session) async {
    final confirmed = await _confirmAction(
      title: '重新打开牌局？',
      message: '重新打开后可以继续修正或录入回合。',
      confirmLabel: '重新打开',
    );
    if (!confirmed) return;
    await _runRoomAction(() async {
      final snapshot = await _snapshotFuture;
      if (!_isRoomOwner(snapshot.room)) {
        throw const PaizhangException('只有房主可以重新打开牌局');
      }
      await widget.services.rooms!.manageGameSession(
        session.id,
        'reopen',
        expectedVersion: session.version,
      );
      _reloadSnapshot();
    });
  }

  Future<_ScoreInput?> _showScoreInput(
    RemoteRoomSnapshot snapshot, {
    List<ScoreChange> initialChanges = const [],
    String? initialNote,
    String title = '录入一局分数',
  }) async {
    var currentChanges = initialChanges;
    var currentNote = initialNote;
    while (mounted) {
      if (!mounted) return null;
      final input = await showDialog<_ScoreInput>(
        context: context,
        builder: (context) => _ScoreDialog(
          members: snapshot.room.members,
          profiles: snapshot.profiles,
          scoringMode: snapshot.room.scoringMode,
          initialChanges: currentChanges,
          initialNote: currentNote,
          title: title,
        ),
      );
      if (input == null) return null;
      if (await _confirmRoundInput(snapshot, input.changes, input.note)) {
        return input;
      }
      currentChanges = input.changes;
      currentNote = input.note;
    }
    return null;
  }

  Future<void> _recordRound(
    GameSession session,
    RemoteRoomSnapshot snapshot,
  ) async {
    if (!_canInputRoom(snapshot.room)) {
      _showError('当前房间不允许录入');
      return;
    }
    if (session.status != GameSessionStatus.active) {
      _showError('请先开始一场牌局');
      return;
    }
    final existingRounds = snapshot.rounds
        .where((round) => round.sessionId == session.id)
        .toList();
    final input = await _showScoreInput(snapshot);
    if (input == null) return;
    final changes = input.changes;
    await _runRoomAction(() async {
      final result = await widget.services.rooms!.recordRoundWithQueue(
        queue: widget.services.queue,
        sessionId: session.id,
        roundNumber: existingRounds.length + 1,
        changes: changes,
        note: input.note,
      );
      if (result.queued) {
        await widget.services.cache.saveRound(result.round);
        _showLocalRound(snapshot, result.round);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('当前网络不可用，分数已保存，稍后自动同步')));
        }
      } else {
        _reloadSnapshot();
        _showSuccess('第 ${existingRounds.length + 1} 局已保存');
      }
    });
  }

  Future<void> _editRound(RemoteRoomSnapshot snapshot, Round round) async {
    if (!_canEditRound(snapshot, round)) {
      _showError('当前牌局不允许修改回合');
      return;
    }
    final input = await _showScoreInput(
      snapshot,
      initialChanges: round.changes,
      initialNote: round.note,
      title: '编辑第 ${round.number} 局',
    );
    if (input == null) return;
    final changes = input.changes;
    await _runRoomAction(() async {
      final result = await widget.services.rooms!.updateRoundWithQueue(
        queue: widget.services.queue,
        sessionId: round.sessionId,
        roundNumber: round.number,
        roundId: round.id,
        changes: changes,
        note: input.note,
      );
      if (result.queued) {
        await widget.services.cache.saveRound(result.round);
        _showLocalRound(snapshot, result.round);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('当前网络不可用，修改已保存，稍后自动同步')));
        }
      } else {
        _reloadSnapshot();
        _showSuccess('第 ${round.number} 局已更新');
      }
    });
  }

  Future<void> _deleteRound(RemoteRoomSnapshot snapshot, Round round) async {
    if (!_canEditRound(snapshot, round)) {
      _showError('只有该回合创建者可以撤销回合');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('撤销第 ${round.number} 局？'),
        content: const Text('这局会保留在历史记录中，但不再计入总分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('撤销'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runRoomAction(() async {
      final result = await widget.services.rooms!.deleteRoundWithQueue(
        queue: widget.services.queue,
        round: round,
      );
      await widget.services.cache.saveRound(result.round);
      _showLocalRound(snapshot, result.round);
      if (result.queued && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前网络不可用，撤销已保存，稍后自动同步')));
      }
    });
  }

  Future<void> _restoreRound(RemoteRoomSnapshot snapshot, Round round) async {
    if (!_canEditRound(snapshot, round)) {
      _showError('只有该回合创建者可以恢复回合');
      return;
    }
    if (round.changes.isEmpty) {
      _showError('该回合没有可恢复的分数记录');
      return;
    }
    await _runRoomAction(() async {
      final result = await widget.services.rooms!.updateRoundWithQueue(
        queue: widget.services.queue,
        sessionId: round.sessionId,
        roundNumber: round.number,
        roundId: round.id,
        changes: round.changes,
        note: round.note,
      );
      await widget.services.cache.saveRound(result.round);
      _showLocalRound(snapshot, result.round);
      if (result.queued && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前网络不可用，恢复已保存，稍后自动同步')));
      }
    });
  }

  Future<void> _showRoundHistory(
    RemoteRoomSnapshot snapshot,
    GameSession session,
  ) async {
    final rounds =
        snapshot.rounds.where((round) => round.sessionId == session.id).toList()
          ..sort((left, right) => right.number.compareTo(left.number));
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _RoundHistoryDialog(
        session: session,
        rounds: rounds,
        profiles: snapshot.profiles,
        currentUserId: widget.services.client?.auth.currentUser?.id,
        canEdit:
            session.status == GameSessionStatus.active &&
            _canInputRoom(snapshot.room),
        onEdit: (round) async {
          Navigator.of(dialogContext).pop();
          await _editRound(snapshot, round);
        },
        onDelete: (round) async {
          Navigator.of(dialogContext).pop();
          await _deleteRound(snapshot, round);
        },
        onRestore: (round) async {
          Navigator.of(dialogContext).pop();
          await _restoreRound(snapshot, round);
        },
      ),
    );
  }

  Future<void> _showSettlement(
    RemoteRoomSnapshot snapshot,
    GameSession session,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SettlementPage(
          room: snapshot.room,
          session: session,
          rounds: snapshot.rounds
              .where((round) => round.sessionId == session.id)
              .toList(),
          profiles: snapshot.profiles,
        ),
      ),
    );
  }

  Future<void> _showRoomHistory() async {
    try {
      final snapshot = await _snapshotFuture;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _RoomHistoryPage(snapshot: snapshot)),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _transferScore(
    RemoteRoomSnapshot snapshot, {
    required GameSession session,
    String? fromPlayerId,
  }) async {
    if (!_canInputRoom(snapshot.room)) {
      _showError('当前房间不允许录入');
      return;
    }
    if (session.status != GameSessionStatus.active) {
      _showError('请先开始一场牌局');
      return;
    }

    final totals = _scoreTotalsForSession(snapshot.rounds, session.id);
    final transfer = await showDialog<_ScoreTransfer>(
      context: context,
      builder: (context) => _ScoreTransferDialog(
        members: snapshot.room.members,
        profiles: snapshot.profiles,
        totals: totals,
        scoringMode: snapshot.room.scoringMode,
        initialFromPlayerId: fromPlayerId,
      ),
    );
    if (transfer == null) return;

    final existingRounds = snapshot.rounds
        .where((round) => round.sessionId == session.id)
        .toList();
    await _runRoomAction(() async {
      final result = await widget.services.rooms!.recordRoundWithQueue(
        queue: widget.services.queue,
        sessionId: session.id,
        roundNumber: existingRounds.length + 1,
        changes: [
          ScoreChange(playerId: transfer.fromPlayerId, value: -transfer.amount),
          ScoreChange(playerId: transfer.toPlayerId, value: transfer.amount),
        ],
        note: '${_scoreUnitLabel(snapshot.room.scoringMode)}转换',
      );
      if (result.queued) {
        await widget.services.cache.saveRound(result.round);
        _showLocalRound(snapshot, result.round);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('当前网络不可用，积分转换已保存，稍后自动同步')),
          );
        }
      } else {
        _reloadSnapshot();
        _showSuccess('积分转换已记录');
      }
    });
  }

  Future<void> _finishSession(
    RemoteRoomSnapshot snapshot,
    GameSession session,
  ) async {
    if (!_isRoomOwner(snapshot.room)) {
      _showError('只有房主可以结束牌局');
      return;
    }
    final confirmed = await _confirmAction(
      title: '结束牌局？',
      message: '结束后将不能继续录入，只有重新打开后才能修正。',
      confirmLabel: '结束牌局',
    );
    if (!confirmed) return;
    await _runRoomAction(() async {
      await widget.services.rooms!.finishGameSession(
        session.id,
        expectedVersion: session.version,
      );
      _reloadSnapshot();
    });
  }

  Future<void> _castCloseVote(
    RemoteRoomSnapshot snapshot, {
    required bool approved,
    required RoomStatus targetStatus,
  }) async {
    if (snapshot.room.isClosed) return;
    await _runRoomAction(() async {
      await widget.services.rooms!.castCloseVote(
        snapshot.room,
        approved,
        vote: snapshot.closeVote,
        targetStatus: targetStatus,
      );
      _reloadSnapshot();
    });
  }

  Future<void> _editRoomDetails(RemoteRoomSnapshot snapshot) async {
    if (!_isRoomOwner(snapshot.room)) {
      _showError('只有房主可以编辑房间');
      return;
    }
    final values = await showDialog<_RoomFormValue>(
      context: context,
      builder: (context) => _RoomFormDialog(
        title: '编辑房间',
        submitLabel: '保存',
        initialName: snapshot.room.name,
        initialGameType: snapshot.room.gameType,
        initialScoringMode: snapshot.room.scoringMode,
      ),
    );
    if (values == null) return;
    await _runRoomAction(() async {
      await widget.services.rooms!.updateRoomDetails(
        snapshot.room,
        name: values.name,
        gameType: values.gameType,
        scoringMode: values.scoringMode,
      );
      _reloadSnapshot();
    });
  }

  Future<void> _showRoomManagement(RemoteRoomSnapshot snapshot) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _RoomManagementDialog(
        room: snapshot.room,
        profiles: snapshot.profiles,
        currentUserId: widget.services.client?.auth.currentUser?.id,
        closeVote: snapshot.closeVote,
        hasActiveSession: snapshot.sessions.any(
          (session) => session.status == GameSessionStatus.active,
        ),
        onEditRoom: () async {
          Navigator.of(dialogContext).pop();
          await _editRoomDetails(snapshot);
        },
        onCloseVote: (approved, targetStatus) async {
          Navigator.of(dialogContext).pop();
          await _castCloseVote(
            snapshot,
            approved: approved,
            targetStatus: targetStatus,
          );
        },
        onCancelCloseVote: () async {
          final proposalId = snapshot.closeVote?.proposalId;
          if (proposalId == null) return;
          Navigator.of(dialogContext).pop();
          await _runRoomAction(() async {
            await widget.services.rooms!.cancelCloseVote(
              snapshot.room,
              proposalId,
            );
            _reloadSnapshot();
          });
        },
        onPermissionChanged: (permission) async {
          Navigator.of(dialogContext).pop();
          await _runRoomAction(() async {
            await widget.services.rooms!.setInputPermission(
              roomId: snapshot.room.id,
              permission: permission,
            );
            _reloadSnapshot();
          });
        },
        onRemoveMember: (userId) async {
          Navigator.of(dialogContext).pop();
          final confirmed = await _confirmAction(
            title: '移除成员？',
            message: '移除后，该成员不能继续录入或管理，但仍可在历史记录查看离开前的牌局。',
            confirmLabel: '移除',
          );
          if (!confirmed) return;
          await _runRoomAction(() async {
            await widget.services.rooms!.removeMember(
              roomId: snapshot.room.id,
              userId: userId,
            );
            _reloadSnapshot();
          });
        },
        onTransferOwnership: (userId) async {
          Navigator.of(dialogContext).pop();
          final confirmed = await _confirmAction(
            title: '转让房主？',
            message: '转让后你将不能继续管理成员和录入权限。',
            confirmLabel: '转让',
          );
          if (!confirmed) return;
          await _runRoomAction(() async {
            await widget.services.rooms!.transferOwnership(
              roomId: snapshot.room.id,
              userId: userId,
            );
            _reloadSnapshot();
          });
        },
        onLeaveRoom: () async {
          Navigator.of(dialogContext).pop();
          final confirmed = await _confirmAction(
            title: '离开房间？',
            message: '离开后需要新的邀请码才能重新加入。',
            confirmLabel: '离开',
          );
          if (!confirmed) return;
          await _runRoomAction(() async {
            await widget.services.rooms!.leaveRoom(snapshot.room.id);
            if (mounted) Navigator.of(context).pop();
          });
        },
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = _friendlyErrorMessage(error);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSyncError(Object error) {
    if (!mounted) return;
    if (_isRoomAccessError(error)) {
      setState(() {
        _snapshotFuture = Future<RemoteRoomSnapshot>.error(error);
      });
      return;
    }
    _showError(error);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmRoundInput(
    RemoteRoomSnapshot snapshot,
    List<ScoreChange> changes,
    String? note,
  ) async {
    final unit = _scoreUnitLabel(snapshot.room.scoringMode);
    final summary = changes
        .map(
          (change) =>
              '${_profileName(change.playerId, snapshot.profiles)} ${change.value > 0 ? '+' : ''}${change.value} $unit',
        )
        .join('\n');
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认提交'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('备注：$note'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('返回修改'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确认提交'),
              ),
            ],
          ),
        ) ??
        false;
  }

  bool _isRoomAccessError(Object error) {
    final value = error.toString().toLowerCase();
    return value.contains('room_member_required') ||
        value.contains('room_not_found') ||
        value.contains('permission denied') ||
        value.contains('not found');
  }

  String _friendlyErrorMessage(Object error) {
    final rawMessage = error.toString();
    const messages = <String, String>{
      'money_round_unbalanced': '金额模式每局必须平账',
      'room_closed': '房间已关闭，当前只能查看历史和结算',
      'active_session_exists': '仍有进行中的牌局，请先结束所有牌局',
      'room_owner_required': '只有房主可以执行此操作',
      'room_member_required': '你已不再是房间成员，当前仅可查看历史',
      'version_conflict': '数据已被其他成员更新，请刷新后重试',
      'vote_expired': '本轮关闭投票已失效，请重新发起',
      'another_close_vote_pending': '已有另一种关闭方式的投票进行中',
      'vote_not_started': '请先发起关闭投票',
      'only_draft_can_delete': '只有草稿牌局可以删除',
      'invalid_session_transition': '当前牌局状态不允许这个操作',
      'session_finished': '牌局已结束，请先重新打开',
      'round_write_forbidden': '当前牌局不允许写入回合',
    };
    for (final entry in messages.entries) {
      if (rawMessage.contains(entry.key)) return entry.value;
    }
    return rawMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
        actions: [
          IconButton(
            onPressed: _showRoomHistory,
            icon: const Icon(Icons.history_rounded),
            tooltip: '房间历史',
          ),
          FutureBuilder<RemoteRoomSnapshot>(
            future: _snapshotFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || !_isRoomOwner(snapshot.data!.room)) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: _createInvite,
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: '生成邀请码',
              );
            },
          ),
          IconButton(
            onPressed: () async {
              try {
                final snapshot = await _snapshotFuture;
                if (mounted) await _showRoomManagement(snapshot);
              } catch (error) {
                _showError(error);
              }
            },
            icon: const Icon(Icons.settings_rounded),
            tooltip: '房间管理',
          ),
        ],
      ),
      body: FutureBuilder<RemoteRoomSnapshot>(
        future: _snapshotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (_isRoomAccessError(snapshot.error!)) {
              return _RoomAccessErrorCard(
                message: _friendlyErrorMessage(snapshot.error!),
                onBack: () => Navigator.of(context).pop(),
              );
            }
            return _ErrorCard(
              message: snapshot.error.toString(),
              onRetry: _reloadSnapshot,
            );
          }
          final data = snapshot.data!;
          final activeSession = _selectedActiveSession(data);
          final activeSessions = data.sessions
              .where((session) => session.status == GameSessionStatus.active)
              .toList();
          final totals = activeSession == null
              ? const <String, int>{}
              : _scoreTotalsForSession(data.rounds, activeSession.id);
          final members = data.room.members
              .where((member) => member.isActive)
              .toList();
          final canInput = _canInputRoom(data.room);
          final isOwner = _isRoomOwner(data.room);
          final scoreUnit = _scoreUnitLabel(data.room.scoringMode);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: Text('${members.length} 位成员'),
                  subtitle: Text(data.room.gameType),
                  trailing: Text(_roomStatusLabel(data.room.status)),
                ),
              ),
              if (data.room.isClosed)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const ListTile(
                    leading: Icon(Icons.lock_outline_rounded),
                    title: Text('房间已关闭'),
                    subtitle: Text('当前仅支持查看历史和结算，不能继续录入或管理。'),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                '成员分数',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (activeSessions.length > 1) ...[
                        DropdownButtonFormField<String>(
                          initialValue: activeSession?.id,
                          decoration: InputDecoration(
                            labelText: '当前牌局',
                            helperText: '选择头像转换所对应的进行中牌局',
                          ),
                          items: [
                            for (final session in activeSessions)
                              DropdownMenuItem(
                                value: session.id,
                                child: Text(session.name),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedSessionId = value);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (activeSession == null)
                        const Text('请先开始一场牌局')
                      else if (!canInput)
                        const Text('当前仅房主可以录入分数'),
                      if (activeSession != null && canInput)
                        Text(
                          '点击成员头像进行$scoreUnit转换',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final member in members)
                            _RoomMemberScoreTile(
                              member: member,
                              profile: data.profiles[member.userId],
                              score: totals[member.userId] ?? 0,
                              enabled: activeSession != null && canInput,
                              onTap: () => _transferScore(
                                data,
                                session: activeSession!,
                                fromPlayerId: member.userId,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '牌局',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: isOwner ? () => _createSession(data) : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('新建'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (data.sessions.isEmpty)
                const Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text('还没有牌局'),
                    subtitle: Text('创建牌局后开始记分'),
                  ),
                )
              else
                for (final session in data.sessions)
                  _SessionCard(
                    session: session,
                    roundCount: data.rounds
                        .where((round) => round.sessionId == session.id)
                        .length,
                    onRecord: () => _recordRound(session, data),
                    onStart: () => _startSession(session),
                    onDelete: () => _deleteDraftSession(session),
                    onRename: () => _renameSession(session),
                    onReopen: () => _reopenSession(session),
                    onFinish: () => _finishSession(data, session),
                    onHistory: () => _showRoundHistory(data, session),
                    onSettlement: () => _showSettlement(data, session),
                    canRecord: canInput,
                    canManage: isOwner,
                    readOnly:
                        data.room.isClosed ||
                        !data.room.hasActiveMember(
                          widget.services.client?.auth.currentUser?.id ?? '',
                        ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class ConnectedProfilePage extends StatefulWidget {
  const ConnectedProfilePage({required this.services, super.key});

  final AppServices services;

  @override
  State<ConnectedProfilePage> createState() => _ConnectedProfilePageState();
}

class _ConnectedProfilePageState extends State<ConnectedProfilePage> {
  late String _nickname;
  String? _avatarKey;
  String? _avatarUrl;
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    final user = widget.services.client!.auth.currentUser;
    _nickname = (user?.userMetadata?['nickname'] as String?)?.trim() ?? '';
    _avatarKey = user?.userMetadata?['avatar_key'] as String?;
    _avatarUrl = user?.userMetadata?['avatar_url'] as String?;
  }

  Future<void> _pickAvatar() async {
    if (_avatarBusy) return;
    setState(() => _avatarBusy = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image == null || !mounted) return;
      final oldKey = _avatarKey;
      var extension = image.name.split('.').last.toLowerCase();
      if (extension == 'jpeg') extension = 'jpg';
      if (!{'jpg', 'png', 'webp'}.contains(extension)) {
        extension = switch (image.mimeType) {
          'image/jpeg' => 'jpg',
          'image/png' => 'png',
          'image/webp' => 'webp',
          _ => extension,
        };
      }
      final upload = await widget.services.rooms!.uploadAvatar(
        await image.readAsBytes(),
        extension,
      );
      try {
        await widget.services.auth!.updateAvatar(
          avatarKey: upload.key,
          avatarUrl: upload.url,
          previousAvatarKey: oldKey,
          previousAvatarUrl: _avatarUrl,
        );
      } catch (_) {
        try {
          await widget.services.rooms!.removeAvatarFile(upload.key);
        } catch (_) {}
        rethrow;
      }
      if (oldKey != null) {
        try {
          await widget.services.rooms!.removeAvatarFile(oldKey);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _avatarKey = upload.key;
          _avatarUrl = upload.url;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('头像已更新')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _selectPresetAvatar() async {
    if (_avatarBusy) return;
    final avatarKey = await showDialog<String>(
      context: context,
      builder: (context) => const _AvatarPresetDialog(),
    );
    if (avatarKey == null || !mounted) return;
    setState(() => _avatarBusy = true);
    final oldKey = _avatarKey;
    try {
      await widget.services.auth!.updateAvatar(
        avatarKey: avatarKey,
        previousAvatarKey: oldKey,
        previousAvatarUrl: _avatarUrl,
      );
      if (oldKey != null) {
        try {
          await widget.services.rooms!.removeAvatarFile(oldKey);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _avatarKey = avatarKey;
          _avatarUrl = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('预设头像已更新')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_avatarBusy || (_avatarKey == null && _avatarUrl == null)) return;
    setState(() => _avatarBusy = true);
    final oldKey = _avatarKey;
    try {
      await widget.services.auth!.clearAvatar(
        previousAvatarKey: oldKey,
        previousAvatarUrl: _avatarUrl,
      );
      try {
        await widget.services.rooms!.removeAvatarFile(oldKey);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _avatarKey = null;
          _avatarUrl = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('头像已删除')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _editNickname() async {
    if (_avatarBusy) return;
    final controller = TextEditingController(text: _nickname);
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: '昵称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nickname == null || nickname.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _avatarBusy = true);
    try {
      await widget.services.auth!.updateNickname(nickname: nickname.trim());
      if (mounted) setState(() => _nickname = nickname.trim());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConnectedHistoryPage(services: widget.services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.services.client!.auth.currentUser;
    final displayName = _nickname.isEmpty
        ? user?.email ?? user?.phone ?? '牌友'
        : _nickname;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Text(
          '我的',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 28),
        Card(
          elevation: 0,
          child: ListTile(
            leading: _UserAvatar(
              name: displayName,
              avatarKey: _avatarKey,
              avatarUrl: _avatarUrl,
              radius: 26,
            ),
            title: Text(displayName),
            subtitle: Text(user?.email ?? user?.phone ?? ''),
            trailing: const Icon(Icons.edit_rounded),
            onTap: _editNickname,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.photo_camera_back_rounded),
            title: const Text('头像'),
            subtitle: Text(
              _avatarKey == null && _avatarUrl == null
                  ? '未设置头像'
                  : '支持预设头像或图片头像',
            ),
            trailing: _avatarBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'preset') _selectPresetAvatar();
                      if (value == 'pick') _pickAvatar();
                      if (value == 'remove') _removeAvatar();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'preset',
                        child: Text('选择预设头像'),
                      ),
                      const PopupMenuItem(value: 'pick', child: Text('选择图片')),
                      if (_avatarKey != null || _avatarUrl != null)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('删除头像'),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('历史记录'),
            subtitle: const Text('查看个人和房间的过往牌局'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _openHistory,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => widget.services.auth!.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('退出登录'),
        ),
      ],
    );
  }
}

class ConnectedHistoryPage extends StatefulWidget {
  const ConnectedHistoryPage({required this.services, super.key});

  final AppServices services;

  @override
  State<ConnectedHistoryPage> createState() => _ConnectedHistoryPageState();
}

class _ConnectedHistoryPageState extends State<ConnectedHistoryPage> {
  late Future<List<_HistoryRoomData>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _historyFuture = _loadHistory();
  }

  Future<List<_HistoryRoomData>> _loadHistory() async {
    final snapshots = await widget.services.rooms!.listMyHistory();
    final currentUserId = widget.services.client?.auth.currentUser?.id;
    final history = <_HistoryRoomData>[];
    for (final snapshot in snapshots) {
      final room = snapshot.room;
      final sessions =
          snapshot.sessions
              .where(
                (session) => snapshot.rounds.any(
                  (round) => round.sessionId == session.id,
                ),
              )
              .toList()
            ..sort(
              (left, right) =>
                  _sessionDate(right).compareTo(_sessionDate(left)),
            );
      if (sessions.isNotEmpty) {
        history.add(
          _HistoryRoomData(
            room: room,
            snapshot: snapshot,
            sessions: List.unmodifiable(sessions),
            isCurrentMember: room.hasActiveMember(currentUserId ?? ''),
          ),
        );
      }
    }
    history.sort((left, right) => right.latestDate.compareTo(left.latestDate));
    return history;
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _historyFuture;
  }

  Future<void> _openSettlement(
    _HistoryRoomData history,
    GameSession session,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SettlementPage(
          room: history.room,
          session: session,
          rounds: history.snapshot.rounds
              .where((round) => round.sessionId == session.id)
              .toList(),
          profiles: history.snapshot.profiles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
      body: FutureBuilder<List<_HistoryRoomData>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorCard(
              message: snapshot.error.toString(),
              onRetry: () => setState(_reload),
            );
          }
          final history = snapshot.data ?? const <_HistoryRoomData>[];
          if (history.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.history_rounded, size: 56),
                  SizedBox(height: 12),
                  Center(child: Text('还没有历史牌局')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final roomHistory = history[index];
                return Card(
                  elevation: 0,
                  child: ExpansionTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.groups_rounded),
                    ),
                    title: Text(roomHistory.room.name),
                    subtitle: Text(
                      '${roomHistory.sessions.length} 场牌局 · '
                      '${roomHistory.isCurrentMember ? '当前成员' : '已离开/被移除'}',
                    ),
                    children: [
                      for (final session in roomHistory.sessions)
                        ListTile(
                          title: Text(session.name),
                          subtitle: Text(
                            '${_activeRoundCount(roomHistory.snapshot, session)} 局有效记录 · ${_sessionStatusLabel(session.status)}',
                          ),
                          trailing: Text(
                            _formatHistoryDate(_sessionDate(session)),
                          ),
                          onTap: () => _openSettlement(roomHistory, session),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _RoomHistoryPage extends StatelessWidget {
  const _RoomHistoryPage({required this.snapshot});

  final RemoteRoomSnapshot snapshot;

  Future<void> _openSettlement(
    BuildContext context,
    GameSession session,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SettlementPage(
          room: snapshot.room,
          session: session,
          rounds: snapshot.rounds
              .where((round) => round.sessionId == session.id)
              .toList(),
          profiles: snapshot.profiles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = [
      ...snapshot.sessions,
    ]..sort((left, right) => _sessionDate(right).compareTo(_sessionDate(left)));
    return Scaffold(
      appBar: AppBar(title: Text('${snapshot.room.name} · 历史')),
      body: sessions.isEmpty
          ? const Center(child: Text('还没有历史牌局'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final rounds =
                    snapshot.rounds
                        .where((round) => round.sessionId == session.id)
                        .toList()
                      ..sort(
                        (left, right) => right.number.compareTo(left.number),
                      );
                return Card(
                  elevation: 0,
                  child: ExpansionTile(
                    title: Text(session.name),
                    subtitle: Text(
                      '${_activeRoundCount(snapshot, session)} 局有效记录 · ${_sessionStatusLabel(session.status)}',
                    ),
                    trailing: Text(_formatHistoryDate(_sessionDate(session))),
                    children: [
                      if (rounds.isEmpty)
                        const ListTile(title: Text('还没有回合记录'))
                      else
                        for (final round in rounds)
                          ListTile(
                            leading: CircleAvatar(
                              child: Text('${round.number}'),
                            ),
                            title: Text(
                              round.isDeleted
                                  ? '第 ${round.number} 局（已撤销）'
                                  : round.changes
                                        .map(
                                          (change) =>
                                              '${_profileName(change.playerId, snapshot.profiles)} ${change.value > 0 ? '+' : ''}${change.value}',
                                        )
                                        .join('，'),
                            ),
                            subtitle: round.note == null || round.note!.isEmpty
                                ? null
                                : Text(round.note!),
                          ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TextButton.icon(
                            onPressed: () => _openSettlement(context, session),
                            icon: const Icon(Icons.emoji_events_rounded),
                            label: const Text('查看结算'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _HistoryRoomData {
  const _HistoryRoomData({
    required this.room,
    required this.snapshot,
    required this.sessions,
    required this.isCurrentMember,
  });

  final Room room;
  final RemoteRoomSnapshot snapshot;
  final List<GameSession> sessions;
  final bool isCurrentMember;

  DateTime get latestDate => _sessionDate(sessions.first);
}

int _activeRoundCount(RemoteRoomSnapshot snapshot, GameSession session) {
  return snapshot.rounds
      .where((round) => round.sessionId == session.id && !round.isDeleted)
      .length;
}

DateTime _sessionDate(GameSession session) {
  return session.finishedAt ?? session.startedAt ?? session.createdAt;
}

String _sessionStatusLabel(GameSessionStatus status) {
  return switch (status) {
    GameSessionStatus.draft => '未开始',
    GameSessionStatus.active => '进行中',
    GameSessionStatus.finished => '已结束',
  };
}

String _roomStatusLabel(RoomStatus status) {
  return switch (status) {
    RoomStatus.waiting => '等待中',
    RoomStatus.active => '进行中',
    RoomStatus.finished => '已结束',
    RoomStatus.archived => '已归档',
    RoomStatus.dissolved => '已解散',
  };
}

String _formatHistoryDate(DateTime value) {
  final date = value.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}

class _ScoreTransfer {
  const _ScoreTransfer({
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.amount,
  });

  final String fromPlayerId;
  final String toPlayerId;
  final int amount;
}

class _ScoreInput {
  const _ScoreInput({required this.changes, this.note});

  final List<ScoreChange> changes;
  final String? note;
}

class _ScoreTransferDialog extends StatefulWidget {
  const _ScoreTransferDialog({
    required this.members,
    required this.profiles,
    required this.totals,
    required this.scoringMode,
    this.initialFromPlayerId,
  });

  final List<RoomMember> members;
  final Map<String, User> profiles;
  final Map<String, int> totals;
  final ScoringMode scoringMode;
  final String? initialFromPlayerId;

  @override
  State<_ScoreTransferDialog> createState() => _ScoreTransferDialogState();
}

class _ScoreTransferDialogState extends State<_ScoreTransferDialog> {
  late final List<RoomMember> _members = widget.members
      .where((member) => member.isActive)
      .toList();
  final _amountController = TextEditingController();
  String? _fromPlayerId;
  String? _toPlayerId;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_members.any((member) => member.userId == widget.initialFromPlayerId)) {
      _fromPlayerId = widget.initialFromPlayerId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amountController.text.trim());
    if (_fromPlayerId == null || _toPlayerId == null) {
      setState(() => _error = '请选择转出方和接收方');
      return;
    }
    if (_fromPlayerId == _toPlayerId) {
      setState(() => _error = '转出方和接收方不能是同一人');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = '请输入大于 0 的$_unitLabel');
      return;
    }
    Navigator.pop(
      context,
      _ScoreTransfer(
        fromPlayerId: _fromPlayerId!,
        toPlayerId: _toPlayerId!,
        amount: amount,
      ),
    );
  }

  String get _unitLabel =>
      widget.scoringMode == ScoringMode.money ? '金额' : '积分';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$_unitLabel转换'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('从一名成员转给另一名成员，并记录为当前牌局的一局变化。'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _fromPlayerId,
              decoration: InputDecoration(labelText: '转出方'),
              items: [
                for (final member in _members)
                  DropdownMenuItem(
                    value: member.userId,
                    child: Text(_memberLabel(member, widget.profiles)),
                  ),
              ],
              onChanged: (value) => setState(() {
                _fromPlayerId = value;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _toPlayerId,
              decoration: InputDecoration(labelText: '接收方'),
              items: [
                for (final member in _members)
                  DropdownMenuItem(
                    value: member.userId,
                    child: Text(_memberLabel(member, widget.profiles)),
                  ),
              ],
              onChanged: (value) => setState(() {
                _toPlayerId = value;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _unitLabel,
                suffixText: _fromPlayerId == null
                    ? null
                    : '当前 ${widget.totals[_fromPlayerId!] ?? 0}',
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('确认转换')),
      ],
    );
  }
}

class _RoomMemberScoreTile extends StatelessWidget {
  const _RoomMemberScoreTile({
    required this.member,
    required this.profile,
    required this.score,
    required this.enabled,
    required this.onTap,
  });

  final RoomMember member;
  final User? profile;
  final int score;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = profile?.nickname ?? _shortId(member.userId);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            _UserAvatar(
              name: label,
              avatarKey: profile?.avatarKey,
              avatarUrl: profile?.avatarUrl,
              radius: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              '$score',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: score < 0
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundHistoryDialog extends StatelessWidget {
  const _RoundHistoryDialog({
    required this.session,
    required this.rounds,
    required this.profiles,
    required this.currentUserId,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
  });

  final GameSession session;
  final List<Round> rounds;
  final Map<String, User> profiles;
  final String? currentUserId;
  final bool canEdit;
  final Future<void> Function(Round round) onEdit;
  final Future<void> Function(Round round) onDelete;
  final Future<void> Function(Round round) onRestore;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${session.name} · 回合记录'),
      content: SizedBox(
        width: 560,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: rounds.isEmpty
              ? const Text('还没有回合记录')
              : ListView.separated(
                  itemCount: rounds.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final round = rounds[index];
                    final changes = round.changes
                        .map(
                          (change) =>
                              '${_profileName(change.playerId, profiles)} ${change.value > 0 ? '+' : ''}${change.value}',
                        )
                        .join('，');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text('${round.number}')),
                      title: Text(
                        round.isDeleted ? '第 ${round.number} 局（已撤销）' : changes,
                        style: TextStyle(
                          decoration: round.isDeleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: round.note == null || round.note!.isEmpty
                          ? null
                          : Text(round.note!),
                      trailing:
                          canEdit &&
                              round.createdBy == currentUserId &&
                              (!round.isDeleted || round.changes.isNotEmpty)
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit(round);
                                } else if (value == 'delete') {
                                  onDelete(round);
                                } else if (value == 'restore') {
                                  onRestore(round);
                                }
                              },
                              itemBuilder: (context) => [
                                if (!round.isDeleted)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('编辑'),
                                  ),
                                if (!round.isDeleted)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('撤销'),
                                  ),
                                if (round.isDeleted && round.changes.isNotEmpty)
                                  const PopupMenuItem(
                                    value: 'restore',
                                    child: Text('恢复'),
                                  ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class _RoomManagementDialog extends StatelessWidget {
  const _RoomManagementDialog({
    required this.room,
    required this.profiles,
    required this.currentUserId,
    required this.closeVote,
    required this.hasActiveSession,
    required this.onEditRoom,
    required this.onCloseVote,
    required this.onCancelCloseVote,
    required this.onPermissionChanged,
    required this.onRemoveMember,
    required this.onTransferOwnership,
    required this.onLeaveRoom,
  });

  final Room room;
  final Map<String, User> profiles;
  final String? currentUserId;
  final RoomCloseVoteSummary? closeVote;
  final bool hasActiveSession;
  final Future<void> Function() onEditRoom;
  final Future<void> Function(bool approved, RoomStatus targetStatus)
  onCloseVote;
  final Future<void> Function() onCancelCloseVote;
  final Future<void> Function(InputPermission permission) onPermissionChanged;
  final Future<void> Function(String userId) onRemoveMember;
  final Future<void> Function(String userId) onTransferOwnership;
  final Future<void> Function() onLeaveRoom;

  @override
  Widget build(BuildContext context) {
    final isOwner = room.ownerId == currentUserId;
    final activeMembers = room.members
        .where((member) => member.isActive)
        .toList();
    return AlertDialog(
      title: const Text('房间管理'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${activeMembers.length} 位成员 · ${room.gameType}'),
            const SizedBox(height: 8),
            Text(
              room.isClosed
                  ? '房间已${room.status == RoomStatus.dissolved ? '解散' : '归档'}，当前仅可查看历史和结算。'
                  : '关闭房间需要有效成员投票，必须严格超过半数同意。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (isOwner && !room.isClosed) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onEditRoom,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('编辑房间资料'),
                ),
              ),
            ],
            if (!room.isClosed) ...[
              const SizedBox(height: 12),
              _CloseVotePanel(
                vote: closeVote,
                currentUserId: currentUserId,
                createdBy: closeVote?.createdBy,
                hasActiveSession: hasActiveSession,
                isOwner: isOwner,
                onVote: onCloseVote,
                onCancel: onCancelCloseVote,
              ),
            ],
            const SizedBox(height: 12),
            if (isOwner && !room.isClosed)
              DropdownButtonFormField<InputPermission>(
                initialValue: room.inputPermission,
                decoration: const InputDecoration(labelText: '记分录入权限'),
                items: const [
                  DropdownMenuItem(
                    value: InputPermission.all,
                    child: Text('所有成员可录入'),
                  ),
                  DropdownMenuItem(
                    value: InputPermission.ownerOnly,
                    child: Text('仅房主可录入'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null && value != room.inputPermission) {
                    onPermissionChanged(value);
                  }
                },
              ),
            const SizedBox(height: 12),
            const Text('成员', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: activeMembers
                      .map<Widget>(
                        (member) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _UserAvatar(
                            name: _profileName(member.userId, profiles),
                            avatarKey: profiles[member.userId]?.avatarKey,
                            avatarUrl: profiles[member.userId]?.avatarUrl,
                          ),
                          title: Text(_profileName(member.userId, profiles)),
                          subtitle: Text(
                            member.userId == room.ownerId ? '房主' : '成员',
                          ),
                          trailing:
                              isOwner &&
                                  !room.isClosed &&
                                  member.userId != room.ownerId
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'transfer') {
                                      onTransferOwnership(member.userId);
                                    } else if (value == 'remove') {
                                      onRemoveMember(member.userId);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'transfer',
                                      child: Text('转让房主'),
                                    ),
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Text('移除成员'),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isOwner && !room.isClosed)
          TextButton(onPressed: onLeaveRoom, child: const Text('离开房间')),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class _CloseVotePanel extends StatelessWidget {
  const _CloseVotePanel({
    required this.vote,
    required this.currentUserId,
    required this.createdBy,
    required this.hasActiveSession,
    required this.isOwner,
    required this.onVote,
    required this.onCancel,
  });

  final RoomCloseVoteSummary? vote;
  final String? currentUserId;
  final String? createdBy;
  final bool hasActiveSession;
  final bool isOwner;
  final Future<void> Function(bool approved, RoomStatus targetStatus) onVote;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final targetStatus = vote?.targetStatus ?? RoomStatus.archived;
    final canVote = !hasActiveSession;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vote == null ? '关闭房间' : '关闭投票进行中',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (hasActiveSession)
              const Text('仍有进行中的牌局，请先结束所有牌局。')
            else if (vote == null)
              const Text('发起后，所有有效成员都需要投票；同意票必须严格超过半数。')
            else ...[
              Text(
                '目标：${targetStatus == RoomStatus.dissolved ? '解散' : '归档'} · '
                '${vote!.approvedCount}/${vote!.activeMemberCount} 票同意',
              ),
              const SizedBox(height: 4),
              Text(
                vote!.currentUserApproved == null
                    ? '你还没有投票'
                    : vote!.currentUserApproved!
                    ? '你已投同意票'
                    : '你已投不同意票',
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (vote == null) ...[
                  FilledButton.tonal(
                    onPressed: canVote
                        ? () => onVote(true, RoomStatus.archived)
                        : null,
                    child: const Text('发起归档投票'),
                  ),
                  OutlinedButton(
                    onPressed: canVote
                        ? () => onVote(true, RoomStatus.dissolved)
                        : null,
                    child: const Text('发起解散投票'),
                  ),
                ] else ...[
                  FilledButton.tonal(
                    onPressed: canVote
                        ? () => onVote(true, targetStatus)
                        : null,
                    child: const Text('同意关闭'),
                  ),
                  OutlinedButton(
                    onPressed: canVote
                        ? () => onVote(false, targetStatus)
                        : null,
                    child: const Text('不同意'),
                  ),
                  if (isOwner || createdBy == currentUserId)
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('取消本轮投票'),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementPage extends StatefulWidget {
  const _SettlementPage({
    required this.room,
    required this.session,
    required this.rounds,
    required this.profiles,
  });

  final Room room;
  final GameSession session;
  final List<Round> rounds;
  final Map<String, User> profiles;

  @override
  State<_SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<_SettlementPage> {
  final _shareCardKey = GlobalKey();

  Room get room => widget.room;
  GameSession get session => widget.session;
  List<Round> get rounds => widget.rounds;
  Map<String, User> get profiles => widget.profiles;

  String _summaryText(
    SettlementResult result,
    List<MapEntry<String, int>> ranking,
    String unit,
  ) {
    final lines = <String>['${session.name} · 结算', '累计排名：'];
    for (var index = 0; index < ranking.length; index++) {
      final entry = ranking[index];
      lines.add(
        '${index + 1}. ${_profileName(entry.key, profiles)} ${entry.value > 0 ? '+' : ''}${entry.value} $unit',
      );
    }
    if (!result.isBalanced) {
      lines.add('金额差额：${result.unbalancedAmount}');
    } else if (result.transfers.isNotEmpty) {
      lines.add('转账：');
      for (final transfer in result.transfers) {
        lines.add(
          '${_profileName(transfer.fromPlayerId, profiles)} → ${_profileName(transfer.toPlayerId, profiles)} ${transfer.amount} $unit',
        );
      }
    } else {
      lines.add('当前没有需要转账的差额。');
    }
    return lines.join('\n');
  }

  Future<void> _shareSummary(String summary) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: summary, subject: '${session.name} · 结算'),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _shareImage(String summary) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = _shareCardKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('结算卡片尚未准备好，请稍后再试');
      }
      final image = await renderObject.toImage(pixelRatio: 3);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw StateError('结算图片生成失败');
        await SharePlus.instance.share(
          ShareParams(
            text: summary,
            subject: '${session.name} · 结算',
            files: [
              XFile.fromData(
                byteData.buffer.asUint8List(),
                mimeType: 'image/png',
                name: 'paizhang-settlement.png',
              ),
            ],
            fileNameOverrides: const ['paizhang-settlement.png'],
          ),
        );
      } finally {
        image.dispose();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = const SettlementCalculator().calculate(
      rounds,
      room.scoringMode,
    );
    final participantIds = <String>{
      ...room.members.map((member) => member.userId),
      ...result.totals.keys,
    };
    final totals = <String, int>{
      for (final playerId in participantIds)
        playerId: result.totals[playerId] ?? 0,
    };
    final ranking = totals.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final unit = _scoreUnitLabel(room.scoringMode);

    return Scaffold(
      appBar: AppBar(
        title: Text('${session.name} · 结算'),
        actions: [
          IconButton(
            tooltip: '系统分享',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareSummary(_summaryText(result, ranking, unit)),
          ),
          IconButton(
            tooltip: '复制结算',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: _summaryText(result, ranking, unit)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('结算摘要已复制')));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: RepaintBoundary(
          key: _shareCardKey,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${session.name} · 结算',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_rounded),
                    title: Text(
                      '${rounds.where((round) => !round.isDeleted).length} 局有效记录',
                    ),
                    subtitle: Text(
                      room.scoringMode == ScoringMode.money ? '金额结算' : '积分结算',
                    ),
                  ),
                ),
                if (!result.isBalanced) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: const Text('暂不能完成金额结算'),
                      subtitle: Text(
                        '当前差额：${result.unbalancedAmount}，请先修正回合记录。',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  '累计排名',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < ranking.length; index++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(child: Text('${index + 1}')),
                        const SizedBox(width: 8),
                        _UserAvatar(
                          name: _profileName(ranking[index].key, profiles),
                          avatarKey: profiles[ranking[index].key]?.avatarKey,
                          avatarUrl: profiles[ranking[index].key]?.avatarUrl,
                          radius: 18,
                        ),
                      ],
                    ),
                    title: Text(_profileName(ranking[index].key, profiles)),
                    trailing: Text(
                      '${ranking[index].value > 0 ? '+' : ''}${ranking[index].value} $unit',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                if (result.isBalanced && result.transfers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    '最少转账路径',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final transfer in result.transfers)
                    Card(
                      elevation: 0,
                      child: ListTile(
                        leading: const Icon(Icons.arrow_forward_rounded),
                        title: Text(
                          '${_profileName(transfer.fromPlayerId, profiles)} → ${_profileName(transfer.toPlayerId, profiles)}',
                        ),
                        trailing: Text('${transfer.amount} $unit'),
                      ),
                    ),
                ],
                if (result.isBalanced && result.transfers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('当前没有需要转账的差额。'),
                  ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _shareImage(_summaryText(result, ranking, unit)),
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('分享结算图片'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, int> _scoreTotalsForSession(
  Iterable<Round> rounds,
  String sessionId,
) {
  final totals = <String, int>{};
  for (final round in rounds) {
    if (round.sessionId != sessionId || round.isDeleted) continue;
    for (final change in round.changes) {
      totals.update(
        change.playerId,
        (value) => value + change.value,
        ifAbsent: () => change.value,
      );
    }
  }
  return totals;
}

String _memberLabel(RoomMember member, Map<String, User> profiles) {
  return profiles[member.userId]?.nickname ?? '玩家 ${_shortId(member.userId)}';
}

String _scoreUnitLabel(ScoringMode mode) {
  return mode == ScoringMode.money ? '金额' : '积分';
}

int _sumChanges(Iterable<ScoreChange> changes) {
  return changes.fold<int>(0, (sum, change) => sum + change.value);
}

String _profileName(String userId, Map<String, User> profiles) {
  return profiles[userId]?.nickname ?? '玩家 ${_shortId(userId)}';
}

String _initialFor(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

class _AvatarPreset {
  const _AvatarPreset({
    required this.key,
    required this.emoji,
    required this.color,
  });

  final String key;
  final String emoji;
  final Color color;
}

const _avatarPresets = <_AvatarPreset>[
  _AvatarPreset(key: 'preset:leaf', emoji: '🍃', color: Color(0xFF2F7D68)),
  _AvatarPreset(key: 'preset:sun', emoji: '☀️', color: Color(0xFFE29B2D)),
  _AvatarPreset(key: 'preset:wave', emoji: '🌊', color: Color(0xFF3B82A0)),
  _AvatarPreset(key: 'preset:star', emoji: '⭐', color: Color(0xFF7B61A8)),
  _AvatarPreset(key: 'preset:fire', emoji: '🔥', color: Color(0xFFD65A43)),
  _AvatarPreset(key: 'preset:moon', emoji: '🌙', color: Color(0xFF44546A)),
];

_AvatarPreset? _avatarPresetFor(String? key) {
  for (final preset in _avatarPresets) {
    if (preset.key == key) return preset;
  }
  return null;
}

class _AvatarPresetDialog extends StatelessWidget {
  const _AvatarPresetDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择预设头像'),
      content: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final preset in _avatarPresets)
            InkWell(
              onTap: () => Navigator.pop(context, preset.key),
              borderRadius: BorderRadius.circular(36),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: preset.color,
                child: Text(preset.emoji, style: const TextStyle(fontSize: 25)),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    this.avatarKey,
    this.avatarUrl,
    this.radius = 20,
  });

  final String name;
  final String? avatarKey;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final preset = _avatarPresetFor(avatarKey);
    final fallback = Text(
      preset?.emoji ?? _initialFor(name),
      style: preset == null ? null : const TextStyle(fontSize: 20),
    );
    final image = url == null || url.isEmpty
        ? null
        : Image.network(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );
    return CircleAvatar(
      radius: radius,
      backgroundColor: preset?.color,
      child: image == null ? fallback : ClipOval(child: image),
    );
  }
}

class _ConnectedActionButton extends StatelessWidget {
  const _ConnectedActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: primary
            ? const Color(0xFF2F7D68)
            : const Color(0xFFE8E5DA),
        foregroundColor: primary ? Colors.white : const Color(0xFF17342F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _ConnectedRoomTile extends StatelessWidget {
  const _ConnectedRoomTile({required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.groups_rounded)),
        title: Text(room.name),
        subtitle: Text(
          '${room.members.where((member) => member.isActive).length} 位成员 · ${room.gameType}',
        ),
        trailing: Text(_roomStatusLabel(room.status)),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.roundCount,
    required this.onRecord,
    required this.onStart,
    required this.onDelete,
    required this.onRename,
    required this.onReopen,
    required this.onFinish,
    required this.onHistory,
    required this.onSettlement,
    required this.canRecord,
    required this.canManage,
    required this.readOnly,
  });

  final GameSession session;
  final int roundCount;
  final VoidCallback onRecord;
  final VoidCallback onStart;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onReopen;
  final VoidCallback onFinish;
  final VoidCallback onHistory;
  final VoidCallback onSettlement;
  final bool canRecord;
  final bool canManage;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(_sessionStatusLabel(session.status)),
              ],
            ),
            const SizedBox(height: 6),
            Text('$roundCount 局'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onHistory,
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('回合记录'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSettlement,
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('看结算'),
                  ),
                ),
              ],
            ),
            if (session.status == GameSessionStatus.draft) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: canManage && !readOnly ? onStart : null,
                      child: const Text('开始牌局'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canManage && !readOnly ? onDelete : null,
                      child: const Text('删除草稿'),
                    ),
                  ),
                ],
              ),
            ],
            if (session.status == GameSessionStatus.active) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canRecord ? onRecord : null,
                      child: const Text('录入一局'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: canManage && !readOnly ? onFinish : null,
                      child: const Text('结束牌局'),
                    ),
                  ),
                ],
              ),
            ],
            if (session.status == GameSessionStatus.finished && canManage) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: readOnly ? null : onReopen,
                      child: const Text('重新打开'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: readOnly ? null : onRename,
                      child: const Text('重命名'),
                    ),
                  ),
                ],
              ),
            ],
            if (session.status != GameSessionStatus.finished && canManage) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: readOnly ? null : onRename,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('重命名'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.error_outline_rounded),
        title: const Text('加载失败'),
        subtitle: Text(message),
        trailing: IconButton(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
    );
  }
}

class _RoomAccessErrorCard extends StatelessWidget {
  const _RoomAccessErrorCard({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48),
                const SizedBox(height: 12),
                const Text(
                  '房间访问已变化',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: onBack, child: const Text('返回')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomFormValue {
  const _RoomFormValue({
    required this.name,
    required this.gameType,
    required this.scoringMode,
  });

  final String name;
  final String gameType;
  final ScoringMode scoringMode;
}

class _RoomFormDialog extends StatefulWidget {
  const _RoomFormDialog({
    this.title = '创建房间',
    this.submitLabel = '创建',
    this.initialName = '',
    this.initialGameType = '掼蛋',
    this.initialScoringMode = ScoringMode.points,
  });

  final String title;
  final String submitLabel;
  final String initialName;
  final String initialGameType;
  final ScoringMode initialScoringMode;

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _gameTypeController;
  late ScoringMode _scoringMode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _gameTypeController = TextEditingController(text: widget.initialGameType);
    _scoringMode = widget.initialScoringMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '房间名称'),
          ),
          TextField(
            controller: _gameTypeController,
            decoration: const InputDecoration(labelText: '玩法'),
          ),
          DropdownButtonFormField<ScoringMode>(
            initialValue: _scoringMode,
            decoration: const InputDecoration(labelText: '记分方式'),
            items: const [
              DropdownMenuItem(value: ScoringMode.points, child: Text('积分')),
              DropdownMenuItem(value: ScoringMode.money, child: Text('金额')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _scoringMode = value);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final gameType = _gameTypeController.text.trim();
            if (name.isEmpty || gameType.isEmpty) {
              setState(() => _error = '请填写房间名称和玩法');
              return;
            }
            Navigator.pop(
              context,
              _RoomFormValue(
                name: name,
                gameType: gameType,
                scoringMode: _scoringMode,
              ),
            );
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _JoinRoomDialog extends StatefulWidget {
  const _JoinRoomDialog();

  @override
  State<_JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<_JoinRoomDialog> {
  final _codeController = TextEditingController();

  Future<void> _scanInvite() async {
    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _InviteScannerPage()),
    );
    if (!mounted || scannedValue == null) return;
    _codeController
      ..text = scannedValue
      ..selection = TextSelection.collapsed(offset: scannedValue.length);
    setState(() {});
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('加入房间'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: '邀请码或分享链接'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _scanInvite,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('扫码'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _codeController.text),
          child: const Text('加入'),
        ),
      ],
    );
  }
}

class _InviteScannerPage extends StatefulWidget {
  const _InviteScannerPage();

  @override
  State<_InviteScannerPage> createState() => _InviteScannerPageState();
}

class _InviteScannerPageState extends State<_InviteScannerPage> {
  String? _errorMessage;
  String? _lastScannedValue;
  bool _isClosing = false;

  void _handleDetection(BarcodeCapture capture) {
    if (_isClosing) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null ||
          rawValue.isEmpty ||
          rawValue == _lastScannedValue) {
        continue;
      }
      _lastScannedValue = rawValue;
      final token = const InviteService().extractToken(rawValue);
      if (token == null) {
        if (mounted) {
          setState(() => _errorMessage = '二维码不是有效的牌账邀请链接');
        }
        return;
      }
      _isClosing = true;
      Navigator.of(context).pop(rawValue);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫描邀请二维码')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(onDetect: _handleDetection),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.initialValue = '',
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: widget.label),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) {
              setState(() => _error = '内容不能为空');
              return;
            }
            Navigator.pop(context, value);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _ScoreDialog extends StatefulWidget {
  const _ScoreDialog({
    required this.members,
    required this.profiles,
    required this.scoringMode,
    this.initialChanges = const [],
    this.initialNote,
    this.title = '录入一局分数',
  });

  final List<RoomMember> members;
  final Map<String, User> profiles;
  final ScoringMode scoringMode;
  final List<ScoreChange> initialChanges;
  final String? initialNote;
  final String title;

  @override
  State<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<_ScoreDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final member in widget.members.where(_shouldShowMember))
      member.userId: TextEditingController(
        text: _initialValue(member.userId)?.toString() ?? '',
      ),
  };
  late final TextEditingController _noteController = TextEditingController(
    text: widget.initialNote ?? '',
  );
  String? _error;

  int? _initialValue(String playerId) {
    for (final change in widget.initialChanges) {
      if (change.playerId == playerId) return change.value;
    }
    return null;
  }

  bool _shouldShowMember(RoomMember member) {
    return member.isActive ||
        widget.initialChanges.any((change) => change.playerId == member.userId);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final changes = <ScoreChange>[];
    for (final entry in _controllers.entries) {
      final rawValue = entry.value.text.trim();
      if (rawValue.isEmpty) continue;
      final value = int.tryParse(rawValue);
      if (value == null) {
        setState(() => _error = '请输入有效的整数分数');
        return;
      }
      if (value != 0) {
        changes.add(ScoreChange(playerId: entry.key, value: value));
      }
    }
    if (changes.isEmpty) {
      setState(() => _error = '至少填写一项非零分数');
      return;
    }
    if (widget.scoringMode == ScoringMode.money && _sumChanges(changes) != 0) {
      setState(() => _error = '金额模式每局必须平账，当前差额为 ${_sumChanges(changes)}');
      return;
    }
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      _ScoreInput(changes: changes, note: note.isEmpty ? null : note),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final member in widget.members.where(_shouldShowMember))
              TextField(
                controller: _controllers[member.userId],
                readOnly: !member.isActive,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: _profileName(member.userId, widget.profiles),
                  helperText: member.isActive ? null : '已离开成员，历史分数会保留',
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('继续')),
      ],
    );
  }
}

String _shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
