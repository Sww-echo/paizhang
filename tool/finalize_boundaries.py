from pathlib import Path
root = Path(__file__).resolve().parents[1]

p = root/'lib/presentation/auth_pages.dart'
s=p.read_text(); a=s.index('class _AuthGateState '); b=s.index('class SignInPage ',a)
s=s[:a]+'''class _AuthGateState extends State<AuthGate> {
  late final InviteController _invites;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState> _navigationKey = GlobalKey<NavigatorState>();
  String? _actorId;

  @override
  void initState() {
    super.initState();
    _invites = InviteController(repository: widget.services.rooms!, onRoomReady: (room) {
      final actor = widget.services.currentUser?.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.services.currentUser?.id != actor) return;
        _navigationKey.currentState?.push(MaterialPageRoute(
          builder: (_) => ConnectedRoomPage(services: widget.services, room: room)));
      });
    });
    _invites.addListener(_showInviteError);
    widget.services.session.addListener(_sessionChanged);
    _sessionChanged();
    if (widget.linkStream == null) _appLinks = AppLinks();
    _linkSubscription = (widget.linkStream ?? _appLinks!.uriLinkStream)
        .listen(_invites.receiveUri, onError: (Object error) {});
    unawaited(_loadInitialLink());
  }

  void _sessionChanged() {
    final actor = widget.services.currentUser?.id;
    if (_actorId != actor) _navigationKey = GlobalKey<NavigatorState>();
    _actorId = actor;
    _invites.setActor(actor);
  }

  Future<void> _loadInitialLink() async {
    if (kIsWeb) _invites.receiveUri(Uri.base);
    try {
      final link = await (widget.initialLink?.call() ?? _appLinks?.getInitialLink());
      if (mounted && link != null) _invites.receiveUri(link);
    } catch (_) {}
  }

  void _showInviteError() {
    if (!mounted || _invites.error == null) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_invites.error!.message),
        action: _invites.canRetry ? SnackBarAction(label: '重试',
            onPressed: () => unawaited(_invites.retryFailed())) : null));
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
      return Navigator(key: _navigationKey,
        onGenerateRoute: (settings) => MaterialPageRoute(settings: settings,
            builder: (_) => ConnectedHomeShell(services: widget.services)));
    });
}

'''+s[b:]
s=s.replace('_message = error.toString()', '_message = mapAppError(error).message')
p.write_text(s)

