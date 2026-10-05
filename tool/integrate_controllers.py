from pathlib import Path

root = Path(__file__).resolve().parents[1]
p = root / 'lib/presentation/room_page.dart'
s = p.read_text()
def replace_section(start, end, replacement):
    global s
    a = s.index(start)
    b = s.index(end, a)
    s = s[:a] + replacement + s[b:]
replace_section('  late Future<RemoteRoomSnapshot> _snapshotFuture;', '  GameSession? _selectedActiveSession(', '''  late final RoomController _controller;
  String? _selectedSessionId;
  bool _actionBusy = false;

  Future<RoomSnapshot> get _snapshotFuture async {
    if (_controller.snapshot != null) return _controller.snapshot!;
    await _controller.refresh();
    final snapshot = _controller.snapshot;
    if (snapshot == null) throw _controller.error ??
        const AppError(AppErrorKind.network, '暂无可用房间数据');
    return snapshot;
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.services.createRoomController(widget.room.id);
    unawaited(_controller.start());
  }

  void _reloadSnapshot() => unawaited(_controller.refresh());

''')
replace_section('  bool _canInputRoom(', '  Future<void> _createInvite()', '''  bool _canInputRoom(Room room) => _controller.canInput;
  bool _isRoomOwner(Room room) => _controller.canManage;
  bool _canEditRound(RoomSnapshot snapshot, Round round) => _controller.canEdit(round);

  Future<void> _runRoomAction(Future<void> Function() action) async {
    if (!mounted || _actionBusy || _controller.busy) return;
    try {
      await _controller.runAction(action);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  void dispose() {
    widget.services.releaseRoomController(_controller);
    super.dispose();
  }

''')
replace_section('  Future<void> _recordRound(', '  Future<void> _showRoundHistory(', '''  Future<void> _recordRound(GameSession session, RoomSnapshot snapshot) async {
    if (!_controller.canInput) return;
    final input = await _showScoreInput(snapshot);
    if (input == null || !mounted) return;
    await _runRoomAction(() async {
      await _controller.recordRound(session.id, input.changes, note: input.note);
      _showSuccess('记录已保存到本机，正在同步');
    });
  }

  Future<void> _editRound(RoomSnapshot snapshot, Round round) async {
    if (!_controller.canEdit(round)) return;
    final input = await _showScoreInput(snapshot, initialChanges: round.changes,
        initialNote: round.note, title: '编辑第 ${round.number} 局');
    if (input == null || !mounted) return;
    await _runRoomAction(() async {
      await _controller.updateRound(round, input.changes, note: input.note);
      _showSuccess('修改已保存到本机，正在同步');
    });
  }

  Future<void> _deleteRound(RoomSnapshot snapshot, Round round) async {
    if (!_controller.canEdit(round)) return;
    final confirmed = await _confirmAction(title: '撤销第 ${round.number} 局？',
        message: '这局会保留在历史记录中，但不再计入总分。', confirmLabel: '撤销');
    if (!confirmed || !mounted) return;
    await _runRoomAction(() => _controller.deleteRound(round));
  }

  Future<void> _restoreRound(RoomSnapshot snapshot, Round round) async {
    if (!_controller.canEdit(round)) return;
    await _runRoomAction(() => _controller.updateRound(round, round.changes, note: round.note));
  }

''')
replace_section('  Future<void> _transferScore(', '  Future<void> _finishSession(', '''  Future<void> _transferScore(RoomSnapshot snapshot, {
    required GameSession session, String? fromPlayerId,
  }) async {
    if (!_controller.canInput || session.status != GameSessionStatus.active) return;
    final transfer = await showDialog<ScoreTransfer>(context: context,
      builder: (context) => ScoreTransferDialog(members: snapshot.room.members,
        profiles: snapshot.profiles,
        totals: _controller.totalsBySession[session.id] ?? const {},
        scoringMode: snapshot.room.scoringMode, initialFromPlayerId: fromPlayerId));
    if (transfer == null || !mounted) return;
    await _runRoomAction(() async {
      await _controller.recordRound(session.id, [
        ScoreChange(playerId: transfer.fromPlayerId, value: -transfer.amount),
        ScoreChange(playerId: transfer.toPlayerId, value: transfer.amount),
      ], note: '${scoreUnitLabel(snapshot.room.scoringMode)}转换');
      _showSuccess('转换已保存到本机，正在同步');
    });
  }

''')
replace_section('  void _handleSyncError(', '  void _showSuccess(', '')
replace_section('  bool _isRoomAccessError(', '  @override\n  Widget build(', '''  bool _isRoomAccessError(Object error) => mapAppError(error).isAccessError;
  String _friendlyErrorMessage(Object error) =>
      error is String ? error : mapAppError(error).message;

  Future<void> _resolveOperation(SyncQueueEntry entry) async {
    await _runRoomAction(() async {
      final draft = await _controller.prepareReapply(entry);
      if (!mounted) return;
      String describe(Round? round) => round == null ? '尚未创建' :
          '${round.isDeleted ? '已撤销；' : ''}${round.changes.map((change) =>
            '${profileName(change.playerId, _controller.snapshot?.profiles ?? {})} ${change.value}').join('，')}';
      final confirmed = await _confirmAction(title: '重新确认这条记录',
        message: '服务器当前：${describe(draft.current)}\\n本地草稿：${describe(draft.desired)}\\n'
            '确认后将按最新版本重新提交草稿，并处理该回合依赖的本地修改。',
        confirmLabel: '重新提交');
      if (confirmed && mounted) await _controller.applyRebased(draft);
    });
  }

  Future<void> _discardOperation(SyncQueueEntry entry) async {
    final confirmed = await _confirmAction(title: '放弃本地修改？',
      message: '将放弃此操作及依赖它的本地修改，不会撤销服务器已经保存的内容。',
      confirmLabel: '放弃本地修改');
    if (confirmed && mounted) await _runRoomAction(() => _controller.discard(entry));
  }

''')
s = s.replace('FutureBuilder<RemoteRoomSnapshot>(\n            future: _snapshotFuture,',
              'RoomSnapshotBuilder(\n            controller: _controller,')
