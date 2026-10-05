import 'package:flutter/material.dart';

import '../application/room_controller.dart';
import '../infrastructure/local/app_database.dart';

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
    final failures = controller.failures;
    final pending = controller.pendingCount;
    final retrying = controller.operations.where(
      (entry) => entry.status == 'retrying',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.refreshing) const LinearProgressIndicator(),
        if (controller.error != null || pending > 0 || failures.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pending > 0
                        ? '$pending 条本地修改待同步'
                        : failures.isNotEmpty
                        ? '${failures.length} 项修改需要处理'
                        : '正在使用本地缓存',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (pending > 0) const Text('分数包含待确认的本地修改；网络恢复后自动同步。'),
                  if (controller.error != null) Text(controller.error!.message),
                  if (retrying.isNotEmpty)
                    TextButton.icon(
                      onPressed: controller.busy
                          ? null
                          : () => onRetry(retrying.first),
                      icon: const Icon(Icons.sync),
                      label: const Text('立即重试'),
                    ),
                  for (final entry in failures)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.status == 'conflict' ? '记录版本冲突' : '修改未提交'),
                          Text(entry.lastError ?? '请检查并重新确认'),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: controller.busy
                                    ? null
                                    : () => onResolve(entry),
                                child: const Text('查看并重新确认'),
                              ),
                              if (entry.status != 'conflict')
                                TextButton(
                                  onPressed: controller.busy
                                      ? null
                                      : () => onRetry(entry),
                                  child: const Text('重试'),
                                ),
                              TextButton(
                                onPressed: controller.busy
                                    ? null
                                    : () => onDiscard(entry),
                                child: const Text('放弃本地修改'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
