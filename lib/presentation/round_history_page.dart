import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'design.dart';
import 'presentation_helpers.dart';

/// 最新回合列表及其本地同步状态。
class RoundHistoryData {
  const RoundHistoryData({
    required this.rounds,
    required this.pendingRoundIds,
    required this.conflictRoundIds,
  });

  final List<Round> rounds;
  final Set<String> pendingRoundIds;
  final Set<String> conflictRoundIds;
}

/// 回合记录页：按时间倒序，显示记录者、备注与同步状态。
///
/// 只有创建者且牌局仍进行中才可修改、撤销或恢复；已结束牌局只读。
/// 操作完成后通过 [onReload] 重新读取回合和同步状态。
class RoundHistoryPage extends StatefulWidget {
  const RoundHistoryPage({
    super.key,
    required this.roomName,
    required this.session,
    required this.rounds,
    required this.profiles,
    required this.currentUserId,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    this.onReload,
    this.pendingRoundIds = const {},
    this.conflictRoundIds = const {},
    this.hasMore = false,
    this.onLoadMore,
  });

  final String roomName;
  final GameSession session;

  /// 该牌局的全部回合（含已撤销），按回合号倒序。
  final List<Round> rounds;
  final Map<String, User> profiles;
  final String? currentUserId;
  final bool canEdit;
  final Future<void> Function(Round round) onEdit;
  final Future<void> Function(Round round) onDelete;
  final Future<void> Function(Round round) onRestore;

  /// 操作后重新读取回合列表和同步状态（倒序）；返回 null 时保留当前内容。
  final Future<RoundHistoryData?> Function()? onReload;
  final Set<String> pendingRoundIds;
  final Set<String> conflictRoundIds;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;

  @override
  State<RoundHistoryPage> createState() => _RoundHistoryPageState();
}

class _RoundHistoryPageState extends State<RoundHistoryPage> {
  late List<Round> _rounds = widget.rounds;
  late Set<String> _pendingRoundIds = {...widget.pendingRoundIds};
  late Set<String> _conflictRoundIds = {...widget.conflictRoundIds};
  String? _busyRoundId;

  Future<void> _run(
    Future<void> Function(Round round) action,
    Round round,
  ) async {
    if (_busyRoundId != null) return;
    setState(() => _busyRoundId = round.id);
    try {
      await action(round);
      final fresh = await widget.onReload?.call();
      if (!mounted || fresh == null) return;
      setState(() {
        _rounds = fresh.rounds;
        _pendingRoundIds = {...fresh.pendingRoundIds};
        _conflictRoundIds = {...fresh.conflictRoundIds};
      });
    } finally {
      if (mounted) setState(() => _busyRoundId = null);
    }
  }

  String _statusLabel(Round round) {
    if (_conflictRoundIds.contains(round.id)) return '版本冲突';
    if (_pendingRoundIds.contains(round.id)) return '待同步';
    return '已同步';
  }

  String _changesLabel(Round round) => round.changes
      .map(
        (change) =>
            '${profileName(change.playerId, widget.profiles)} ${pzSigned(change.value)}',
      )
      .join(' · ');

  String _timeLabel(Round round) {
    final time = round.createdAt.toLocal();
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _actions(BuildContext context, Round round) {
    final c = PzColors.of(context);
    final mine = round.createdBy == widget.currentUserId;
    if (!widget.canEdit || !mine) {
      return Text('只读', style: TextStyle(fontSize: 12, color: c.subtle));
    }
    final busy = _busyRoundId != null;
    final currentBusy = _busyRoundId == round.id;
    if (round.isDeleted) {
      if (round.changes.isEmpty) {
        return Text('只读', style: TextStyle(fontSize: 12, color: c.subtle));
      }
      return TextButton(
        onPressed: busy ? null : () => _run(widget.onRestore, round),
        child: Text(currentBusy ? '处理中…' : '恢复'),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: busy ? null : () => _run(widget.onEdit, round),
          child: Text(currentBusy ? '处理中…' : '编辑'),
        ),
        TextButton(
          onPressed: busy ? null : () => _run(widget.onDelete, round),
          child: const Text('撤销'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.session.name} · 回合记录',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          if (_rounds.isEmpty)
            const PzBoard(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: PzHint('还没有回合记录。记一局后，这里会按时间倒序展示。'),
                ),
              ],
            ),
          for (final round in _rounds) ...[
            PzBoard(
              title: '第 ${round.number} 回合',
              children: [
                PzBoardRow(
                  title: round.isDeleted ? '已撤销' : _changesLabel(round),
                  detail: round.isDeleted
                      ? '原变化保留 · 不计入总分'
                      : '记录者：${profileName(round.createdBy, widget.profiles)} · '
                            '${_timeLabel(round)} · ${_statusLabel(round)}',
                  titleColor: round.isDeleted ? c.muted : null,
                  trailing: _actions(context, round),
                ),
                if (round.note != null && round.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(13, 0, 13, 11),
                    child: PzHint('备注：${round.note!}'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (widget.hasMore && widget.onLoadMore != null)
            PzButton(
              label: '查看更多回合',
              tone: PzButtonTone.ghost,
              onPressed: widget.onLoadMore,
            ),
        ],
      ),
    );
  }
}
