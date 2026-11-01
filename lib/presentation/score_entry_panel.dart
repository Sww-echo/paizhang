import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'avatar_widgets.dart';
import 'design.dart';
import 'presentation_helpers.dart';

enum ScoreEntryMode { full, multi }

/// 整局录入草稿：原始文本 + 每个值的来源（manual / auto / split）。
class RoundEntryDraft {
  final Map<String, String> raw = {};
  final Map<String, String> sources = {};
  String note = '';
  bool auto = true;

  bool get isEmpty => raw.isEmpty && sources.isEmpty;
}

/// 多人转分草稿：接收人勾选与各自金额（取消勾选保留输入）。
class MultiEntryDraft {
  final Map<String, String> raw = {};
  final List<String> selected = [];

  bool get isEmpty => raw.isEmpty && selected.isEmpty;
}

/// 未提交表单草稿，按 账号 / 房间 / 牌局 / 模式 隔离；
/// 单人转分还按接收人区分。弹层关闭保留草稿，只有显式清空才丢弃。
class ScoreDraftStore {
  final Map<String, RoundEntryDraft> _full = {};
  final Map<String, MultiEntryDraft> _multi = {};
  final Map<String, String> _transferAmounts = {};

  static String _key(
    String actorId,
    String roomId,
    String sessionId,
    String mode,
    String extra,
  ) => '$actorId|$roomId|$sessionId|$mode|$extra';

  RoundEntryDraft full({
    required String actorId,
    required String roomId,
    required String sessionId,
  }) => _full.putIfAbsent(
    _key(actorId, roomId, sessionId, 'full', '-'),
    RoundEntryDraft.new,
  );

  MultiEntryDraft multi({
    required String actorId,
    required String roomId,
    required String sessionId,
  }) => _multi.putIfAbsent(
    _key(actorId, roomId, sessionId, 'multi', '-'),
    MultiEntryDraft.new,
  );

  String transferAmount({
    required String actorId,
    required String roomId,
    required String sessionId,
    required String recipientId,
  }) =>
      _transferAmounts[_key(
        actorId,
        roomId,
        sessionId,
        'transfer',
        recipientId,
      )] ??
      '';

  void setTransferAmount({
    required String actorId,
    required String roomId,
    required String sessionId,
    required String recipientId,
    required String raw,
  }) {
    _transferAmounts[_key(
          actorId,
          roomId,
          sessionId,
          'transfer',
          recipientId,
        )] =
        raw;
  }

  void clearFull({
    required String actorId,
    required String roomId,
    required String sessionId,
  }) => _full.remove(_key(actorId, roomId, sessionId, 'full', '-'));

  void clearMulti({
    required String actorId,
    required String roomId,
    required String sessionId,
  }) => _multi.remove(_key(actorId, roomId, sessionId, 'multi', '-'));

  void clearTransfer({
    required String actorId,
    required String roomId,
    required String sessionId,
    required String recipientId,
  }) => _transferAmounts.remove(
    _key(actorId, roomId, sessionId, 'transfer', recipientId),
  );

  /// 离开房间或账号切换时丢弃该房间的全部草稿。
  void clearRoom(String actorId, String roomId) {
    final prefix = '$actorId|$roomId|';
    _full.removeWhere((key, _) => key.startsWith(prefix));
    _multi.removeWhere((key, _) => key.startsWith(prefix));
    _transferAmounts.removeWhere((key, _) => key.startsWith(prefix));
  }
}

/// 面板内可切换的牌局（整局与多人模式）。
class ScoreEntrySession {
  const ScoreEntrySession({
    required this.id,
    required this.name,
    required this.nextRoundNumber,
    required this.totals,
  });

  final String id;
  final String name;
  final int nextRoundNumber;
  final Map<String, int> totals;
}

class RoundEntryComputation {
  const RoundEntryComputation({
    required this.valid,
    required this.values,
    required this.sum,
    required this.message,
    this.autoId,
  });

