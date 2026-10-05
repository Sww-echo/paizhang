import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';

import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/settlement_calculator.dart';
import 'avatar_widgets.dart';
import 'presentation_helpers.dart';
import '../infrastructure/backend/app_error_mapper.dart';

import 'dart:ui' as ui;

class SettlementPage extends StatefulWidget {
  const SettlementPage({
    super.key,
    required this.room,
    required this.session,
    required this.rounds,
    required this.profiles,
  });

  final Room room;
  final GameSession session;
  final List<Round> rounds;
  final Map<String, User> profiles;

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  final _shareCardKey = GlobalKey();

  Room get room => widget.room;
  GameSession get session => widget.session;
  List<Round> get rounds => widget.rounds;
  Map<String, User> get profiles => widget.profiles;

  String _summaryText(
    SettlementResult result,
    List<MapEntry<String, int>> ranking,
    String unit,
  ) {
    final lines = <String>['${session.name} · 结算', '累计排名：'];
    for (var index = 0; index < ranking.length; index++) {
      final entry = ranking[index];
      lines.add(
        '${index + 1}. ${profileName(entry.key, profiles)} ${entry.value > 0 ? '+' : ''}${entry.value} $unit',
      );
    }
    if (!result.isBalanced) {
      lines.add('金额差额：${result.unbalancedAmount}');
    } else if (result.transfers.isNotEmpty) {
      lines.add('转账：');
      for (final transfer in result.transfers) {
        lines.add(
          '${profileName(transfer.fromPlayerId, profiles)} → ${profileName(transfer.toPlayerId, profiles)} ${transfer.amount} $unit',
        );
      }
    } else {
      lines.add('当前没有需要转账的差额。');
    }
    return lines.join('\n');
  }

  Future<void> _shareSummary(String summary) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: summary, subject: '${session.name} · 结算'),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
    }
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
    final unit = scoreUnitLabel(room.scoringMode);

    return Scaffold(
      appBar: AppBar(
        title: Text('${session.name} · 结算'),
        actions: [
          IconButton(
            tooltip: '系统分享',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareSummary(_summaryText(result, ranking, unit)),
          ),
          IconButton(
            tooltip: '复制结算',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: _summaryText(result, ranking, unit)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('结算摘要已复制')));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: RepaintBoundary(
          key: _shareCardKey,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${session.name} · 结算',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_rounded),
                    title: Text(
                      '${rounds.where((round) => !round.isDeleted).length} 局有效记录',
                    ),
                    subtitle: Text(
                      room.scoringMode == ScoringMode.money ? '金额结算' : '积分结算',
                    ),
                  ),
                ),
                if (!result.isBalanced) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: const Text('暂不能完成金额结算'),
                      subtitle: Text(
                        '当前差额：${result.unbalancedAmount}，请先修正回合记录。',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  '累计排名',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < ranking.length; index++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(child: Text('${index + 1}')),
                        const SizedBox(width: 8),
                        UserAvatar(
                          name: profileName(ranking[index].key, profiles),
                          avatarKey: profiles[ranking[index].key]?.avatarKey,
                          avatarUrl: profiles[ranking[index].key]?.avatarUrl,
                          radius: 18,
                        ),
                      ],
                    ),
                    title: Text(profileName(ranking[index].key, profiles)),
                    trailing: Text(
                      '${ranking[index].value > 0 ? '+' : ''}${ranking[index].value} $unit',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                if (result.isBalanced && result.transfers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    '最少转账路径',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (final transfer in result.transfers)
                    Card(
                      elevation: 0,
                      child: ListTile(
                        leading: const Icon(Icons.arrow_forward_rounded),
                        title: Text(
                          '${profileName(transfer.fromPlayerId, profiles)} → ${profileName(transfer.toPlayerId, profiles)}',
                        ),
                        trailing: Text('${transfer.amount} $unit'),
                      ),
                    ),
                ],
                if (result.isBalanced && result.transfers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('当前没有需要转账的差额。'),
                  ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _shareImage(_summaryText(result, ranking, unit)),
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('分享结算图片'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
