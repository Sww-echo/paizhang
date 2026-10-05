import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'avatar_widgets.dart';
import 'presentation_helpers.dart';

class RoomMemberScoreTile extends StatelessWidget {
  const RoomMemberScoreTile({
    super.key,
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
    final label = profile?.nickname ?? shortId(member.userId);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            UserAvatar(
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

class RoomManagementDialog extends StatelessWidget {
  const RoomManagementDialog({
    super.key,
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
                  : '关闭房间需要有效成员投票，同意票达到有效成员半数即可关闭。',
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
              CloseVotePanel(
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
                          leading: UserAvatar(
                            name: profileName(member.userId, profiles),
                            avatarKey: profiles[member.userId]?.avatarKey,
                            avatarUrl: profiles[member.userId]?.avatarUrl,
                          ),
                          title: Text(profileName(member.userId, profiles)),
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

class CloseVotePanel extends StatelessWidget {
  const CloseVotePanel({
    super.key,
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
              const Text('发起后，有效成员可以投票；同意票达到有效成员半数即可关闭。')
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

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
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
                Text(sessionStatusLabel(session.status)),
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

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});

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

class RoomAccessErrorCard extends StatelessWidget {
  const RoomAccessErrorCard({
    super.key,
    required this.message,
    required this.onBack,
  });

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
