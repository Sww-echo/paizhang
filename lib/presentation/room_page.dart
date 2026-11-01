import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../application/app_services.dart';
import '../application/room_controller.dart';
import '../domain/app_error.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../domain/room_snapshot.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import '../infrastructure/local/app_database.dart';
import 'avatar_widgets.dart';
import 'common_widgets.dart';
import 'design.dart';
import 'presentation_helpers.dart';
import 'room_management_page.dart';
import 'room_widgets.dart';
import 'round_history_page.dart';
import 'score_entry_panel.dart';
import 'settlement_page.dart';
import 'sync_status_panel.dart';
import 'transfer_dialog.dart';

/// 房间记分台：结果按累计分排序，输入顺序固定。
/// 主按钮「记一局」，多人转分为次入口，点头像直接进入单人转分。
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
  late final RoomController _controller;
  final ScoreDraftStore _drafts = ScoreDraftStore();
  final _actionBusyNotifier = ValueNotifier(false);
  String? _selectedSessionId;
  bool get _actionBusy => _actionBusyNotifier.value;

  Future<RoomSnapshot> get _snapshotFuture async {
    if (_controller.snapshot != null) return _controller.snapshot!;
    await _controller.refresh();
    final snapshot = _controller.snapshot;
    if (snapshot == null) {
      throw _controller.error ??
          const AppError(AppErrorKind.network, '暂无可用房间数据');
    }
    return snapshot;
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.services.createRoomController(widget.room.id);
    unawaited(_controller.start());
  }

  void _reloadSnapshot() => unawaited(_controller.refresh());

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

  List<GameSession> _activeSessions(RemoteRoomSnapshot snapshot) => snapshot
      .sessions
      .where((session) => session.status == GameSessionStatus.active)
      .toList();

  int _nextRoundNumber(String sessionId) {
    final rounds = _controller.roundsBySession[sessionId] ?? const <Round>[];
    var max = 0;
    for (final round in rounds) {
      if (round.number > max) max = round.number;
    }
    return max + 1;
  }

  Map<String, int> _totalsFor(String sessionId) =>
      _controller.totalsBySession[sessionId] ?? const <String, int>{};

  String _latestRoundSummary(String sessionId) {
    final rounds =
        (_controller.roundsBySession[sessionId] ?? const <Round>[])
            .where((round) => !round.isDeleted)
            .toList()
          ..sort((left, right) => right.number.compareTo(left.number));
    if (rounds.isEmpty) return '尚无回合记录';
    final latest = rounds.first;
    return latest.changes
        .map(
          (change) =>
              '${profileName(change.playerId, _controller.snapshot?.profiles ?? const {})} '
              '${pzSigned(change.value)}',
        )
        .join(' · ');
  }

  List<ScoreEntrySession> _entrySessions(RemoteRoomSnapshot snapshot) => [
    for (final session in _activeSessions(snapshot))
      ScoreEntrySession(
        id: session.id,
        name: session.name,
        nextRoundNumber: _nextRoundNumber(session.id),
        totals: _totalsFor(session.id),
      ),
  ];

  Future<bool> _runRoomAction(Future<void> Function() action) async {
    if (!mounted) return false;
    if (_actionBusy || _controller.busy) {
      _showError('正在处理，请稍后重试');
      return false;
    }
    try {
      await _controller.runAction(action);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<void> _saveScoreAction(Future<void> Function() action) async {
    if (!_controller.isCurrent) {
      throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    }
    if (_actionBusy || _controller.busy) {
      throw const AppError(AppErrorKind.validation, '正在处理，请稍后重试');
    }
    await _controller.runAction(action);
  }

  @override
  void dispose() {
    _actionBusyNotifier.dispose();
    widget.services.releaseRoomController(_controller);
    super.dispose();
  }

  // ── 记分入口 ─────────────────────────────────────────────────────────────

  Future<void> _recordRound(
    RemoteRoomSnapshot snapshot,
    GameSession session,
  ) async {
    if (!_controller.canInput) return;
    final saved = await showPzDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScoreEntryPanel(
        mode: ScoreEntryMode.full,
        actorId: _controller.actorId,
        roomId: snapshot.room.id,
        roomName: snapshot.room.name,
        members: snapshot.room.members
            .where((member) => member.isActive)
            .toList(),
        profiles: snapshot.profiles,
        scoringMode: snapshot.room.scoringMode,
        sessions: _entrySessions(snapshot),
        initialSessionId: session.id,
        drafts: _drafts,
        onSave: (sessionId, changes) =>
            _saveScoreAction(() => _controller.recordRound(sessionId, changes)),
        onSaveWithNote: (sessionId, changes, note) => _saveScoreAction(
          () => _controller.recordRound(sessionId, changes, note: note),
        ),
      ),
    );
    if (saved == true && mounted) {
      _showSuccess('已保存到本机 · 待同步');
    }
  }

  Future<void> _multiTransfer(
    RemoteRoomSnapshot snapshot,
    GameSession session,
  ) async {
    if (_controller.inputDisabledReason(session.id) != null) return;
    final saved = await showPzDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScoreEntryPanel(
        mode: ScoreEntryMode.multi,
        actorId: _controller.actorId,
        roomId: snapshot.room.id,
        roomName: snapshot.room.name,
        members: snapshot.room.members
            .where((member) => member.isActive)
            .toList(),
        profiles: snapshot.profiles,
        scoringMode: snapshot.room.scoringMode,
        sessions: _entrySessions(snapshot),
        initialSessionId: session.id,
        drafts: _drafts,
        onSave: (sessionId, changes) => _saveScoreAction(() {
          final amounts = <String, int>{
            for (final change in changes)
              if (change.playerId != _controller.actorId)
                change.playerId: change.value,
          };
          return _controller.transferScores(sessionId, amounts);
        }),
      ),
    );
    if (saved == true && mounted) {
      _showSuccess('转分已保存到本机 · 待同步');
    }
  }

  Future<void> _transferScore(
    RoomSnapshot snapshot, {
    required GameSession session,
    required String toPlayerId,
  }) async {
    if (!_controller.canInput || session.status != GameSessionStatus.active) {
      return;
    }
    final actorId = _controller.actorId;
    if (actorId == toPlayerId) return;
    final saved = await showPzDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScoreTransferDialog(
        actorId: actorId,
        toPlayerId: toPlayerId,
        members: snapshot.room.members,
        profiles: snapshot.profiles,
        totals: _totalsFor(session.id),
        scoringMode: snapshot.room.scoringMode,
        roomName: snapshot.room.name,
        sessionName: session.name,
        nextRoundNumber: _nextRoundNumber(session.id),
        initialAmount: _drafts.transferAmount(
          actorId: actorId,
          roomId: snapshot.room.id,
          sessionId: session.id,
          recipientId: toPlayerId,
        ),
        onDraftChanged: (raw) => _drafts.setTransferAmount(
          actorId: actorId,
          roomId: snapshot.room.id,
          sessionId: session.id,
          recipientId: toPlayerId,
          raw: raw,
        ),
        onSubmit: (request) => _saveScoreAction(
          () => _controller.transferScores(session.id, {
            request.toPlayerId: request.amount,
          }),
        ),
      ),
    );
    if (saved == true) {
      _drafts.clearTransfer(
        actorId: actorId,
        roomId: snapshot.room.id,
        sessionId: session.id,
        recipientId: toPlayerId,
      );
      if (mounted) _showSuccess('转分已保存到本机 · 待同步');
    }
  }

  Future<void> _editRound(Round requestedRound) async {
    await _controller.refresh();
    if (!mounted) return;
    final currentSnapshot = _controller.snapshot;
    if (currentSnapshot == null) return;
    final round =
        (_controller.roundsBySession[requestedRound.sessionId] ??
                const <Round>[])
            .firstWhere(
              (candidate) => candidate.id == requestedRound.id,
              orElse: () => requestedRound,
            );
    final session = currentSnapshot.sessions.firstWhere(
      (candidate) => candidate.id == round.sessionId,
      orElse: () => currentSnapshot.sessions.first,
    );
    if (!_controller.canEdit(round)) return;
    final store = ScoreDraftStore();
    final draft = store.full(
      actorId: _controller.actorId,
      roomId: currentSnapshot.room.id,
      sessionId: round.sessionId,
    );
    draft.note = round.note ?? '';
    for (final change in round.changes) {
      draft.raw[change.playerId] = '${change.value}';
      draft.sources[change.playerId] = 'manual';
    }
    final participantIds = round.changes
        .map((change) => change.playerId)
        .toSet();
    final members = currentSnapshot.room.members
        .where(
          (member) => member.isActive || participantIds.contains(member.userId),
        )
        .toList();
    // 历史参与者即使不再出现在成员快照中，也必须保留其原值。
    final knownIds = members.map((member) => member.userId).toSet();
    for (final id in participantIds.difference(knownIds)) {
      members.add(
        RoomMember(
          userId: id,
          role: RoomRole.member,
          joinedAt: round.createdAt,
          leftAt: round.createdAt,
        ),
      );
    }
    // 核对页会叠加编辑后的分数，先从累计中扣除该回合的原值。
    final totalsBeforeRound = Map<String, int>.of(_totalsFor(round.sessionId));
    if (!round.isDeleted) {
      for (final change in round.changes) {
        totalsBeforeRound.update(
          change.playerId,
          (total) => total - change.value,
          ifAbsent: () => -change.value,
        );
      }
    }
    final saved = await showPzDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScoreEntryPanel(
        mode: ScoreEntryMode.full,
        title: '编辑第 ${round.number} 回合',
        actorId: _controller.actorId,
        roomId: currentSnapshot.room.id,
        roomName: currentSnapshot.room.name,
        members: members,
        profiles: currentSnapshot.profiles,
        scoringMode: currentSnapshot.room.scoringMode,
        sessions: [
          ScoreEntrySession(
            id: round.sessionId,
            name: session.name,
            nextRoundNumber: round.number,
            totals: totalsBeforeRound,
          ),
        ],
        initialSessionId: round.sessionId,
        drafts: store,
        onSave: (_, changes) => _saveScoreAction(
          () => _controller.updateRound(round, changes, note: round.note),
        ),
        onSaveWithNote: (_, changes, note) => _saveScoreAction(
          () => _controller.updateRound(round, changes, note: note),
        ),
      ),
    );
    if (saved == true && mounted) _showSuccess('修改已保存到本机 · 待同步');
  }

  Future<void> _deleteRound(Round round) async {
    if (!_controller.canEdit(round)) return;
    final confirmed = await pzConfirm(
      context,
      title: '撤销第 ${round.number} 回合？',
      message: '这局会保留在历史记录中，但不再计入总分。',
      confirmLabel: '撤销',
    );
    if (!confirmed || !mounted) return;
    if (!await _runRoomAction(() => _controller.deleteRound(round))) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('已撤销第 ${round.number} 回合'),
          action: SnackBarAction(
            label: '恢复',
            onPressed: () => unawaited(_restoreRound(round)),
          ),
        ),
      );
  }

  Future<void> _restoreRound(Round round) async {
    // 撤销已经把这个回合推到新版本，必须用当前版本当底，否则乐观锁必然冲突。
    final rounds =
        _controller.roundsBySession[round.sessionId] ?? const <Round>[];
    final latest = rounds.firstWhere(
      (candidate) => candidate.id == round.id,
      orElse: () => round,
    );
    if (!_controller.canEdit(latest)) return;
    await _runRoomAction(
      () => _controller.updateRound(latest, latest.changes, note: latest.note),
    );
  }

  Future<RoundHistoryData> _roundHistoryData(String sessionId) async {
    await _controller.refresh();
    final rounds = _controller.roundsBySession[sessionId] ?? const <Round>[];
    final roundIds = rounds.map((round) => round.id).toSet();
    final pending = <String>{};
    final conflicts = <String>{};
    final actorId = widget.services.currentUser?.id;
    final operations = actorId == null
        ? const <SyncQueueEntry>[]
        : await widget.services.database.unresolvedOperations(actorId: actorId);
    for (final entry in operations.where(
      (entry) =>
          entry.entityType == 'round' && roundIds.contains(entry.entityId),
    )) {
      if (entry.status == 'conflict') {
        conflicts.add(entry.entityId);
      } else if (entry.status == 'pending' || entry.status == 'retrying') {
        pending.add(entry.entityId);
      }
    }
    return RoundHistoryData(
      rounds: [...rounds]
        ..sort((left, right) => right.number.compareTo(left.number)),
      pendingRoundIds: pending,
      conflictRoundIds: conflicts,
    );
  }

  Future<void> _showRoundHistory(
    RemoteRoomSnapshot snapshot,
    GameSession session,
  ) async {
    final rounds =
        (snapshot.rounds
              .where((round) => round.sessionId == session.id)
              .toList())
          ..sort((left, right) => right.number.compareTo(left.number));
    final roundIds = rounds.map((round) => round.id).toSet();
    final pending = <String>{};
    final conflicts = <String>{};
    final actorId = widget.services.currentUser?.id;
    final operations = actorId == null
        ? const <SyncQueueEntry>[]
        : await widget.services.database.unresolvedOperations(actorId: actorId);
    for (final entry in operations.where(
      (entry) =>
          entry.entityType == 'round' && roundIds.contains(entry.entityId),
    )) {
      if (entry.status == 'conflict') {
        conflicts.add(entry.entityId);
      } else if (entry.status == 'pending' || entry.status == 'retrying') {
        pending.add(entry.entityId);
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoundHistoryPage(
          roomName: snapshot.room.name,
          session: session,
          rounds: rounds,
          profiles: snapshot.profiles,
          currentUserId: widget.services.currentUser?.id,
          canEdit:
              session.status == GameSessionStatus.active &&
              _controller.canInput,
          pendingRoundIds: pending,
          conflictRoundIds: conflicts,
          onEdit: _editRound,
          onDelete: _deleteRound,
          onRestore: _restoreRound,
          onReload: () => _roundHistoryData(session.id),
        ),
      ),
    );
  }

  Future<void> _showSettlement(
    RemoteRoomSnapshot snapshot,
    GameSession session,
  ) async {
    final sessionRounds = snapshot.rounds
        .where((round) => round.sessionId == session.id)
        .toList();
    final roundIds = sessionRounds.map((round) => round.id).toSet();
    final actorId = widget.services.currentUser?.id;
    final operations = actorId == null
        ? const <SyncQueueEntry>[]
        : await widget.services.database.unresolvedOperations(actorId: actorId);
    final sessionOperations = operations.where(
      (entry) =>
          entry.entityType == 'round' && roundIds.contains(entry.entityId),
    );
    final pendingCount = sessionOperations
        .where(
          (entry) => entry.status == 'pending' || entry.status == 'retrying',
        )
        .length;
    final conflictCount = sessionOperations
        .where((entry) => entry.status == 'conflict')
        .length;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettlementPage(
          room: snapshot.room,
          session: session,
          rounds: sessionRounds,
          profiles: snapshot.profiles,
          currentUserId: widget.services.currentUser?.id,
          pendingCount: pendingCount,
          conflictCount: conflictCount,
        ),
      ),
    );
  }

  // ── 房间管理 ─────────────────────────────────────────────────────────────

  Future<void> _createSession(RemoteRoomSnapshot snapshot) async {
    if (_actionBusy) return;
    if (!_controller.canManage) {
      _showError('只有房主可以创建牌局');
      return;
    }
    final name = await showPzDialog<String>(
      context: context,
      builder: (context) => const _TextInputDialog(
        title: '创建牌局',
        label: '牌局名称',
        confirmLabel: '创建',
      ),
    );
    if (name == null || !mounted) return;
    setState(() => _actionBusyNotifier.value = true);
    try {
      await widget.services.rooms!.createGameSession(
        roomId: snapshot.room.id,
        name: name,
      );
      _reloadSnapshot();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _actionBusyNotifier.value = false);
    }
  }

  Future<void> _startSession(GameSession session) async {
    await _runRoomAction(() async {
      await widget.services.rooms!.startGameSession(
        session.id,
        expectedVersion: session.version,
      );
      _reloadSnapshot();
    });
  }

  Future<void> _deleteDraftSession(GameSession session) async {
    await _runRoomAction(() async {
      await widget.services.rooms!.manageGameSession(
        session.id,
        'delete',
        expectedVersion: session.version,
      );
      _reloadSnapshot();
    });
  }

  Future<void> _renameSession(GameSession session) async {
    final name = await showPzDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog(
        title: '重命名牌局',
        label: '牌局名称',
        confirmLabel: '保存',
        initialValue: session.name,
      ),
    );
    if (name == null || !mounted) return;
    await _runRoomAction(() async {
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
    await _runRoomAction(() async {
      await widget.services.rooms!.manageGameSession(
        session.id,
        'reopen',
        expectedVersion: session.version,
      );
      _reloadSnapshot();
    });
  }

  Future<void> _finishSession(GameSession session) async {
    await _runRoomAction(() async {
      await widget.services.rooms!.finishGameSession(
        session.id,
        expectedVersion: session.version,
      );
      unawaited(HapticFeedback.mediumImpact());
      _reloadSnapshot();
    });
  }

  Future<void> _editRoomDetails(RemoteRoomSnapshot snapshot) async {
    final values = await showPzDialog<RoomFormValue>(
      context: context,
      builder: (context) => RoomFormDialog(
        title: '编辑房间',
        submitLabel: '保存',
        initialName: snapshot.room.name,
        initialGameType: snapshot.room.gameType,
        initialScoringMode: snapshot.room.scoringMode,
      ),
    );
    if (values == null || !mounted) return;
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

  Future<void> _showRoomManagement() async {
    final updates = Listenable.merge([_controller, _actionBusyNotifier]);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimatedBuilder(
          animation: updates,
          builder: (managementContext, _) {
            final snapshot = _controller.snapshot;
            if (snapshot == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('房间管理')),
                body: RoomAccessErrorCard(
                  message: _controller.error?.message ?? '房间访问尚未确认，请返回后重试',
                  onBack: () => Navigator.of(managementContext).pop(),
                ),
              );
            }
            return _buildRoomManagement(managementContext, snapshot);
          },
        ),
      ),
    );
    if (mounted) _reloadSnapshot();
  }

  Widget _buildRoomManagement(
    BuildContext managementContext,
    RemoteRoomSnapshot snapshot,
  ) {
    final roundCounts = <String, int>{
      for (final session in snapshot.sessions)
        session.id: (_controller.roundsBySession[session.id] ?? const <Round>[])
            .where((round) => !round.isDeleted)
            .length,
    };
    return RoomManagementPage(
      room: snapshot.room,
      sessions: snapshot.sessions,
      roundCounts: roundCounts,
      profiles: snapshot.profiles,
      currentUserId: widget.services.currentUser?.id,
      closeVote: snapshot.closeVote,
      canManage: _controller.canManage && !_actionBusy,
      canInput: _controller.canInput && !_actionBusy,
      readOnly: snapshot.room.isClosed,
      hasActiveSession: snapshot.sessions.any(
        (session) => session.status == GameSessionStatus.active,
      ),
      busy: _controller.busy || _controller.refreshing || _actionBusy,
      onEditRoom: () => _editRoomDetails(snapshot),
      onPermissionChanged: (permission) => _runRoomAction(() async {
        await widget.services.rooms!.setInputPermission(
          roomId: snapshot.room.id,
          permission: permission,
        );
        _reloadSnapshot();
      }),
      onInvite: _createInvite,
      onCreateSession: () => _createSession(snapshot),
      onStartSession: _startSession,
      onDeleteSession: _deleteDraftSession,
      onRenameSession: _renameSession,
      onFinishSession: _finishSession,
      onReopenSession: _reopenSession,
      onOpenHistory: (session) => _showRoundHistory(snapshot, session),
      onOpenSettlement: (session) => _showSettlement(snapshot, session),
      onRecordSession: (session) async {
        setState(() => _selectedSessionId = session.id);
        Navigator.of(managementContext).pop();
        await _recordRound(snapshot, session);
      },
      onCastCloseVote: (approved, targetStatus) => _castCloseVote(
        snapshot,
        approved: approved,
        targetStatus: targetStatus,
      ),
      onCancelCloseVote: () {
        final proposalId = snapshot.closeVote?.proposalId;
        if (proposalId == null) return Future.value();
        return _runRoomAction(() async {
          await widget.services.rooms!.cancelCloseVote(
            snapshot.room,
            proposalId,
          );
          _reloadSnapshot();
        });
      },
      onRemoveMember: (userId) => _runRoomAction(() async {
        await widget.services.rooms!.removeMember(
          roomId: snapshot.room.id,
          userId: userId,
        );
        _reloadSnapshot();
      }),
      onTransferOwnership: (userId) => _runRoomAction(() async {
        await widget.services.rooms!.transferOwnership(
          roomId: snapshot.room.id,
          userId: userId,
        );
        _reloadSnapshot();
      }),
      onLeaveRoom: () => _runRoomAction(() async {
        await widget.services.rooms!.leaveRoom(snapshot.room.id);
        if (mounted && managementContext.mounted) {
          Navigator.of(managementContext).pop();
          Navigator.of(context).pop();
        }
      }),
    );
  }

  Future<void> _createInvite() async {
    if (_actionBusy) return;
    setState(() => _actionBusyNotifier.value = true);
    try {
      final snapshot = await _snapshotFuture;
      if (!_controller.canManage) {
        _showError('只有房主可以生成邀请码');
        return;
      }
      final invite = await widget.services.rooms!.createInvite(
        roomId: snapshot.room.id,
        kind: InviteKind.code,
      );
      if (!mounted) return;
      await _showInviteSheet(snapshot, invite);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _actionBusyNotifier.value = false);
    }
  }

  Future<void> _showInviteSheet(
    RemoteRoomSnapshot snapshot,
    RemoteInvite invite,
  ) async {
    final memberCount = snapshot.room.members
        .where((member) => member.isActive)
        .length;
    final modeLabel = scoreUnitLabel(snapshot.room.scoringMode);
    await showPzDialog<void>(
      context: context,
      builder: (dialogContext) {
        final c = PzColors.of(dialogContext);
        Future<void> copy(String text, String message) async {
          await Clipboard.setData(ClipboardData(text: text));
          if (dialogContext.mounted) {
            ScaffoldMessenger.of(dialogContext)
                .showSnackBar(SnackBar(content: Text(message)));
          }
        }

        return PzDialogShell(
          title: '邀请牌友',
          subtitle:
              '${snapshot.room.name} · $memberCount 位成员 · '
              '${snapshot.room.gameType} · $modeLabel',
          actions: [
            PzButton(
              label: '完成',
              tone: PzButtonTone.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          children: [
            if (invite.shareLink.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: c.sunken,
                  borderRadius: PzRadius.cardAll,
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: invite.shareLink,
                      size: 200,
                      backgroundColor: Colors.white,
                      semanticsLabel: '房间邀请二维码',
                    ),
                    const SizedBox(height: 8),
                    const PzHint('邀请二维码区域'),
                  ],
                ),
              ),
            PzBoard(
              title: '邀请码',
              children: [
                PzBoardRow(
                  title: invite.code,
                  detail: '有效期以实际邀请为准',
                  trailing: TextButton(
                    onPressed: () => copy(invite.code, '邀请码已复制'),
                    child: const Text('复制'),
                  ),
                ),
              ],
            ),
            PzButton(
              label: '分享邀请链接',
              onPressed: () async {
                try {
                  await SharePlus.instance.share(
                    ShareParams(
                      text: invite.shareLink,
                      subject: '${snapshot.room.name} · 邀请',
                    ),
                  );
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text(mapAppError(error).message)),
                    );
                  }
                }
              },
            ),
            PzButton(
              label: '复制邀请链接',
              tone: PzButtonTone.ghost,
              onPressed: () => copy(invite.shareLink, '分享链接已复制'),
            ),
          ],
        );
      },
    );
  }

  // ── 同步队列 ─────────────────────────────────────────────────────────────

  Future<void> _resolveOperation(SyncQueueEntry entry) async {
    await _runRoomAction(() async {
      final draft = await _controller.prepareReapply(entry);
      if (!mounted) return;
      String describe(Round? round) => round == null
          ? '尚未创建'
          : '${round.isDeleted ? '已撤销；' : ''}'
                '${round.changes.map((change) => '${profileName(change.playerId, _controller.snapshot?.profiles ?? const {})} ${pzSigned(change.value)}').join(' · ')}';
      final confirmed = await pzConfirm(
        context,
        title: '重新确认这条记录',
        message:
            '服务器当前：${describe(draft.current)}\n本地草稿：${describe(draft.desired)}\n'
            '确认后将按最新版本重新提交草稿，并处理该回合依赖的本地修改。',
        confirmLabel: '重新提交',
      );
      if (confirmed && mounted) await _controller.applyRebased(draft);
    });
  }

  Future<void> _discardOperation(SyncQueueEntry entry) async {
    final confirmed = await pzConfirm(
      context,
      title: '放弃本地修改？',
      message: '将放弃此操作及依赖它的本地修改，不会撤销服务器已经保存的内容。',
      confirmLabel: '放弃本地修改',
    );
    if (confirmed && mounted) {
      await _runRoomAction(() => _controller.discard(entry));
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is String ? error : mapAppError(error).message;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── 界面 ────────────────────────────────────────────────────────────────

  List<_RankedMember> _ranking(
    List<RoomMember> members,
    Map<String, int> totals,
  ) {
    final entries = [
      for (var index = 0; index < members.length; index++)
        _RankedMember(
          member: members[index],
          total: totals[members[index].userId] ?? 0,
          joinIndex: index,
        ),
    ];
    entries.sort((left, right) {
      final byTotal = right.total.compareTo(left.total);
      if (byTotal != 0) return byTotal;
      return left.joinIndex.compareTo(right.joinIndex);
    });
    for (var index = 0; index < entries.length; index++) {
      var rank = index + 1;
      for (var scan = 0; scan < entries.length; scan++) {
        if (entries[scan].total == entries[index].total) {
          rank = scan + 1;
          break;
        }
      }
      entries[index].rank = rank;
    }
    return entries;
  }

  Widget _rankingBoard(
    BuildContext context,
    RemoteRoomSnapshot snapshot,
    GameSession session,
    List<RoomMember> members,
    bool canInput,
  ) {
    final totals = _totalsFor(session.id);
    final ranking = _ranking(members, totals);
    final actorId = _controller.actorId;
    return PzBoard(
      title: session.name,
      pill: PzPill(pzAmountLabel(snapshot.room.scoringMode)),
      children: [
        for (final entry in ranking)
          PzBoardRow(
            rank: '${entry.rank}',
            avatar: UserAvatar(
              name: profileName(entry.member.userId, snapshot.profiles),
              avatarKey: snapshot.profiles[entry.member.userId]?.avatarKey,
              avatarUrl: snapshot.profiles[entry.member.userId]?.avatarUrl,
              radius: 15,
            ),
            title: entry.member.userId == actorId
                ? '我'
                : profileName(entry.member.userId, snapshot.profiles),
            detail: entry.member.userId == actorId
                ? '${profileName(entry.member.userId, snapshot.profiles)} · 当前账号'
                : canInput
                ? '点头像转分'
                : '仅查看',
            trailing: PzScoreText(
              entry.total,
              unit: pzScoreUnit(snapshot.room.scoringMode),
            ),
            highlight: entry.member.userId == actorId,
            onTap: canInput && entry.member.userId != actorId
                ? () => _transferScore(
                    snapshot,
                    session: session,
                    toPlayerId: entry.member.userId,
                  )
                : null,
          ),
      ],
    );
  }

  Widget _buildFooter(
    BuildContext context,
    RoomSnapshot snapshot,
    GameSession? session,
  ) {
    final reason = _actionBusy
        ? '正在处理，请稍候'
        : _controller.inputDisabledReason(session?.id);
    if (session == null) {
      final owner = _controller.canManage;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!owner) ...[
                const PzHint('等待房主开始牌局'),
                const SizedBox(height: 8),
              ],
              PzButton(
                label: '创建牌局',
                icon: Icons.add_rounded,
                onPressed: owner && !_actionBusy
                    ? () => _createSession(snapshot)
                    : null,
              ),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reason != null) ...[PzHint(reason), const SizedBox(height: 8)],
            PzButton(
              label: '记一局',
              onPressed: reason == null
                  ? () => _recordRound(snapshot, session)
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PzButton(
                    label: '多人转分',
                    tone: PzButtonTone.ghost,
                    onPressed: reason == null
                        ? () => _multiTransfer(snapshot, session)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PzButton(
                    label: '看结算',
                    tone: PzButtonTone.ghost,
                    onPressed: () => _showSettlement(snapshot, session),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RoomSnapshot snapshot,
    RoomController controller,
  ) {
    final data = snapshot;
    final activeSession = _selectedActiveSession(data);
    final activeSessions = _activeSessions(data);
    final members = data.room.members
        .where((member) => member.isActive)
        .toList();
    final canInput = _controller.canInput && !_controller.busy && !_actionBusy;
    final roundCount = activeSession == null
        ? 0
        : (_controller.roundsBySession[activeSession.id] ?? const <Round>[])
              .where((round) => !round.isDeleted)
              .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        SyncStatusPanel(
          controller: _controller,
          onResolve: _resolveOperation,
          onDiscard: _discardOperation,
          onRetry: (entry) => _runRoomAction(() => _controller.retry(entry)),
        ),
        if (data.room.isClosed)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: PzNotice(title: '房间已关闭', message: '当前仅支持查看历史和结算，不能继续录入或管理。'),
          ),
        PzContextBox(
          title: '当前牌局',
          subtitle: activeSession == null
              ? '暂无进行中的牌局'
              : '已记 $roundCount 回合 · ${data.room.name}',
          child: activeSessions.length > 1
              ? PzDropdown<String>(
                  value: activeSession?.id,
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
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (activeSession == null)
          const PzBoard(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: PzHint('没有进行中的牌局。房主可在「管理」中创建或开始牌局。'),
              ),
            ],
          )
        else ...[
          if (canInput)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: PzHint('点牌友头像或所在行，输入金额转分'),
            ),
          _rankingBoard(context, data, activeSession, members, canInput),
          const SizedBox(height: 12),
          PzBoard(
            dividerBetween: false,
            children: [
              PzBoardRow(
                title: '已记 $roundCount 回合',
                detail: '最近回合：${_latestRoundSummary(activeSession.id)}',
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => Text(
            _controller.snapshot?.room.name ?? widget.room.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          RoomSnapshotBuilder(
            controller: _controller,
            builder: (context, snapshot) {
              if (!snapshot.hasData || !_controller.canManage) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: _createInvite,
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: '邀请牌友',
              );
            },
          ),
          IconButton(
            onPressed: () async {
              try {
                await _snapshotFuture;
                if (mounted) await _showRoomManagement();
              } catch (error) {
                _showError(error);
              }
            },
            icon: const Icon(Icons.tune_rounded),
            tooltip: '管理',
          ),
        ],
      ),
      bottomNavigationBar: RoomSnapshotBuilder(
        controller: _controller,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return _buildFooter(
            context,
            snapshot.data!,
            _selectedActiveSession(snapshot.data!),
          );
        },
      ),
      body: RoomSnapshotBuilder(
        controller: _controller,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (mapAppError(snapshot.error!).isAccessError) {
              return RoomAccessErrorCard(
                message: mapAppError(snapshot.error!).message,
                onBack: () => Navigator.of(context).pop(),
              );
            }
            return Center(
              child: ErrorCard(
                message: mapAppError(snapshot.error!).message,
                onRetry: _reloadSnapshot,
              ),
            );
          }
          return _buildBody(context, snapshot.data!, _controller);
        },
      ),
    );
  }
}

