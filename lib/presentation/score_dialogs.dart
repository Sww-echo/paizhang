import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'presentation_helpers.dart';

class ScoreTransfer {
  const ScoreTransfer({
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.amount,
  });

  final String fromPlayerId;
  final String toPlayerId;
  final int amount;
}

class ScoreInput {
  const ScoreInput({required this.changes, this.note});

  final List<ScoreChange> changes;
  final String? note;
}

class ScoreTransferDialog extends StatefulWidget {
  const ScoreTransferDialog({super.key,
    required this.members,
    required this.profiles,
    required this.totals,
    required this.scoringMode,
    required this.fromPlayerId,
    required this.toPlayerId,
  });

  final List<RoomMember> members;
  final Map<String, User> profiles;
  final Map<String, int> totals;
  final ScoringMode scoringMode;
  final String fromPlayerId;
  final String toPlayerId;

  @override
  State<ScoreTransferDialog> createState() => _ScoreTransferDialogState();
}

class _ScoreTransferDialogState extends State<ScoreTransferDialog> {
  late final List<RoomMember> _members = widget.members
      .where((member) => member.isActive)
      .toList();
  final _amountController = TextEditingController();
  late final String _fromPlayerId;
  late final String _toPlayerId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fromPlayerId = widget.fromPlayerId;
    _toPlayerId = widget.toPlayerId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_amountController.text.trim());
    if (!_members.any((member) => member.userId == _fromPlayerId) ||
        !_members.any((member) => member.userId == _toPlayerId)) {
      setState(() => _error = '房间成员已发生变化，请重新打开转换');
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
      ScoreTransfer(
        fromPlayerId: _fromPlayerId,
        toPlayerId: _toPlayerId,
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
            _TransferMemberSummary(
              label: '转出方',
              memberId: _fromPlayerId,
              members: _members,
              profiles: widget.profiles,
            ),
            const SizedBox(height: 8),
            const Icon(Icons.arrow_downward_rounded, size: 20),
            const SizedBox(height: 8),
            _TransferMemberSummary(
              label: '接收方',
              memberId: _toPlayerId,
              members: _members,
              profiles: widget.profiles,
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _unitLabel,
                suffixText: '当前 ${widget.totals[_fromPlayerId] ?? 0}',
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

class _TransferMemberSummary extends StatelessWidget {
  const _TransferMemberSummary({
    required this.label,
    required this.memberId,
    required this.members,
    required this.profiles,
  });

  final String label;
  final String memberId;
  final List<RoomMember> members;
  final Map<String, User> profiles;

  @override
  Widget build(BuildContext context) {
    RoomMember? member;
    for (final candidate in members) {
      if (candidate.userId == memberId) {
        member = candidate;
        break;
      }
    }
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(
        member == null ? '成员已离开房间' : memberLabel(member, profiles),
      ),
    );
  }
}

class RoundHistoryDialog extends StatelessWidget {
  const RoundHistoryDialog({super.key,
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
                              '${profileName(change.playerId, profiles)} ${change.value > 0 ? '+' : ''}${change.value}',
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

class ScoreDialog extends StatefulWidget {
  const ScoreDialog({super.key,
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
  State<ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<ScoreDialog> {
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
    if (widget.scoringMode == ScoringMode.money && sumChanges(changes) != 0) {
      setState(() => _error = '金额模式每局必须平账，当前差额为 ${sumChanges(changes)}');
      return;
    }
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      ScoreInput(changes: changes, note: note.isEmpty ? null : note),
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
                  labelText: profileName(member.userId, widget.profiles),
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