  final bool valid;
  final Map<String, int> values;
  final int sum;
  final String message;
  final String? autoId;
}

/// 整局净变化计算，规则与方案演示一致：
/// 空白 = 未指定；显式 0 = 手动值；自动补齐仅金额模式、仅剩一位空白。
RoundEntryComputation computeRoundEntry({
  required List<RoomMember> members,
  required RoundEntryDraft draft,
  required ScoringMode scoringMode,
  required Map<String, User> profiles,
}) {
  final values = <String, int>{};
  final missing = <String>[];
  var sum = 0;
  for (final member in members) {
    final raw = (draft.raw[member.userId] ?? '').trim();
    if (raw.isEmpty) {
      missing.add(member.userId);
      continue;
    }
    final value = pzParseScoreInteger(raw);
    if (value == null) {
      return RoundEntryComputation(
        valid: false,
        values: values,
        sum: sum,
        message: '${profileName(member.userId, profiles)}：请输入有效的整数净变化',
      );
    }
    values[member.userId] = value;
    sum += value;
  }
  String? autoId;
  if (scoringMode == ScoringMode.money &&
      draft.auto &&
      missing.length == 1 &&
      values.isNotEmpty) {
    autoId = missing.first;
    final autoValue = pzParseScoreInteger('${-sum}');
    if (autoValue == null) {
      return RoundEntryComputation(
        valid: false,
        values: values,
        sum: sum,
        message: '自动补齐超出允许范围，请调整输入',
      );
    }
    values[autoId] = autoValue;
    sum = 0;
  }
  final nonzero = values.values.any((value) => value != 0);
  final balanced = scoringMode == ScoringMode.points || sum == 0;
  final valid = nonzero && balanced;
  final message = !nonzero
      ? '至少填写一项非零变化'
      : !balanced
      ? '金额模式还需分配 ${pzSigned(-sum)}'
      : '';
  return RoundEntryComputation(
    valid: valid,
    values: values,
    sum: sum,
    message: message,
    autoId: autoId,
  );
}

class MultiEntryComputation {
  const MultiEntryComputation({
    required this.valid,
    required this.values,
    required this.total,
    required this.message,
  });

  final bool valid;
  final Map<String, int> values;
  final int total;
  final String message;
}

/// 多人转分计算：至少选一人，每项为正整数，合计转出即我的负变化。
MultiEntryComputation computeMultiEntry({
  required String actorId,
  required List<RoomMember> members,
  required MultiEntryDraft draft,
  required Map<String, User> profiles,
}) {
  if (draft.selected.isEmpty) {
    return const MultiEntryComputation(
      valid: false,
      values: {},
      total: 0,
      message: '请至少选择一位接收人',
    );
  }
  final values = <String, int>{};
  var total = 0;
  for (final id in draft.selected) {
    RoomMember? member;
    for (final candidate in members) {
      if (candidate.userId == id && candidate.isActive) member = candidate;
    }
    if (member == null || id == actorId) {
      return MultiEntryComputation(
        valid: false,
        values: values,
        total: total,
        message: '接收人无效或已不在房间',
      );
    }
    final amount = pzParseScoreInteger(draft.raw[id] ?? '', positive: true);
    if (amount == null) {
      return MultiEntryComputation(
        valid: false,
        values: values,
        total: total,
        message: '${profileName(id, profiles)}：请输入大于 0 的有效整数金额',
      );
    }
    values[id] = amount;
    total += amount;
    if (total > pzScoreLimit) {
      return MultiEntryComputation(
        valid: false,
        values: values,
        total: total,
        message: '合计转出超出允许范围',
      );
    }
  }
  values[actorId] = -total;
  return MultiEntryComputation(
    valid: true,
    values: values,
    total: total,
    message: '',
  );
}