class _RankedMember {
  _RankedMember({
    required this.member,
    required this.total,
    required this.joinIndex,
  });

  final RoomMember member;
  final int total;
  final int joinIndex;
  int rank = 1;
}

/// 单行文本输入对话框（创建／重命名牌局）。
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
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PzDialogShell(
      title: widget.title,
      actions: [
        PzButton(
          label: '取消',
          tone: PzButtonTone.secondary,
          onPressed: () => Navigator.pop(context),
        ),
        PzButton(
          label: widget.confirmLabel,
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) {
              setState(() => _error = '内容不能为空');
              return;
            }
            Navigator.pop(context, value);
          },
        ),
      ],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PzLabel(widget.label),
            PzTextField(controller: _controller, autofocus: true),
            if (_error != null) ...[
              const SizedBox(height: 6),
              PzFormError(_error),
            ],
          ],
        ),
      ],
    );
  }
}

class RoomSnapshotBuilder extends StatelessWidget {
  const RoomSnapshotBuilder({
    required this.controller,
    required this.builder,
    super.key,
  });
  final RoomController controller;
  final AsyncWidgetBuilder<RoomSnapshot> builder;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final data = controller.snapshot;
      if (data != null) {
        return builder(
          context,
          AsyncSnapshot.withData(ConnectionState.done, data),
        );
      }
      if (controller.loading) {
        return builder(context, const AsyncSnapshot.waiting());
      }
      return builder(
        context,
        AsyncSnapshot.withError(
          ConnectionState.done,
          controller.error ?? const AppError(AppErrorKind.network, '暂无可用房间数据'),
        ),
      );
    },
  );
}
