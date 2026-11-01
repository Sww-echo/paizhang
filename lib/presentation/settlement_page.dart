import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models.dart';
import '../domain/settlement_calculator.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'avatar_widgets.dart';
import 'design.dart';
import 'presentation_helpers.dart';

/// 结算与分享：优先展示谁给谁多少，完整名次紧随其后。
///
/// 查看结算不会自动结束牌局。存在未确认变化时明显标注「暂定结果」，
/// 并写入分享图；不平账时显示差额而不是转账方案。
class SettlementPage extends StatefulWidget {
  const SettlementPage({
    super.key,
    required this.room,
    required this.session,
    required this.rounds,
    required this.profiles,
    this.currentUserId,
    this.pendingCount = 0,
    this.conflictCount = 0,
  });

  final Room room;
  final GameSession session;
  final List<Round> rounds;
  final Map<String, User> profiles;
  final String? currentUserId;
  final int pendingCount;
  final int conflictCount;

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  final _shareCardKey = GlobalKey();

  Room get room => widget.room;
  GameSession get session => widget.session;
  List<Round> get rounds => widget.rounds;
  Map<String, User> get profiles => widget.profiles;

  String get _unit => pzScoreUnit(room.scoringMode);

  int get _validRoundCount => rounds.where((round) => !round.isDeleted).length;

  bool get _provisional => widget.pendingCount > 0 || widget.conflictCount > 0;

  String get _confirmationLabel {
    final parts = <String>[
      if (widget.pendingCount > 0) '${widget.pendingCount} 条待同步',
      if (widget.conflictCount > 0) '${widget.conflictCount} 条冲突',
    ];
    if (parts.isNotEmpty) return '暂定结果 · ${parts.join(' · ')}';
    return session.status == GameSessionStatus.active ? '截至当前' : '已确认结果';
  }