/// 主动平摊：只分配给空白成员，不覆盖手动值；
/// 余数按固定加入顺序每人 1 个整数单位。返回给用户看的明细说明。
String applySplitToDraft({
  required List<RoomMember> members,
  required RoundEntryDraft draft,
  required Map<String, User> profiles,
}) {
  final missing = <String>[];
  var sum = 0;
  for (final member in members) {
    final raw = (draft.raw[member.userId] ?? '').trim();
    if (raw.isEmpty) {
      missing.add(member.userId);
      continue;
    }
    final value = pzParseScoreInteger(raw);
    if (value == null) return '先修正无效数字，再平摊';
    sum += value;
  }
  if (missing.isEmpty) return '没有未填成员，现有输入已保留';
  if (sum == 0) return '没有需要平摊的差额，现有输入已保留';
  final amounts = pzSplitAmount(-sum, missing.length);
  if (amounts.any((value) => pzParseScoreInteger('$value') == null)) {
    return '平摊金额超出允许范围';
  }
  for (var index = 0; index < missing.length; index++) {
    draft.raw[missing[index]] = '${amounts[index]}';
    draft.sources[missing[index]] = 'split';
  }
  final detail = [
    for (var index = 0; index < missing.length; index++)
      '${profileName(missing[index], profiles)} ${pzSigned(amounts[index])}',
  ].join('，');
  return '平摊明细：$detail。手动值已保留。';
}

/// 整局 / 多人录入面板：录入与只读核对在同一面板内切换。
///
/// 保存成功返回 `true`；取消返回 `null`。保存中禁用提交，
/// 失败保留输入并就地显示原因，不关闭面板。
class ScoreEntryPanel extends StatefulWidget {
  const ScoreEntryPanel({
    super.key,
    required this.mode,
    this.title,
    required this.actorId,
    required this.roomId,
    required this.roomName,
    required this.members,
    required this.profiles,
    required this.scoringMode,
    required this.sessions,
    required this.initialSessionId,
    required this.drafts,
    required this.onSave,
    this.onSaveWithNote,
  });

  final ScoreEntryMode mode;

  /// 面板标题覆盖（编辑回合等场景）。
  final String? title;
  final String actorId;
  final String roomId;
  final String roomName;

  /// 按固定加入顺序排列；编辑时还包含原回合的离开成员，其值只读。
  final List<RoomMember> members;
  final Map<String, User> profiles;
  final ScoringMode scoringMode;
  final List<ScoreEntrySession> sessions;
  final String initialSessionId;
  final ScoreDraftStore drafts;
  final Future<void> Function(String sessionId, List<ScoreChange> changes)
  onSave;
  final Future<void> Function(
    String sessionId,
    List<ScoreChange> changes,
    String? note,
  )?
  onSaveWithNote;

  @override
  State<ScoreEntryPanel> createState() => _ScoreEntryPanelState();
}

class _ScoreEntryPanelState extends State<ScoreEntryPanel> {
  late String _sessionId = _resolveInitialSession();
  bool _reviewing = false;
  bool _busy = false;
  String? _submitError;
  String? _splitHint;
  Map<String, int>? _reviewValues;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  late final TextEditingController _noteController = TextEditingController();

  String _resolveInitialSession() {
    for (final session in widget.sessions) {
      if (session.id == widget.initialSessionId) return session.id;
    }
    return widget.sessions.isEmpty ? '' : widget.sessions.first.id;
  }

  ScoreEntrySession? get _session {
    for (final session in widget.sessions) {
      if (session.id == _sessionId) return session;
    }
    return null;
  }

  String get _unit => pzScoreUnit(widget.scoringMode);

  RoundEntryDraft get _fullDraft => widget.drafts.full(
    actorId: widget.actorId,
    roomId: widget.roomId,
    sessionId: _sessionId,
  );

  MultiEntryDraft get _multiDraft => widget.drafts.multi(
    actorId: widget.actorId,
    roomId: widget.roomId,
    sessionId: _sessionId,
  );

  TextEditingController _controllerFor(String memberId) =>
      _controllers.putIfAbsent(
        memberId,
        () => TextEditingController(text: _draftRawFor(memberId)),
      );

