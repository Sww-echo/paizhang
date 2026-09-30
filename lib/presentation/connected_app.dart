import 'dart:async';

import 'package:flutter/material.dart';

import '../application/app_services.dart';
import '../domain/models.dart';
import '../infrastructure/backend/room_sync_coordinator.dart';
import '../infrastructure/backend/supabase_room_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({required this.services, super.key});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final auth = services.auth;
    final client = services.client;
    if (auth == null || client == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        final user = client.auth.currentUser;
        if (user == null) return SignInPage(services: services);
        return ConnectedHomeShell(services: services);
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
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _codeRequested = false;
  bool _busy = false;
  String? _message;

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
    _identifierController.dispose();
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    await _run(() async {
      final identifier = _identifierController.text.trim();
      await widget.services.auth!.requestCode(identifier);
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _message = '验证码已发送，请检查邮箱或短信';
      });
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

class ConnectedHomePage extends StatelessWidget {
  const ConnectedHomePage({
    required this.services,
    required this.onMessage,
    required this.onRoomsChanged,
    super.key,
  });

  final AppServices services;
  final ValueChanged<String> onMessage;
  final VoidCallback onRoomsChanged;

  Future<void> _createRoom(BuildContext context) async {
    final values = await showDialog<_RoomFormValue>(
      context: context,
      builder: (context) => const _RoomFormDialog(),
    );
    if (values == null || !context.mounted) return;
    try {
      final room = await services.rooms!.createRoom(
        name: values.name,
        gameType: values.gameType,
        scoringMode: values.scoringMode,
      );
      onRoomsChanged();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConnectedRoomPage(services: services, room: room),
        ),
      );
    } catch (error) {
      onMessage(error.toString());
    }
  }

  Future<void> _joinRoom(BuildContext context) async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _JoinRoomDialog(),
    );
    if (code == null || !context.mounted) return;
    try {
      final roomId = await services.rooms!.joinByCode(code);
      final room = await services.rooms!.getRoom(roomId);
      onRoomsChanged();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConnectedRoomPage(services: services, room: room),
        ),
      );
    } catch (error) {
      onMessage(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = services.client!.auth.currentUser;
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
                onPressed: () => _createRoom(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ConnectedActionButton(
                icon: Icons.login_rounded,
                label: '加入房间',
                onPressed: () => _joinRoom(context),
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
    final values = await showDialog<_RoomFormValue>(
      context: context,
      builder: (context) => const _RoomFormDialog(),
    );
    if (values == null) return;
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
    } catch (error) {
      widget.onMessage(error.toString());
    }
  }

  Future<void> _joinRoom() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _JoinRoomDialog(),
    );
    if (code == null) return;
    try {
      final roomId = await widget.services.rooms!.joinByCode(code);
      final room = await widget.services.rooms!.getRoom(roomId);
      if (!mounted) return;
      setState(_reload);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
    } catch (error) {
      widget.onMessage(error.toString());
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
                        onPressed: _createRoom,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ConnectedActionButton(
                        icon: Icons.login_rounded,
                        label: '加入房间',
                        onPressed: _joinRoom,
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

  @override
  void initState() {
    super.initState();
    _snapshotFuture = widget.services.rooms!.getRoomSnapshot(widget.room.id);
    _sync = widget.services.createRoomSyncCoordinator(
      onRefresh: () async => _reloadSnapshot(),
    );
    unawaited(_sync.start(widget.room.id));
  }

  void _reloadSnapshot() {
    if (mounted) setState(() => _snapshotFuture = _loadSnapshot());
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

  @override
  void dispose() {
    unawaited(_sync.stop());
    super.dispose();
  }

  Future<void> _createInvite() async {
    try {
      final invite = await widget.services.rooms!.createInvite(
        roomId: widget.room.id,
        kind: InviteKind.code,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('房间邀请码'),
          content: SelectableText(invite.code),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createSession() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _TextInputDialog(
        title: '创建牌局',
        label: '牌局名称',
        confirmLabel: '创建',
      ),
    );
    if (name == null) return;
    try {
      final session = await widget.services.rooms!.createGameSession(
        roomId: widget.room.id,
        name: name,
      );
      await widget.services.rooms!.startGameSession(session.id);
      _reloadSnapshot();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _recordRound(
    GameSession session,
    RemoteRoomSnapshot snapshot,
  ) async {
    final existingRounds = snapshot.rounds
        .where((round) => round.sessionId == session.id)
        .toList();
    final changes = await showDialog<List<ScoreChange>>(
      context: context,
      builder: (context) => _ScoreDialog(members: snapshot.room.members),
    );
    if (changes == null || changes.isEmpty) return;
    try {
      final result = await widget.services.rooms!.recordRoundWithQueue(
        queue: widget.services.queue,
        sessionId: session.id,
        roundNumber: existingRounds.length + 1,
        changes: changes,
      );
      if (result.queued) {
        await widget.services.cache.saveRound(result.round);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('当前网络不可用，分数已保存，稍后自动同步')));
        }
      } else {
        _reloadSnapshot();
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _finishSession(GameSession session) async {
    try {
      await widget.services.rooms!.finishGameSession(session.id);
      _reloadSnapshot();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.name),
        actions: [
          IconButton(
            onPressed: _createInvite,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: '生成邀请码',
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
            return _ErrorCard(
              message: snapshot.error.toString(),
              onRetry: _reloadSnapshot,
            );
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: Text('${data.room.members.length} 位成员'),
                  subtitle: Text(data.room.gameType),
                  trailing: Text(data.room.status.name),
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
                    onPressed: _createSession,
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
                    onFinish: () => _finishSession(session),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class ConnectedProfilePage extends StatelessWidget {
  const ConnectedProfilePage({required this.services, super.key});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final user = services.client!.auth.currentUser;
    final nickname = user?.userMetadata?['nickname'] as String?;
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
            leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text(nickname ?? user?.email ?? user?.phone ?? '牌友'),
            subtitle: Text(user?.email ?? user?.phone ?? ''),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: () => services.auth!.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('退出登录'),
        ),
      ],
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
  final VoidCallback onPressed;
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
        subtitle: Text('${room.members.length} 位成员 · ${room.gameType}'),
        trailing: Text(room.status.name),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.roundCount,
    required this.onRecord,
    required this.onFinish,
  });

  final GameSession session;
  final int roundCount;
  final VoidCallback onRecord;
  final VoidCallback onFinish;

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
                Text(session.status.name),
              ],
            ),
            const SizedBox(height: 6),
            Text('$roundCount 局'),
            if (session.status == GameSessionStatus.active) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRecord,
                      child: const Text('录入一局'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: onFinish,
                      child: const Text('结束牌局'),
                    ),
                  ),
                ],
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
  const _RoomFormDialog();

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _nameController = TextEditingController();
  final _gameTypeController = TextEditingController(text: '掼蛋');
  ScoringMode _scoringMode = ScoringMode.points;

  @override
  void dispose() {
    _nameController.dispose();
    _gameTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建房间'),
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _RoomFormValue(
                name: _nameController.text,
                gameType: _gameTypeController.text,
                scoringMode: _scoringMode,
              ),
            );
          },
          child: const Text('创建'),
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('加入房间'),
      content: TextField(
        controller: _codeController,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(labelText: '邀请码'),
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

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
  });

  final String title;
  final String label;
  final String confirmLabel;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _ScoreDialog extends StatefulWidget {
  const _ScoreDialog({required this.members});

  final List<RoomMember> members;

  @override
  State<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<_ScoreDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final member in widget.members.where((member) => member.isActive))
      member.userId: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final changes = <ScoreChange>[];
    for (final entry in _controllers.entries) {
      final value = int.tryParse(entry.value.text.trim());
      if (value != null) {
        changes.add(ScoreChange(playerId: entry.key, value: value));
      }
    }
    Navigator.pop(context, changes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('录入一局分数'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final member in widget.members.where(
              (member) => member.isActive,
            ))
              TextField(
                controller: _controllers[member.userId],
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: '玩家 ${_shortId(member.userId)}',
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
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

String _shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
