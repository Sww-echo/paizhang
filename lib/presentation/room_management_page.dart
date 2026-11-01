import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'design.dart';
import 'presentation_helpers.dart';

/// 房间管理页：房间设置、成员、关闭投票与牌局生命周期。
///
/// 创建、开始、结束和关闭分别处理；查看结算不会自动结束牌局。
/// 每个动作在执行前说明权限与后果，失败时由调用方就地提示。
class RoomManagementPage extends StatelessWidget {
  const RoomManagementPage({
    super.key,
    required this.room,
    required this.sessions,
    required this.roundCounts,
    required this.profiles,
    required this.currentUserId,
    required this.closeVote,
    required this.canManage,
    required this.canInput,
    required this.readOnly,
    required this.hasActiveSession,
    required this.busy,
    required this.onEditRoom,
    required this.onPermissionChanged,
    required this.onInvite,
    required this.onCreateSession,
    required this.onStartSession,
    required this.onDeleteSession,
    required this.onRenameSession,
    required this.onFinishSession,
    required this.onReopenSession,
    required this.onOpenHistory,
    required this.onOpenSettlement,
    required this.onRecordSession,
    required this.onCastCloseVote,
    required this.onCancelCloseVote,
    required this.onRemoveMember,
    required this.onTransferOwnership,
    required this.onLeaveRoom,
  });

  final Room room;
  final List<GameSession> sessions;
  final Map<String, int> roundCounts;
  final Map<String, User> profiles;
  final String? currentUserId;
  final RoomCloseVoteSummary? closeVote;
  final bool canManage;
  final bool canInput;
  final bool readOnly;
  final bool hasActiveSession;
  final bool busy;

  final Future<void> Function() onEditRoom;
  final Future<void> Function(InputPermission permission) onPermissionChanged;
  final Future<void> Function() onInvite;
  final Future<void> Function() onCreateSession;
  final Future<void> Function(GameSession session) onStartSession;
  final Future<void> Function(GameSession session) onDeleteSession;
  final Future<void> Function(GameSession session) onRenameSession;
  final Future<void> Function(GameSession session) onFinishSession;
  final Future<void> Function(GameSession session) onReopenSession;
  final Future<void> Function(GameSession session) onOpenHistory;
  final Future<void> Function(GameSession session) onOpenSettlement;
  final Future<void> Function(GameSession session) onRecordSession;
  final Future<void> Function(bool approved, RoomStatus targetStatus)
  onCastCloseVote;
  final Future<void> Function() onCancelCloseVote;
  final Future<void> Function(String userId) onRemoveMember;
  final Future<void> Function(String userId) onTransferOwnership;
  final Future<void> Function() onLeaveRoom;

  bool get _closed => room.isClosed;
  bool get _isOwner => room.ownerId == currentUserId;
  bool get _manageEnabled => canManage && !busy;
  bool get _inputEnabled => canInput && !busy;

  String get _permissionLabel =>
      room.inputPermission == InputPermission.all ? '所有成员' : '仅房主';