  FocusNode _focusFor(String memberId) =>
      _focusNodes.putIfAbsent(memberId, FocusNode.new);

  String _draftRawFor(String memberId) => widget.mode == ScoreEntryMode.full
      ? (_fullDraft.raw[memberId] ?? '')
      : (_multiDraft.raw[memberId] ?? '');

  @override
  void initState() {
    super.initState();
    _noteController.text = _fullDraft.note;
    _syncAutoValue();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// 自动补齐的值只写入输入框，不进入草稿 raw；用户修改后才转为手动值。
  void _syncAutoValue() {
    if (widget.mode != ScoreEntryMode.full) return;
    final session = _session;
    if (session == null) return;
    final computation = _computeFull();
    final autoId = computation.autoId;
    if (autoId == null) return;
    final controller = _controllers[autoId];
    if (controller == null || (_focusNodes[autoId]?.hasFocus ?? false)) return;
    final text = '${computation.values[autoId]}';
    if (controller.text != text) controller.text = text;
  }

  RoundEntryComputation _computeFull() => computeRoundEntry(
    members: widget.members,
    draft: _fullDraft,
    scoringMode: widget.scoringMode,
    profiles: widget.profiles,
  );

  MultiEntryComputation _computeMulti() => computeMultiEntry(
    actorId: widget.actorId,
    members: widget.members,
    draft: _multiDraft,
    profiles: widget.profiles,
  );

  void _switchSession(String? sessionId) {
    if (sessionId == null || sessionId == _sessionId) return;
    _fullDraft.note = _noteController.text;
    setState(() {
      _sessionId = sessionId;
      _noteController.text = _fullDraft.note;
      _splitHint = null;
      _submitError = null;
      _reviewing = false;
      _reviewValues = null;
      for (final entry in _controllers.entries) {
        entry.value.text = _draftRawFor(entry.key);
      }
    });
    _syncAutoValue();
  }

  void _handleFullChanged(String memberId, String text) {
    if (!widget.members.any((m) => m.userId == memberId && m.isActive)) return;
    final draft = _fullDraft;
    draft.raw[memberId] = text;
    draft.sources[memberId] = 'manual';
    setState(() {
      _splitHint = null;
      _submitError = null;
    });
    _syncAutoValue();
  }

  void _toggleAuto(bool value) {
    setState(() {
      _fullDraft.auto = value;
      _splitHint = null;
      for (final member in widget.members) {
        final controller = _controllers[member.userId];
        if (controller == null) continue;
        final text = _fullDraft.raw[member.userId] ?? '';
        if (controller.text != text) controller.text = text;
      }
    });
    if (value) _syncAutoValue();
  }

  void _toggleSign(String memberId) {
    if (!widget.members.any((m) => m.userId == memberId && m.isActive)) return;
    final draft = _fullDraft;
    final value = pzParseScoreInteger(draft.raw[memberId] ?? '');
    draft.raw[memberId] = value == null
        ? '-'
        : value == 0
        ? '0'
        : '${-value}';
    draft.sources[memberId] = 'manual';
    _controllerFor(memberId).text = draft.raw[memberId]!;
    setState(() {
      _splitHint = null;
      _submitError = null;
    });
    _syncAutoValue();
  }

  void _applySplit() {
    final message = applySplitToDraft(
      members: widget.members,
      draft: _fullDraft,
      profiles: widget.profiles,
    );
    setState(() {
      _splitHint = message;
      _submitError = null;
      for (final member in widget.members) {
        final controller = _controllers[member.userId];
        if (controller == null) continue;
        final text = _fullDraft.raw[member.userId] ?? '';
        if (controller.text != text) controller.text = text;
      }
    });
    _syncAutoValue();
  }

  void _handleMultiChanged(String memberId, String text) {
    _multiDraft.raw[memberId] = text;
    setState(() => _submitError = null);
  }

  void _handleNoteChanged(String text) {
    _fullDraft.note = text;
    setState(() => _submitError = null);
  }

  void _toggleRecipient(String memberId, bool selected) {
    final draft = _multiDraft;
    setState(() {
      if (selected) {
        if (!draft.selected.contains(memberId)) draft.selected.add(memberId);
      } else {
        draft.selected.remove(memberId);
      }
      _submitError = null;
    });
  }

  List<ScoreChange> _orderedChanges(Map<String, int> values) => [
    for (final member in widget.members)
      if (values.containsKey(member.userId))
        ScoreChange(playerId: member.userId, value: values[member.userId]!),
  ];

  void _startReview() {
    final values = widget.mode == ScoreEntryMode.full
        ? _computeFull().values
        : _computeMulti().values;
    setState(() {
      _reviewing = true;
      _reviewValues = values;
      _submitError = null;
    });
  }

  void _backToEntry() => setState(() {
    _reviewing = false;
    _reviewValues = null;
    _submitError = null;
  });

  Future<void> _submitReview() async {
    final values = _reviewValues;
    if (values == null || _busy) return;
    final changes = _orderedChanges(values);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _submitError = null;
    });
    try {
      final note = widget.mode == ScoreEntryMode.full
          ? _fullDraft.note.trim().isEmpty
                ? null
                : _fullDraft.note.trim()
          : null;
      final onSaveWithNote = widget.onSaveWithNote;
      if (onSaveWithNote != null) {
        await onSaveWithNote(_sessionId, changes, note);
      } else {
        await widget.onSave(_sessionId, changes);
      }
      // 面板内可以切换牌局，只清理实际保存的草稿。
      if (widget.mode == ScoreEntryMode.full) {
        widget.drafts.clearFull(
          actorId: widget.actorId,
          roomId: widget.roomId,
          sessionId: _sessionId,
        );
      } else {
        widget.drafts.clearMulti(
          actorId: widget.actorId,
          roomId: widget.roomId,
          sessionId: _sessionId,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _submitError = mapAppError(error).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _memberName(String memberId) => memberId == widget.actorId
      ? '${profileName(memberId, widget.profiles)}（我）'
      : profileName(memberId, widget.profiles);

  List<Widget> _contextChildren(ScoreEntrySession session) => [
    PzContextBox(
      title: '${widget.roomName} · ${session.name}',
      subtitle: _reviewing
          ? '预计第 ${session.nextRoundNumber} 回合 · 核对本回合变化与预计累计'
          : '预计第 ${session.nextRoundNumber} 回合 · ${pzAmountLabel(widget.scoringMode)}',
    ),
    if (!_reviewing && widget.sessions.length > 1) ...[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PzLabel('当前牌局'),
          PzDropdown<String>(
            value: _sessionId,
            enabled: !_busy,
            items: [
              for (final option in widget.sessions)
                DropdownMenuItem(value: option.id, child: Text(option.name)),
            ],
            onChanged: _switchSession,
          ),
          const SizedBox(height: 6),
          const PzHint('切换时保留当前草稿，另一场的输入独立显示。'),
        ],
      ),
    ],
  ];

  Widget _fullRow(RoomMember member, RoundEntryComputation computation) {
    final c = PzColors.of(context);
    final draft = _fullDraft;
    final isAuto = computation.autoId == member.userId;
    final isSplit = draft.sources[member.userId] == 'split';
    final raw = (draft.raw[member.userId] ?? '').trim();
    final value = computation.values[member.userId];
    final sourceLabel = !member.isActive
        ? '已离开成员 · 原分数保留'
        : isAuto
        ? '自动补齐 ${pzSigned(value ?? 0)}，可直接修改'
        : isSplit
        ? '平摊填入，可直接修改'
        : raw.isEmpty
        ? '未填写'
        : '手动值，不自动覆盖';
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        children: [
          UserAvatar(
            name: profileName(member.userId, widget.profiles),
            avatarKey: widget.profiles[member.userId]?.avatarKey,
            avatarUrl: widget.profiles[member.userId]?.avatarUrl,
            radius: 15,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profileName(member.userId, widget.profiles),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sourceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PzChip(
            key: ValueKey('sign-${member.userId}'),
            label: '＋ / −',
            enabled: !_busy && member.isActive,
            onTap: () => _toggleSign(member.userId),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: PzTextField(
              fieldKey: ValueKey('full-${member.userId}'),
              controller: _controllerFor(member.userId),
              focusNode: _focusFor(member.userId),
              enabled: !_busy,
              readOnly: !member.isActive,
              autoFill: isAuto || isSplit,
              textAlign: TextAlign.right,
              hint: isAuto ? '自动 ${pzSigned(value ?? 0)}' : '净变化',
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              semanticsLabel:
                  '${profileName(member.userId, widget.profiles)} 净变化',
              onChanged: (text) => _handleFullChanged(member.userId, text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _multiRow(RoomMember member, MultiEntryComputation computation) {
    final c = PzColors.of(context);
    final draft = _multiDraft;
    final selected = draft.selected.contains(member.userId);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        children: [
          Checkbox(
            key: ValueKey('recipient-${member.userId}'),
            value: selected,
            onChanged: _busy
                ? null
                : (value) => _toggleRecipient(member.userId, value ?? false),
            activeColor: c.brand,
            checkColor: c.onBrand,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profileName(member.userId, widget.profiles),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? '接收金额' : '未选择',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: PzTextField(
              fieldKey: ValueKey('transfer-amount-${member.userId}'),
              controller: _controllerFor(member.userId),
              enabled: !_busy && selected,
              textAlign: TextAlign.right,
              hint: '金额',
              keyboardType: TextInputType.number,
              semanticsLabel:
                  '${profileName(member.userId, widget.profiles)} 接收金额',
              onChanged: (text) => _handleMultiChanged(member.userId, text),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _entryChildren(ScoreEntrySession session) {
    if (widget.mode == ScoreEntryMode.full) {
      final computation = _computeFull();
      final hasInput = _fullDraft.raw.values.any(
        (value) => value.trim().isNotEmpty,
      );
      final meterValue = computation.valid
          ? widget.scoringMode == ScoringMode.money
                ? '0 · 已平账'
                : '${pzSigned(computation.sum)} · 允许不平账'
          : !hasInput
          ? '尚未填写'
          : '${pzSigned(computation.sum)} · ${computation.message}';
      return [
        ..._contextChildren(session),
        const PzHint('填写每位成员的净变化：正数为赢，负数为输。'),
        PzBoard(
          title: '本回合净变化',
          children: [
            for (final member in widget.members) _fullRow(member, computation),
          ],
        ),
        PzBoard(
          title: '备注（可选）',
          children: [
            Padding(
              padding: const EdgeInsets.all(13),
              child: PzTextField(
                fieldKey: const ValueKey('round-note'),
                controller: _noteController,
                enabled: !_busy,
                maxLength: 120,
                hint: '记录本回合的说明',
                textInputAction: TextInputAction.done,
                semanticsLabel: '回合备注',
                onChanged: _handleNoteChanged,
              ),
            ),
          ],
        ),
        if (widget.scoringMode == ScoringMode.money)
          PzCheckline(
            label: '自动补齐最后一位未填成员',
            value: _fullDraft.auto,
            onChanged: _busy ? null : _toggleAuto,
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: PzChip(label: '平摊给未填成员', enabled: !_busy, onTap: _applySplit),
        ),
        if (_splitHint != null) PzHint(_splitHint!),
        PzMeter(
          label: widget.scoringMode == ScoringMode.money ? '本回合差额' : '本回合合计',
          value: meterValue,
          tone: computation.valid
              ? PzMeterTone.balanced
              : hasInput
              ? PzMeterTone.unbalanced
              : PzMeterTone.neutral,
        ),
        PzFormError(_submitError ?? (hasInput ? computation.message : null)),
      ];
    }
    final computation = _computeMulti();
    final hasInput = _multiDraft.raw.values.any(
      (value) => value.trim().isNotEmpty,
    );
    final recipients = widget.members
        .where((member) => member.userId != widget.actorId)
        .toList();
    final detail = computation.valid
        ? [
            for (final member in widget.members)
              if (computation.values.containsKey(member.userId))
                '${profileName(member.userId, widget.profiles)} '
                    '${pzSigned(computation.values[member.userId]!)}',
          ].join(' · ')
        : null;
    return [
      ..._contextChildren(session),
      PzHint('转出方：${_memberName(widget.actorId)} · 勾选接收人并分别填金额'),
      PzBoard(
        title: '接收人',
        children: [
          if (recipients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(13),
              child: PzHint('没有其他可接收分数的成员'),
            ),
          for (final member in recipients) _multiRow(member, computation),
        ],
      ),
      PzMeter(
        label: '合计转出',
        value: computation.valid ? '${computation.total} $_unit' : '待填写完整金额',
        tone: computation.valid ? PzMeterTone.balanced : PzMeterTone.neutral,
      ),
      if (detail != null) PzHint('本回合：$detail'),
      PzFormError(_submitError ?? (hasInput ? computation.message : null)),
    ];
  }

  List<Widget> _reviewChildren(ScoreEntrySession session) {
    final values = _reviewValues ?? const <String, int>{};
    return [
      ..._contextChildren(session),
      PzBoard(
        dividerBetween: false,
        children: [
          for (final member in widget.members)
            if (values.containsKey(member.userId))
              PzBoardRow(
                avatar: UserAvatar(
                  name: profileName(member.userId, widget.profiles),
                  avatarKey: widget.profiles[member.userId]?.avatarKey,
                  avatarUrl: widget.profiles[member.userId]?.avatarUrl,
                  radius: 15,
                ),
                title: member.userId == widget.actorId
                    ? '我'
                    : profileName(member.userId, widget.profiles),
                detail:
                    '预计累计 '
                    '${pzSigned((session.totals[member.userId] ?? 0) + values[member.userId]!)}',
                trailing: PzScoreText(
                  values[member.userId]!,
                  unit: _unit,
                  size: 17,
                ),
              ),
        ],
      ),
      if (widget.mode == ScoreEntryMode.full &&
          _fullDraft.note.trim().isNotEmpty)
        PzHint('备注：${_fullDraft.note.trim()}'),
      const PzHint('确认摘要只读。需要改动时返回输入态，重新校验后再核对。'),
      PzFormError(_submitError),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return PzDialogShell(
        title:
            widget.title ??
            (widget.mode == ScoreEntryMode.full ? '整局录入' : '多人转分'),
        actions: [
          PzButton(
            label: '返回记分台',
            tone: PzButtonTone.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        children: const [PzHint('暂无进行中的牌局，请先开始一场。')],
      );
    }
    final canReview = widget.mode == ScoreEntryMode.full
        ? _computeFull().valid
        : _computeMulti().valid;
    return PopScope(
      canPop: !_busy,
      child: PzDialogShell(
        title: _reviewing
            ? '核对本回合'
            : widget.title ??
                  (widget.mode == ScoreEntryMode.full ? '整局录入' : '多人转分'),
        maxWidth: 560,
        actions: _reviewing
            ? [
                PzButton(
                  label: '返回修改',
                  tone: PzButtonTone.secondary,
                  onPressed: _busy ? null : _backToEntry,
                ),
                PzButton(label: '确认保存', busy: _busy, onPressed: _submitReview),
              ]
            : [
                PzButton(
                  label: '返回记分台',
                  tone: PzButtonTone.secondary,
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                ),
                PzButton(
                  label: '核对',
                  onPressed: canReview ? _startReview : null,
                ),
              ],
        children: _reviewing
            ? _reviewChildren(session)
            : _entryChildren(session),
      ),
    );
  }
}