  String get _dateLabel {
    final date = sessionDate(session).toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _summaryText(
    SettlementResult result,
    List<MapEntry<String, int>> ranking,
  ) {
    final lines = <String>[
      '${room.name} · ${session.name} · $_dateLabel',
      '$_validRoundCount 回合有效 · $_confirmationLabel',
      '累计排名：',
      for (var index = 0; index < ranking.length; index++)
        '${index + 1}. ${profileName(ranking[index].key, profiles)} '
            '${pzSigned(ranking[index].value)} $_unit',
    ];
    if (!result.isBalanced) {
      lines.add('金额差额：${result.unbalancedAmount}，请先修正回合记录。');
    } else if (result.transfers.isNotEmpty) {
      lines.add('建议转账路径：');
      for (final transfer in result.transfers) {
        lines.add(
          '${profileName(transfer.fromPlayerId, profiles)} → '
          '${profileName(transfer.toPlayerId, profiles)} '
          '${transfer.amount} $_unit',
        );
      }
    } else {
      lines.add('当前没有需要转账的差额。');
    }
    return lines.join('\n');
  }

  Future<void> _shareImage(String summary) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = _shareCardKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('结算卡片尚未准备好，请稍后再试');
      }
      final image = await renderObject.toImage(pixelRatio: 3);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw StateError('结算图片生成失败');
        await SharePlus.instance.share(
          ShareParams(
            text: summary,
            subject: '${session.name} · 结算',
            files: [
              XFile.fromData(
                byteData.buffer.asUint8List(),
                mimeType: 'image/png',
                name: 'paizhang-settlement.png',
              ),
            ],
            fileNameOverrides: const ['paizhang-settlement.png'],
          ),
        );
      } finally {
        image.dispose();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
    }
  }

  Widget _heroCard(
    BuildContext context,
    List<MapEntry<String, int>> ranking,
    int total,
  ) {
    final c = PzColors.of(context);
    final currentUserId = widget.currentUserId;
    final heroEntry =
        ranking.where((entry) => entry.key == currentUserId).firstOrNull ??
        (ranking.isEmpty ? null : ranking.first);
    final others = ranking.where((entry) => entry.key != heroEntry?.key);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.hero, borderRadius: PzRadius.cardAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${room.name} · ${session.name} · $_dateLabel',
            style: TextStyle(fontSize: 12, color: c.heroSub),
          ),
          const SizedBox(height: 8),
          if (heroEntry != null)
            Text(
              '${profileName(heroEntry.key, profiles)} '
              '${pzSigned(heroEntry.value)} $_unit',
              style: pzMonoStyle(size: 26, color: c.heroInk),
            ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              others
                  .map(
                    (entry) =>
                        '${profileName(entry.key, profiles)} '
                        '${pzSigned(entry.value)}',
                  )
                  .join(' · '),
              style: TextStyle(fontSize: 13, height: 1.5, color: c.heroInk),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '$_validRoundCount 回合有效 · 合计 ${pzSigned(total)}',
            style: TextStyle(fontSize: 12, color: c.heroSub),
          ),
          const SizedBox(height: 2),
          Text(
            _confirmationLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _provisional ? c.warn : c.heroSub,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = const SettlementCalculator().calculate(
      rounds,
      room.scoringMode,
    );
    final participantIds = <String>{
      ...room.members.map((member) => member.userId),
      ...result.totals.keys,
    };
    final totals = <String, int>{
      for (final playerId in participantIds)
        playerId: result.totals[playerId] ?? 0,
    };
    final ranking = totals.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final total = totals.values.fold<int>(0, (sum, value) => sum + value);
    final summary = _summaryText(result, ranking);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${session.name} · 结算',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RepaintBoundary(
              key: _shareCardKey,
              child: Container(
                color: PzColors.of(context).bg,
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroCard(context, ranking, total),
                    const SizedBox(height: 16),
                    if (!result.isBalanced)
                      PzNotice(
                        title: '金额不平账',
                        message:
                            '当前差额：${result.unbalancedAmount}，请先修正回合记录；'
                            '不平账时不生成转账方案。',
                      )
                    else if (result.transfers.isNotEmpty) ...[
                      const PzLabel('建议转账路径'),
                      PzBoard(
                        children: [
                          for (final transfer in result.transfers)
                            PzBoardRow(
                              title:
                                  '${profileName(transfer.fromPlayerId, profiles)} → '
                                  '${profileName(transfer.toPlayerId, profiles)}',
                              detail: room.scoringMode == ScoringMode.money
                                  ? '按当前累计差额匹配'
                                  : null,
                              trailing: Text(
                                '${transfer.amount} $_unit',
                                style: pzMonoStyle(
                                  size: 15,
                                  color: PzColors.of(context).fg,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ] else
                      const PzHint('当前没有需要转账的差额。'),
                    const SizedBox(height: 16),
                    const PzLabel('累计排名'),
                    PzBoard(
                      children: [
                        for (var index = 0; index < ranking.length; index++)
                          PzBoardRow(
                            rank: '${index + 1}',
                            avatar: UserAvatar(
                              name: profileName(ranking[index].key, profiles),
                              avatarKey:
                                  profiles[ranking[index].key]?.avatarKey,
                              avatarUrl:
                                  profiles[ranking[index].key]?.avatarUrl,
                              radius: 15,
                            ),
                            title: ranking[index].key == widget.currentUserId
                                ? '我'
                                : profileName(ranking[index].key, profiles),
                            detail: ranking[index].key == widget.currentUserId
                                ? profileName(ranking[index].key, profiles)
                                : null,
                            trailing: PzScoreText(
                              ranking[index].value,
                              unit: _unit,
                              size: 17,
                            ),
                          ),
                      ],
                    ),
                    if (_provisional) ...[
                      const SizedBox(height: 12),
                      PzHint('有未确认变化，核对后再按结果结算。'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PzButton(
              label: '分享结算图片',
              icon: Icons.image_rounded,
              onPressed: () => _shareImage(summary),
            ),
            const SizedBox(height: 8),
            PzButton(
              label: '复制摘要',
              tone: PzButtonTone.ghost,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: summary));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('结算摘要已复制')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
