import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'avatar_widgets.dart';
import 'design.dart';
import 'presentation_helpers.dart';

/// Fixed-direction transfer (我 → 被点击的牌友) submitted inside the dialog.
class ScoreTransferRequest {
  const ScoreTransferRequest({required this.toPlayerId, required this.amount});

  final String toPlayerId;
  final int amount;
}

/// 点头像后的转分弹窗：方向固定、金额框自动聚焦、常用金额可选。
///
/// 提交在弹窗内完成：保存中禁用按钮，失败保留输入并就地显示原因，
/// 成功后返回 true；取消或返回保留草稿（由调用方的 [ScoreDraftStore] 保存）。
class ScoreTransferDialog extends StatefulWidget {
  const ScoreTransferDialog({
    super.key,
    required this.actorId,
    required this.toPlayerId,
    required this.members,
    required this.profiles,
    required this.totals,
    required this.scoringMode,
    required this.onSubmit,
    this.roomName,
    this.sessionName,
    this.nextRoundNumber,
    this.initialAmount = '',
    this.onDraftChanged,
  });

  final String actorId;
  final String toPlayerId;
  final List<RoomMember> members;
  final Map<String, User> profiles;
  final Map<String, int> totals;
  final ScoringMode scoringMode;
  final Future<void> Function(ScoreTransferRequest request) onSubmit;
  final String? roomName;
  final String? sessionName;
  final int? nextRoundNumber;
  final String initialAmount;
  final ValueChanged<String>? onDraftChanged;

  @override
  State<ScoreTransferDialog> createState() => _ScoreTransferDialogState();
}

class _ScoreTransferDialogState extends State<ScoreTransferDialog> {
  static const _presets = [10, 20, 50];
  late final TextEditingController _amountController = TextEditingController(
    text: widget.initialAmount,
  );
  final _focusNode = FocusNode();
  bool _busy = false;
  String? _submitError;

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _unitWord => widget.scoringMode == ScoringMode.money ? '金额' : '积分';
  String get _amountLabel => pzAmountLabel(widget.scoringMode);

  String _name(String userId) => profileName(userId, widget.profiles);

  bool get _recipientActive => widget.members.any(
    (member) => member.isActive && member.userId == widget.toPlayerId,
  );

  int? get _amount =>
      pzParseScoreInteger(_amountController.text, positive: true);

  String? get _validationMessage {
    if (widget.actorId == widget.toPlayerId) return '不能给自己转分';
    if (!_recipientActive) return '该成员已不在房间，请重新打开转分';
    final raw = _amountController.text.trim();
    if (raw.isEmpty) return null;
    if (_amount == null) return '请输入大于 0 的有效整数$_unitWord';
    return null;
  }

  String get _contextLabel {
    final parts = <String>[
      if (widget.roomName != null) widget.roomName!,
      if (widget.sessionName != null) widget.sessionName!,
      if (widget.nextRoundNumber != null) '预计第 ${widget.nextRoundNumber} 回合',
    ];
    return parts.join(' · ');
  }

  void _selectPreset(int value) {
    _amountController.text = '$value';
    widget.onDraftChanged?.call('$value');
    setState(() => _submitError = null);
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (amount == null || _busy) {
      setState(() {});
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _submitError = null;
    });
    try {
      await widget.onSubmit(
        ScoreTransferRequest(toPlayerId: widget.toPlayerId, amount: amount),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _submitError = mapAppError(error).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _deltaText(int? value, {required bool lead}) {
    final c = PzColors.of(context);
    if (value == null) {
      return Text('—', style: pzMonoStyle(size: 17, color: c.muted));
    }
    return Text(
      pzSigned(value),
      style: pzMonoStyle(size: 17, color: lead ? c.win : c.lose),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final amount = _amount;
    final actorName = _name(widget.actorId);
    final recipientName = _name(widget.toPlayerId);
    final actorTotal = widget.totals[widget.actorId] ?? 0;
    final recipientTotal = widget.totals[widget.toPlayerId] ?? 0;
    final validation = _validationMessage;
    final canSubmit = validation == null && amount != null && !_busy;
    return PopScope(
      canPop: !_busy,
      child: PzDialogShell(
        title: '转分给$recipientName',
        subtitle: _contextLabel.isEmpty ? null : _contextLabel,
        actions: [
          PzButton(
            label: '取消',
            tone: PzButtonTone.secondary,
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          PzButton(
            label: '确认转分',
            busy: _busy,
            onPressed: canSubmit ? _submit : null,
          ),
        ],
        children: [
          PzBoard(
            background: c.sunken,
            dividerBetween: false,
            children: [
              PzBoardRow(
                avatar: UserAvatar(
                  name: actorName,
                  avatarKey: widget.profiles[widget.actorId]?.avatarKey,
                  avatarUrl: widget.profiles[widget.actorId]?.avatarUrl,
                  radius: 15,
                ),
                title: '我',
                detail: '转出方固定',
                trailing: _deltaText(
                  amount == null ? null : -amount,
                  lead: false,
                ),
              ),
              PzBoardRow(
                avatar: UserAvatar(
                  name: recipientName,
                  avatarKey: widget.profiles[widget.toPlayerId]?.avatarKey,
                  avatarUrl: widget.profiles[widget.toPlayerId]?.avatarUrl,
                  radius: 15,
                ),
                title: recipientName,
                detail: '接收方固定',
                trailing: _deltaText(amount, lead: true),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PzLabel(_amountLabel),
              PzTextField(
                controller: _amountController,
                focusNode: _focusNode,
                autofocus: true,
                hint: '请输入正整数$_unitWord',
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                onChanged: (value) {
                  widget.onDraftChanged?.call(value);
                  setState(() => _submitError = null);
                },
                onSubmitted: (_) {
                  if (canSubmit) _submit();
                },
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            children: [
              for (final preset in _presets)
                PzChip(
                  label: '$preset',
                  hot: _amountController.text.trim() == '$preset',
                  onTap: _busy ? null : () => _selectPreset(preset),
                ),
            ],
          ),
          PzHint(
            amount == null
                ? '输入金额后预览双方变化。'
                : '预计累计：$actorName ${pzSigned(actorTotal - amount)} · '
                      '$recipientName ${pzSigned(recipientTotal + amount)}',
          ),
          PzFormError(_submitError ?? validation),
        ],
      ),
    );
  }
}