s = s.replace('FutureBuilder<RemoteRoomSnapshot>(\n        future: _snapshotFuture,',
              'RoomSnapshotBuilder(\n        controller: _controller,')
s = s.replace('title: Text(widget.room.name),', '''title: AnimatedBuilder(animation: _controller,
            builder: (_, _) => Text(_controller.snapshot?.room.name ?? widget.room.name)),''')
s = s.replace('final canInput = _canInputRoom(data.room);',
              'final canInput = _controller.canInput && !_controller.busy && !_actionBusy;')
s = s.replace('final isOwner = _isRoomOwner(data.room);',
              'final isOwner = _controller.canManage && !_controller.busy && !_actionBusy;')
s = s.replace('scoreTotalsForSession(data.rounds, activeSession.id)',
              '(_controller.totalsBySession[activeSession.id] ?? const <String, int>{})')
s = s.replace('''roundCount: data.rounds
                        .where((round) => round.sessionId == session.id)
                        .length,''', '''roundCount: (_controller.roundsBySession[session.id] ?? const <Round>[])
                        .where((round) => !round.isDeleted).length,''')
s = s.replace('''          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
''', '''          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SyncStatusPanel(controller: _controller,
                onResolve: _resolveOperation, onDiscard: _discardOperation,
                onRetry: (entry) => _runRoomAction(() => _controller.retry(entry))),
''')
s = s.replace("import 'presentation_helpers.dart';", "import 'presentation_helpers.dart';\nimport 'sync_status_panel.dart';")
s = s.replace('widget.services.client?.auth.currentUser?.id', 'widget.services.currentUser?.id')
s += '''
class RoomSnapshotBuilder extends StatelessWidget {
  const RoomSnapshotBuilder({required this.controller, required this.builder, super.key});
  final RoomController controller;
  final AsyncWidgetBuilder<RoomSnapshot> builder;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller,
    builder: (context, _) {
      final data = controller.snapshot;
      if (data != null) return builder(context, AsyncSnapshot.withData(ConnectionState.done, data));
      if (controller.loading) return builder(context, const AsyncSnapshot.waiting());
      return builder(context, AsyncSnapshot.withError(ConnectionState.done,
          controller.error ?? const AppError(AppErrorKind.network, '暂无可用房间数据')));
    });
}
'''
assert 'recordRoundWithQueue' not in s and 'createRoomSyncCoordinator' not in s
p.write_text(s)

p = root / 'lib/presentation/home_pages.dart'
s = p.read_text()
a=s.index('class _ConnectedHomeShellState '); b=s.index('  void _showMessage(',a)
s=s[:a]+'''class _ConnectedHomeShellState extends State<ConnectedHomeShell> {
  int _selectedIndex = 0;

'''+s[b:]
s=s.replace('onRoomsChanged: () => setState(() {}),','onRoomsChanged: widget.services.invalidateRooms,')
s=s.replace('body: SafeArea(child: pages[_selectedIndex]),',
            'body: SafeArea(child: IndexedStack(index: _selectedIndex, children: pages)),')
s=s.replace('widget.services.client!.auth.currentUser','widget.services.currentUser')
s=s.replace("user?.userMetadata?['nickname'] ?? user?.email ?? '牌友'", "user?.nickname ?? '牌友'")
a=s.index('  @override\n  void initState()', s.index('class _ConnectedRoomsPageState'))
b=s.index('  Future<void> _refresh()',a)
s=s[:a]+'''  @override
  void initState() {
    super.initState();
    _roomsFuture = widget.services.loadRooms();
    widget.services.roomList.addListener(_onRoomsChanged);
  }

  void _onRoomsChanged() {
    if (mounted) setState(() => _roomsFuture = Future.value(widget.services.roomList.value));
  }

  @override
  void dispose() {
    widget.services.roomList.removeListener(_onRoomsChanged);
    super.dispose();
  }

  void _reload() {
    _roomsFuture = widget.services.loadRooms(force: true);
  }

'''+s[b:]
s=s.replace('widget.onMessage(error.toString());','widget.onMessage(mapAppError(error).message);')
s="import '../infrastructure/backend/app_error_mapper.dart';\n"+s
p.write_text(s)

p=root/'lib/presentation/profile_page.dart'
s=p.read_text().replace('widget.services.client!.auth.currentUser','widget.services.currentUser')
s=s.replace("(user?.userMetadata?['nickname'] as String?)?.trim() ?? ''", "user?.nickname.trim() ?? ''")
s=s.replace("user?.userMetadata?['avatar_key'] as String?", 'user?.avatarKey')
s=s.replace("user?.userMetadata?['avatar_url'] as String?", 'user?.avatarUrl')
s=s.replace('Text(error.toString())','Text(mapAppError(error).message)')
s="import '../infrastructure/backend/app_error_mapper.dart';\n"+s
p.write_text(s)
print('Connected room writes to RoomController; preserved page UI and updated session/list boundaries.')
