import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'presentation_helpers.dart';

class MultiScoreTransferDialog extends StatefulWidget {
  const MultiScoreTransferDialog({
    super.key,
    required this.actorId,
    required this.members,
    required this.profiles,
    required this.scoringMode,
    required this.onSubmit,
  });

  final String actorId;
  final List<RoomMember> members;
  final Map<String, User> profiles;
  final ScoringMode scoringMode;
  final Future<void> Function(Map<String, int> amounts) onSubmit;

  @override
  State<MultiScoreTransferDialog> createState() =>
      _MultiScoreTransferDialogState();
}

class _MultiScoreTransferDialogState extends State<MultiScoreTransferDialog> {
  late final _amounts = {
    for (final member in widget.members)
      if (member.isActive && member.userId != widget.actorId)
        member.userId: TextEditingController(),
  };
  final _selected = <String>{};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _amounts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _unit => scoreUnitLabel(widget.scoringMode);
  int get _total => _selected.fold(
    0,
    (sum, id) => sum + (int.tryParse(_amounts[id]!.text.trim()) ?? 0),
  );

  Future<void> _submit() async {
    if (_busy) return;
    final values = <String, int>{};
    String? error;
    if (_selected.isEmpty) error = '请至少选择一位接收人';
    var total = 0;
    for (final id in _selected) {
      final value = int.tryParse(_amounts[id]!.text.trim());
      if (value == null || value <= 0 || value > 2147483647) {
        error = '${profileName(id, widget.profiles)}：请输入有效的正整数';
        break;
      }
      values[id] = value;
      total += value;
      if (total > 2147483647) {
        error = '本次转出总额超出允许范围';
        break;
      }
    }
    if (error != null) {
      setState(() => _error = error);
      FocusScope.of(context).unfocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认多人转分'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('转出方：${profileName(widget.actorId, widget.profiles)}（我）'),
                const SizedBox(height: 12),
                for (final entry in values.entries)
                  Text(
                    '${profileName(entry.key, widget.profiles)} +${entry.value} $_unit',
                  ),
                const SizedBox(height: 12),
                Text('合计转出：$total $_unit'),
                const Text('本次作为一条记录保存，所有接收人一起提交。'),
              ],
            ),
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
      );
      if (confirmed != true || !mounted) return;
      await widget.onSubmit(Map.unmodifiable(values));
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) setState(() => _error = mapAppError(failure).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * .84,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('多人转分', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '转出方：${profileName(widget.actorId, widget.profiles)}（我）',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_amounts.isEmpty) const Text('没有其他可接收分数的成员'),
                      for (final entry in _amounts.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Checkbox(
                                key: ValueKey('recipient-${entry.key}'),
                                value: _selected.contains(entry.key),
                                onChanged: _busy
                                    ? null
                                    : (checked) => setState(() {
                                        if (checked == true) {
                                          _selected.add(entry.key);
                                        } else {
                                          _selected.remove(entry.key);
                                        }
                                        _error = null;
                                      }),
                              ),
                              Expanded(
                                child: Text(
                                  profileName(entry.key, widget.profiles),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 112,
                                child: TextField(
                                  key: ValueKey('transfer-amount-${entry.key}'),
                                  controller: entry.value,
                                  enabled:
                                      !_busy && _selected.contains(entry.key),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: '分值',
                                    suffixText: _unit,
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (_) =>
                                      setState(() => _error = null),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('已选 ${_selected.length} 人 · 合计转出 $_total $_unit'),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? '正在提交…' : '核对并提交'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