p=root/'lib/presentation/history_pages.dart'; s=p.read_text()
a=s.index('class _ConnectedHistoryPageState '); b=s.index('class RoomHistoryPage ',a)
s=s[:a]+'''class _ConnectedHistoryPageState extends State<ConnectedHistoryPage> {
  final List<HistoryRoomSummary> _history = [];
  bool _loading = false;
  bool _hasMore = true;
  AppError? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMore());
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = null; });
    final generation = _generation;
    try {
      final values = await widget.services.rooms!.listHistoryRooms(
          before: _history.isEmpty ? null : _history.last);
      if (!mounted || generation != _generation) return;
      final ids = _history.map((room) => room.roomId).toSet();
      setState(() {
        _history.addAll(values.where((room) => !ids.contains(room.roomId)));
        _hasMore = values.length == 20;
      });
    } catch (error) {
      if (mounted && generation == _generation) setState(() => _error = mapAppError(error));
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() { _generation++; _history.clear(); _hasMore = true; });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('历史记录')),
    body: RefreshIndicator(onRefresh: _refresh, child: ListView(
      physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20),
      children: [
        if (_history.isEmpty && !_loading && _error == null)
          const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('还没有历史牌局'))),
        for (final history in _history)
          _HistoryRoomCard(key: ValueKey('${history.roomId}:$_generation'),
              services: widget.services, history: history),
        if (_error != null) ErrorCard(message: _error!.message, onRetry: _loadMore),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_hasMore && !_loading && _error == null)
          TextButton(onPressed: _loadMore, child: const Text('加载更多房间')),
      ],
    )),
  );
}

class _HistoryRoomCard extends StatefulWidget {
  const _HistoryRoomCard({required this.services, required this.history, super.key});
  final AppServices services;
  final HistoryRoomSummary history;
  @override
  State<_HistoryRoomCard> createState() => _HistoryRoomCardState();
}

class _HistoryRoomCardState extends State<_HistoryRoomCard> {
  final List<HistorySessionSummary> _sessions = [];
  bool _loading = false;
  bool _hasMore = true;
  bool _opening = false;
  AppError? _error;

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = null; });
    try {
      final values = await widget.services.rooms!.listHistorySessions(widget.history.roomId,
          before: _sessions.isEmpty ? null : _sessions.last);
      if (!mounted) return;
      final ids = _sessions.map((value) => value.session.id).toSet();
      setState(() {
        _sessions.addAll(values.where((value) => !ids.contains(value.session.id)));
        _hasMore = values.length == 20;
      });
    } catch (error) {
      if (mounted) setState(() => _error = mapAppError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(HistorySessionSummary value) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final snapshot = await widget.services.rooms!.getHistorySession(widget.history.roomId, value.session.id);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettlementPage(
        room: snapshot.room, session: snapshot.sessions.single,
        rounds: snapshot.rounds, profiles: snapshot.profiles)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(elevation: 0, child: ExpansionTile(
    leading: const CircleAvatar(child: Icon(Icons.groups_rounded)),
    title: Text(widget.history.name),
    subtitle: Text('${widget.history.sessionCount} 场牌局 · ${widget.history.isCurrentMember ? '当前成员' : '已离开/被移除'}'),
    onExpansionChanged: (expanded) { if (expanded && _sessions.isEmpty) unawaited(_loadMore()); },
    children: [
      if (_opening) const LinearProgressIndicator(),
      for (final value in _sessions)
        ListTile(title: Text(value.session.name),
          subtitle: Text('${value.roundCount} 局有效记录 · ${sessionStatusLabel(value.session.status)}'),
          trailing: Text(formatHistoryDate(value.lastActivityAt)),
          onTap: _opening ? null : () => _open(value)),
      if (_error != null) ErrorCard(message: _error!.message, onRetry: _loadMore),
      if (_loading) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
      if (_hasMore && !_loading && _error == null)
        TextButton(onPressed: _loadMore, child: const Text('加载更多牌局')),
    ],
  ));
}

'''+s[b:]
a=s.index('class HistoryRoomData '); s=s[:a]
s="import 'dart:async';\nimport '../domain/app_error.dart';\nimport '../infrastructure/backend/app_error_mapper.dart';\n"+s
p.write_text(s)

p=root/'lib/infrastructure/backend/supabase_room_repository.dart'; s=p.read_text()
for start,end in [
 ('class RoundWriteResult ', 'class SupabaseRoomRepository '),
 ('  Future<Round> recordRound({', '  Future<List<Round>> listRounds('),
 ('  Future<Round> _getRound(', '  String _requireUserId()'),
 ('  String? _uuidOrNull(', '  Room _roomFromRow('),
]:
    a=s.index(start); b=s.index(end,a); s=s[:a]+s[b:]
a=s.index('  bool _isRetryableSyncError('); s=s[:a]+'}\n'
s=s.replace("import '../local/app_database.dart';\n",'').replace("import '../local/sync_queue.dart';\n",'')
p.write_text(s)

p=root/'test/infrastructure/local_database_test.dart'; s=p.read_text()
s="import 'package:paizhang/domain/app_error.dart';\n"+s
s=s.replace('LocalRoomCache(database)', "LocalRoomCache(database, actorId: 'user-1')")
s=s.replace('SyncQueue(database)', "SyncQueue(database, currentActorId: () => 'user-1')")
s=s.replace('database.pendingOperations()', "database.pendingOperations(actorId: 'user-1')")
s=s.replace("StateError('network')", "const AppError(AppErrorKind.network, '网络不可用')")
s=s.replace("contains('network')", "contains('网络')")
p.write_text(s)

p=root/'test/domain/paizhang_service_test.dart'; s=p.read_text()
a=s.index("  test('金额模式拒绝未平衡回合'"); b=s.index("  test('仅房主录入模式",a)
block=s[a:b]
block=block.replace('    final game = service.startGame(', '''    service.joinByToken(userId: player.id,
        token: service.createInvite(roomId: room.id, kind: InviteKind.link).token);
    final game = service.startGame(''')
block=block.replace('throwsA(isA<PaizhangException>()),', '''throwsA(isA<PaizhangException>().having(
          (error) => error.message, 'message', '金额模式下本局金额必须平衡')),''')
s=s[:a]+block+s[b:]; p.write_text(s)
print('Finished auth/history boundaries, removed legacy write APIs, and aligned existing tests.')