  Future<void> _pickPermission(BuildContext context) async {
    final picked = await showPzDialog<InputPermission>(
      context: context,
      builder: (dialogContext) => PzDialogShell(
        title: '录入权限',
        actions: [
          PzButton(
            label: '取消',
            tone: PzButtonTone.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
        children: [
          for (final option in InputPermission.values)
            PzBoardRow(
              title: option == InputPermission.all ? '所有成员' : '仅房主',
              detail: option == InputPermission.all ? '成员可记录自己的操作' : '其他成员查看结果',
              trailing: Text(
                room.inputPermission == option ? '已选' : '选择',
                style: TextStyle(
                  fontSize: 12,
                  color: room.inputPermission == option
                      ? PzColors.of(context).brandInk
                      : PzColors.of(context).muted,
                ),
              ),
              onTap: () => Navigator.of(dialogContext).pop(option),
            ),
        ],
      ),
    );
    if (picked != null && picked != room.inputPermission) {
      await onPermissionChanged(picked);
    }
  }

  Future<void> _confirmThen(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() action,
  }) async {
    final confirmed = await pzConfirm(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    );
    if (confirmed) await action();
  }

  Future<void> _castVote(
    BuildContext context, {
    required bool approved,
    required RoomStatus targetStatus,
  }) async {
    final vote = closeVote;
    final reachesThreshold =
        approved &&
        vote != null &&
        (vote.approvedCount + 1) * 2 >= vote.activeMemberCount;
    if (reachesThreshold) {
      final confirmed = await pzConfirm(
        context,
        title: '同意后可能立即关闭房间',
        message:
            '这是第 ${vote.approvedCount + 1} 票同意，达到 ${vote.activeMemberCount} 人房间的关闭门槛。'
            '${targetStatus == RoomStatus.dissolved ? '解散' : '归档'}后停止记分和管理，历史与结算保留。',
        confirmLabel: '同意并关闭',
      );
      if (!confirmed) return;
    }
    await onCastCloseVote(approved, targetStatus);
  }

  Widget _settingsBoard(BuildContext context) {
    final c = PzColors.of(context);
    return PzBoard(
      title: '房间设置',
      children: [
        PzBoardRow(
          title: '名称与玩法',
          detail: '${room.name} · ${room.gameType}',
          trailing: Text('›', style: TextStyle(fontSize: 16, color: c.muted)),
          onTap: _manageEnabled ? () => onEditRoom() : null,
        ),
        PzBoardRow(
          title: '录入权限',
          detail: _permissionLabel,
          trailing: Text('›', style: TextStyle(fontSize: 16, color: c.muted)),
          onTap: _manageEnabled ? () => _pickPermission(context) : null,
        ),
        PzBoardRow(
          title: '邀请牌友',
          detail: '二维码、邀请码、链接',
          trailing: Text('›', style: TextStyle(fontSize: 16, color: c.muted)),
          onTap: _manageEnabled ? () => onInvite() : null,
        ),
      ],
    );
  }

  Widget _membersBoard(BuildContext context) {
    final c = PzColors.of(context);
    final activeMembers = room.members
        .where((member) => member.isActive)
        .toList();
    return PzBoard(
      title: '成员 · ${activeMembers.length} 人',
      children: [
        for (final member in activeMembers)
          PzBoardRow(
            title: profileName(member.userId, profiles),
            detail: member.userId == room.ownerId
                ? '房主'
                : _manageEnabled
                ? '成员'
                : '成员 · 管理操作仅房主可用',
            trailing:
                _manageEnabled && member.userId != room.ownerId && !_closed
                ? PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded, color: c.muted),
                    onSelected: (value) async {
                      if (value == 'transfer') {
                        await _confirmThen(
                          context,
                          title: '转让房主？',
                          message: '转让后你将不能继续管理成员和录入权限。',
                          confirmLabel: '转让',
                          action: () => onTransferOwnership(member.userId),
                        );
                      } else if (value == 'remove') {
                        await _confirmThen(
                          context,
                          title: '移除成员？',
                          message: '移除后，该成员不能继续录入或管理，但仍可在历史记录查看离开前的牌局。',
                          confirmLabel: '移除',
                          action: () => onRemoveMember(member.userId),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'transfer', child: Text('转让房主')),
                      PopupMenuItem(value: 'remove', child: Text('移除成员')),
                    ],
                  )
                : null,
          ),
      ],
    );
  }

