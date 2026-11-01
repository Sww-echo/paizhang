import 'package:flutter/material.dart';

import '../application/room_controller.dart';
import '../infrastructure/local/app_database.dart';
import 'design.dart';

/// 连接、队列与权限独立表达：可以同时显示「离线 · 2 条待同步 · 1 条冲突」。
///
/// 需要处理的记录就近提示，动作与房间页保持一致（重新确认 / 重试 / 放弃）。
class SyncStatusPanel extends StatelessWidget {
  const SyncStatusPanel({
    required this.controller,
    required this.onResolve,
    required this.onDiscard,
    required this.onRetry,
    super.key,
  });

  final RoomController controller;
  final Future<void> Function(SyncQueueEntry entry) onResolve;
  final Future<void> Function(SyncQueueEntry entry) onDiscard;
  final Future<void> Function(SyncQueueEntry entry) onRetry;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final failures = controller.failures;
    final pending = controller.pendingCount;
    final conflicts = failures
        .where((entry) => entry.status == 'conflict')
        .length;
    final retrying = controller.operations
        .where((entry) => entry.status == 'retrying')
        .toList();
    final offline = controller.error?.isRetryable == true;
    final nothingToShow =
        !offline &&
        pending == 0 &&
        failures.isEmpty &&
        retrying.isEmpty &&
        controller.error == null;
    if (nothingToShow && !controller.refreshing) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.refreshing)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(
              minHeight: 2,
              color: c.brand,
              backgroundColor: c.sunken,
            ),
          ),
        if (!nothingToShow)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PzPill(
                  offline ? '离线 · 使用本地缓存' : '在线',
                  tone: offline ? PzPillTone.accent : PzPillTone.grey,
                ),
                if (pending > 0)
                  PzPill('$pending 条待同步', tone: PzPillTone.accent),
                if (conflicts > 0)
                  PzPill('$conflicts 条冲突', tone: PzPillTone.win),
                if (retrying.isNotEmpty)
                  PzPill('${retrying.length} 条等待重试', tone: PzPillTone.grey),
                if (pending == 0 &&
                    failures.isEmpty &&
                    retrying.isEmpty &&
                    !offline)
                  const PzPill('已同步', tone: PzPillTone.brand),
              ],
            ),
          ),
        if (pending > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PzHint('分数包含待确认的本地修改；网络恢复后自动同步。'),
          ),
        if (controller.error != null && !offline)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PzNotice(message: controller.error!.message),
          ),
        if (retrying.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PzButton(
                label: '立即重试',
                tone: PzButtonTone.ghost,
                onPressed: controller.busy
                    ? null
                    : () => onRetry(retrying.first),
              ),
            ),
          ),
        for (final entry in failures)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PzNotice(
              title: entry.status == 'conflict' ? '第 N 回合 · 版本冲突' : '修改未提交',
              message: entry.lastError ?? '请检查并重新确认',
            ),
          ),
        for (final entry in failures)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PzButton(
                  label: '查看并重新确认',
                  tone: PzButtonTone.secondary,
                  onPressed: controller.busy ? null : () => onResolve(entry),
                ),
                if (entry.status != 'conflict')
                  PzButton(
                    label: '重试',
                    tone: PzButtonTone.secondary,
                    onPressed: controller.busy ? null : () => onRetry(entry),
                  ),
                PzButton(
                  label: '放弃本地修改',
                  tone: PzButtonTone.ghost,
                  onPressed: controller.busy ? null : () => onDiscard(entry),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
