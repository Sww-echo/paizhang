import 'package:flutter/material.dart';

import '../application/app_services.dart';
import '../domain/models.dart';
import '../domain/room_snapshot.dart';

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../application/room_controller.dart';
import '../domain/app_error.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import '../infrastructure/local/app_database.dart';
import 'room_widgets.dart';
import 'score_dialogs.dart';
import 'common_widgets.dart';
import 'history_pages.dart';
import 'settlement_page.dart';
import 'presentation_helpers.dart';
import 'sync_status_panel.dart';

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
  String? _selectedSessionId;
  bool _actionBusy = false;

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

  bool _canInputRoom(Room room) => _controller.canInput;
  bool _isRoomOwner(Room room) => _controller.canManage;

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
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '房间邀请码',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: invite.code),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('邀请码已复制')),
                            );
                          }
                        },
                        child: const Text('复制邀请码'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: invite.shareLink),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('分享链接已复制')),
                            );
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
                ],
              ),
            ),
          ),
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
      builder: (context) => const TextInputDialog(
        title: '创建牌局',
        label: '牌局名称',
        confirmLabel: '创建',
      ),
    );
    if (name == null) return;
    if (!mounted) return;
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
      builder: (context) => TextInputDialog(
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

  Future<ScoreInput?> _showScoreInput(
    RemoteRoomSnapshot snapshot, {
    List<ScoreChange> initialChanges = const [],
    String? initialNote,
    String title = '录入一局分数',
  }) async {
    var currentChanges = initialChanges;
    var currentNote = initialNote;
    while (mounted) {
      if (!mounted) return null;
      final input = await showDialog<ScoreInput>(
        context: context,
        builder: (context) => ScoreDialog(
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

  Future<void> _recordRound(GameSession session, RoomSnapshot snapshot) async {
    if (!_controller.canInput) return;
    final input = await _showScoreInput(snapshot);
    if (input == null || !mounted) return;
    await _runRoomAction(() async {
      await _controller.recordRound(
        session.id,
        input.changes,
        note: input.note,
      );
      _showSuccess('记录已保存到本机，正在同步');
    });
  }

  Future<void> _editRound(RoomSnapshot snapshot, Round round) async {
    if (!_controller.canEdit(round)) return;
    final input = await _showScoreInput(
      snapshot,
      initialChanges: round.changes,
      initialNote: round.note,
      title: '编辑第 ${round.number} 局',
    );
    if (input == null || !mounted) return;
    await _runRoomAction(() async {
      await _controller.updateRound(round, input.changes, note: input.note);
      _showSuccess('修改已保存到本机，正在同步');
    });
  }

  Future<void> _deleteRound(RoomSnapshot snapshot, Round round) async {
    if (!_controller.canEdit(round)) return;
    final confirmed = await _confirmAction(
      title: '撤销第 ${round.number} 局？',
      message: '这局会保留在历史记录中，但不再计入总分。',
      confirmLabel: '撤销',
    );
    if (!confirmed || !mounted) return;
    await _runRoomAction(() => _controller.deleteRound(round));
  }

  Future<void> _restoreRound(RoomSnapshot snapshot, Round round) async {
    if (!_controller.canEdit(round)) return;
    await _runRoomAction(
      () => _controller.updateRound(round, round.changes, note: round.note),
    );
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
      builder: (dialogContext) => RoundHistoryDialog(
        session: session,
        rounds: rounds,
        profiles: snapshot.profiles,
        currentUserId: widget.services.currentUser?.id,
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
        builder: (_) => SettlementPage(
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
        MaterialPageRoute(builder: (_) => RoomHistoryPage(snapshot: snapshot)),
      );
    } catch (error) {
      _showError(error);
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
    final fromPlayerId = widget.services.currentUser?.id;
    if (fromPlayerId == null || fromPlayerId == toPlayerId) return;
    final transfer = await showDialog<ScoreTransfer>(
      context: context,
      builder: (context) => ScoreTransferDialog(
        members: snapshot.room.members,
        profiles: snapshot.profiles,
        totals: _controller.totalsBySession[session.id] ?? const {},
        scoringMode: snapshot.room.scoringMode,
        fromPlayerId: fromPlayerId,
        toPlayerId: toPlayerId,
      ),
    );
    if (transfer == null || !mounted) return;
    await _runRoomAction(() async {
      await _controller.recordRound(session.id, [
        ScoreChange(playerId: transfer.fromPlayerId, value: -transfer.amount),
        ScoreChange(playerId: transfer.toPlayerId, value: transfer.amount),
      ], note: '${scoreUnitLabel(snapshot.room.scoringMode)}转换');
      _showSuccess('转换已保存到本机，正在同步');
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
    final values = await showDialog<RoomFormValue>(
      context: context,
      builder: (context) => RoomFormDialog(
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
      builder: (dialogContext) => RoomManagementDialog(
        room: snapshot.room,
        profiles: snapshot.profiles,
        currentUserId: widget.services.currentUser?.id,
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
    final unit = scoreUnitLabel(snapshot.room.scoringMode);
    final summary = changes
        .map(
          (change) =>
              '${profileName(change.playerId, snapshot.profiles)} ${change.value > 0 ? '+' : ''}${change.value} $unit',
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

  bool _isRoomAccessError(Object error) => mapAppError(error).isAccessError;
  String _friendlyErrorMessage(Object error) =>
      error is String ? error : mapAppError(error).message;

  Future<void> _resolveOperation(SyncQueueEntry entry) async {
    await _runRoomAction(() async {
      final draft = await _controller.prepareReapply(entry);
      if (!mounted) return;
      String describe(Round? round) => round == null
          ? '尚未创建'
          : '${round.isDeleted ? '已撤销；' : ''}${round.changes.map((change) => '${profileName(change.playerId, _controller.snapshot?.profiles ?? {})} ${change.value}').join('，')}';
      final confirmed = await _confirmAction(
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
    final confirmed = await _confirmAction(
      title: '放弃本地修改？',
      message: '将放弃此操作及依赖它的本地修改，不会撤销服务器已经保存的内容。',
      confirmLabel: '放弃本地修改',
    );
    if (confirmed && mounted) {
      await _runRoomAction(() => _controller.discard(entry));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) =>
              Text(_controller.snapshot?.room.name ?? widget.room.name),
        ),
        actions: [
          IconButton(
            onPressed: _showRoomHistory,
            icon: const Icon(Icons.history_rounded),
            tooltip: '房间历史',
          ),
          RoomSnapshotBuilder(
            controller: _controller,
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
      body: RoomSnapshotBuilder(
        controller: _controller,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (_isRoomAccessError(snapshot.error!)) {
              return RoomAccessErrorCard(
                message: _friendlyErrorMessage(snapshot.error!),
                onBack: () => Navigator.of(context).pop(),
              );
            }
            return ErrorCard(
              message: mapAppError(snapshot.error!).message,
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
              : (_controller.totalsBySession[activeSession.id] ??
                    const <String, int>{});
          final members = data.room.members
              .where((member) => member.isActive)
              .toList();
          final canInput =
              _controller.canInput && !_controller.busy && !_actionBusy;
          final isOwner =
              _controller.canManage && !_controller.busy && !_actionBusy;
          final scoreUnit = scoreUnitLabel(data.room.scoringMode);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SyncStatusPanel(
                controller: _controller,
                onResolve: _resolveOperation,
                onDiscard: _discardOperation,
                onRetry: (entry) =>
                    _runRoomAction(() => _controller.retry(entry)),
              ),
              Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: Text('${members.length} 位成员'),
                  subtitle: Text(data.room.gameType),
                  trailing: Text(roomStatusLabel(data.room.status)),
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
                          '点击好友头像，将当前用户的$scoreUnit转给对方',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final member in members)
                            RoomMemberScoreTile(
                              member: member,
                              profile: data.profiles[member.userId],
                              score: totals[member.userId] ?? 0,
                              enabled:
                                  activeSession != null &&
                                  canInput &&
                                  member.userId !=
                                      widget.services.currentUser?.id,
                              onTap: () => _transferScore(
                                data,
                                session: activeSession!,
                                toPlayerId: member.userId,
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
                  SessionCard(
                    session: session,
                    roundCount:
                        (_controller.roundsBySession[session.id] ??
                                const <Round>[])
                            .where((round) => !round.isDeleted)
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
                          widget.services.currentUser?.id ?? '',
                        ),
                  ),
            ],
          );
        },
      ),
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