  Widget _closeVoteBoard(BuildContext context) {
    final c = PzColors.of(context);
    final vote = closeVote;
    final targetLabel = vote?.targetStatus == RoomStatus.dissolved
        ? '解散'
        : '归档';
    if (vote == null) {
      return PzBoard(
        title: '关闭房间',
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 0),
            child: PzHint(
              hasActiveSession
                  ? '仍有进行中的牌局，请先结束所有牌局。'
                  : '发起后，有效成员可以投票；同意票达到有效成员半数即可关闭。',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 8, 13, 11),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PzButton(
                  label: '发起归档投票',
                  tone: PzButtonTone.secondary,
                  onPressed: hasActiveSession || busy
                      ? null
                      : () => _confirmThen(
                          context,
                          title: '发起归档投票？',
                          message: '归档后停止记分和管理，历史与结算保留。',
                          confirmLabel: '发起投票',
                          action: () =>
                              onCastCloseVote(true, RoomStatus.archived),
                        ),
                ),
                PzButton(
                  label: '发起解散投票',
                  tone: PzButtonTone.secondary,
                  onPressed: hasActiveSession || busy
                      ? null
                      : () => _confirmThen(
                          context,
                          title: '发起解散投票？',
                          message: '解散后停止记分和管理，历史与结算保留。',
                          confirmLabel: '发起投票',
                          action: () =>
                              onCastCloseVote(true, RoomStatus.dissolved),
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final remaining = vote.remainingApprovals;
    final myChoice = vote.currentUserApproved == null
        ? '尚未投票'
        : vote.currentUserApproved!
        ? '已投同意票'
        : '已投不同意票';
    return PzBoard(
      title: '$targetLabel${room.name} · 投票中',
      pill: PzPill('${vote.approvedCount}/${vote.activeMemberCount}'),
      children: [
        PzBoardRow(
          title: '${vote.approvedCount} / ${vote.activeMemberCount} 人同意',
          detail: '达到 ${vote.requiredApprovals} 票即$targetLabel',
          trailing: Text(
            remaining > 0 ? '还差 $remaining 票' : '已达到门槛',
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
        ),
        PzBoardRow(title: '我的选择', detail: myChoice),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 0),
          child: PzNotice(
            message: '同意后可能立即达到关闭门槛。$targetLabel后停止记分和管理，历史与结算保留。',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 8, 13, 11),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PzButton(
                label: '不同意',
                tone: PzButtonTone.secondary,
                onPressed: hasActiveSession || busy
                    ? null
                    : () => onCastCloseVote(false, vote.targetStatus),
              ),
              PzButton(
                label: '同意$targetLabel',
                tone: PzButtonTone.secondary,
                onPressed: hasActiveSession || busy
                    ? null
                    : () => _castVote(
                        context,
                        approved: true,
                        targetStatus: vote.targetStatus,
                      ),
              ),
              if (vote.createdBy == currentUserId || _isOwner)
                PzButton(
                  label: '取消本轮投票',
                  tone: PzButtonTone.ghost,
                  onPressed: busy ? null : () => onCancelCloseVote(),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 0, 13, 11),
          child: const PzHint('本轮有效期以提案为准。成员变化或新开牌局后，本轮投票失效。'),
        ),
      ],
    );
  }

  Widget _sessionBoard(BuildContext context, GameSession session) {
    final c = PzColors.of(context);
    final count = roundCounts[session.id] ?? 0;
    final status = session.status;
    final actions = <Widget>[];
    if (status == GameSessionStatus.draft) {
      actions.addAll([
        PzButton(
          label: '开始',
          tone: PzButtonTone.primary,
          onPressed: _manageEnabled ? () => onStartSession(session) : null,
        ),
        PzButton(
          label: '重命名',
          tone: PzButtonTone.secondary,
          onPressed: _manageEnabled ? () => onRenameSession(session) : null,
        ),
        PzButton(
          label: '删除草稿',
          tone: PzButtonTone.secondary,
          onPressed: _manageEnabled
              ? () => _confirmThen(
                  context,
                  title: '删除草稿牌局？',
                  message: '删除后不会产生任何记分记录，且无法恢复。',
                  confirmLabel: '删除',
                  action: () => onDeleteSession(session),
                )
              : null,
        ),
      ]);
    } else if (status == GameSessionStatus.active) {
      actions.addAll([
        PzButton(
          label: '记分',
          tone: PzButtonTone.primary,
          onPressed: _inputEnabled ? () => onRecordSession(session) : null,
        ),
        PzButton(
          label: '历史',
          tone: PzButtonTone.secondary,
          onPressed: () => onOpenHistory(session),
        ),
        PzButton(
          label: '结算',
          tone: PzButtonTone.secondary,
          onPressed: () => onOpenSettlement(session),
        ),
        PzButton(
          label: '结束',
          tone: PzButtonTone.secondary,
          onPressed: _manageEnabled
              ? () => _confirmThen(
                  context,
                  title: '结束牌局？',
                  message: '结束后将不能继续录入，只有重新打开后才能修正。',
                  confirmLabel: '结束牌局',
                  action: () => onFinishSession(session),
                )
              : null,
        ),
      ]);
    } else {
      actions.addAll([
        PzButton(
          label: '历史',
          tone: PzButtonTone.secondary,
          onPressed: () => onOpenHistory(session),
        ),
        PzButton(
          label: '结算',
          tone: PzButtonTone.primary,
          onPressed: () => onOpenSettlement(session),
        ),
        if (_isOwner)
          PzButton(
            label: '重新打开',
            tone: PzButtonTone.secondary,
            onPressed: _manageEnabled && !readOnly
                ? () => _confirmThen(
                    context,
                    title: '重新打开牌局？',
                    message: '重新打开后可以继续修正或录入回合。',
                    confirmLabel: '重新打开',
                    action: () => onReopenSession(session),
                  )
                : null,
          ),
      ]);
    }
    return PzBoard(
      title: session.name,
      pill: PzPill(
        sessionStatusLabel(status),
        tone: status == GameSessionStatus.active
            ? PzPillTone.brand
            : status == GameSessionStatus.draft
            ? PzPillTone.accent
            : PzPillTone.grey,
      ),
      children: [
        PzBoardRow(
          title: sessionStatusLabel(status),
          detail: switch (status) {
            GameSessionStatus.draft => '$count 回合 · 尚未开始',
            GameSessionStatus.active => '$count 回合 · 当前记分对象',
            GameSessionStatus.finished => '$count 回合 · 只读',
          },
          trailing: Text(switch (status) {
            GameSessionStatus.draft => '草稿',
            GameSessionStatus.active => '当前',
            GameSessionStatus.finished => '已结束',
          }, style: TextStyle(fontSize: 12, color: c.muted)),
        ),
        if (_isOwner && status == GameSessionStatus.active && _manageEnabled)
          PzBoardRow(
            title: '重命名',
            detail: '仅房主',
            trailing: Text('›', style: TextStyle(fontSize: 16, color: c.muted)),
            onTap: () => onRenameSession(session),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 8, 13, 11),
          child: Wrap(spacing: 8, runSpacing: 8, children: actions),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedSessions = [...sessions]
      ..sort((left, right) {
        int rank(GameSessionStatus status) => switch (status) {
          GameSessionStatus.active => 0,
          GameSessionStatus.draft => 1,
          GameSessionStatus.finished => 2,
        };
        final byStatus = rank(left.status).compareTo(rank(right.status));
        if (byStatus != 0) return byStatus;
        return sessionDate(right).compareTo(sessionDate(left));
      });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${room.name} · 管理',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          if (_closed)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: PzNotice(
                title: '房间已关闭',
                message: '当前仅可查看历史和结算，不能继续录入或管理。',
              ),
            ),
          _settingsBoard(context),
          const SizedBox(height: 12),
          _membersBoard(context),
          if (!_closed) ...[
            const SizedBox(height: 12),
            _closeVoteBoard(context),
          ],
          const SizedBox(height: 12),
          PzSectionTitle(
            '牌局',
            action: _manageEnabled
                ? PzButton(
                    label: '新建牌局',
                    tone: PzButtonTone.secondary,
                    onPressed: () => onCreateSession(),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          if (sortedSessions.isEmpty)
            const PzBoard(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: PzHint('还没有牌局。创建牌局后开始记分。'),
                ),
              ],
            ),
          for (final session in sortedSessions) ...[
            _sessionBoard(context, session),
            const SizedBox(height: 12),
          ],
          if (!_closed)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: PzHint('关闭房间前先结束所有进行中的牌局。历史记录保留。'),
            ),
          if (!_isOwner && !_closed) ...[
            const SizedBox(height: 12),
            PzButton(
              label: '离开房间',
              tone: PzButtonTone.ghost,
              onPressed: busy
                  ? null
                  : () => _confirmThen(
                      context,
                      title: '离开房间？',
                      message: '离开后需要新的邀请码才能重新加入；已参与期间的历史仍可查看。',
                      confirmLabel: '离开',
                      action: onLeaveRoom,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
