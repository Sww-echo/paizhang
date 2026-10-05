import 'package:flutter/material.dart';

import '../application/app_services.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import '../infrastructure/local/app_database.dart';
import 'room_page.dart';

class SyncQueuePage extends StatefulWidget {
  const SyncQueuePage({required this.services, super.key});
  final AppServices services;
  @override
  State<SyncQueuePage> createState() => _SyncQueuePageState();
}

class _SyncQueuePageState extends State<SyncQueuePage> {
  late final String? _actorId = widget.services.currentUser?.id;
  late final Stream<List<SyncQueueEntry>> _operations = _actorId == null
      ? Stream.value(const [])
      : widget.services.database.watchOperations(_actorId);
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || widget.services.currentUser?.id != _actorId) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRoom(SyncQueueEntry entry) => _run(() async {
    final room = await widget.services.rooms!.getRoom(entry.roomId);
    if (!mounted || widget.services.currentUser?.id != _actorId) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ConnectedRoomPage(services: widget.services, room: room),
      ),
    );
  });

  Future<void> _discard(SyncQueueEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃本地修改？'),
        content: const Text('此操作及依赖它的本地修改会被放弃。服务器已经保存的内容不会被撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _run(() => widget.services.queue.discard(entry.operationId));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('同步记录')),
    body: StreamBuilder<List<SyncQueueEntry>>(
      stream: _operations,
      builder: (context, snapshot) {
        if (widget.services.currentUser?.id != _actorId) {
          return const Center(child: Text('账号已切换'));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('本地同步记录暂不可用，请稍后重试'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data!;
        if (entries.isEmpty) return const Center(child: Text('所有本地修改均已处理'));
        final unresolved = entries.map((entry) => entry.operationId).toSet();
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final dependent =
                entry.dependsOn != null && unresolved.contains(entry.dependsOn);
            final label = switch (entry.status) {
              'conflict' => '版本冲突',
              'rejected' => '未提交',
              'retrying' => '等待重试',
              _ => '待同步',
            };
            final action = switch (entry.operation) {
              'delete' => '撤销',
              'update' => '修改',
              _ => '录入',
            };
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$action回合 · $label',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(entry.lastError ?? '网络恢复后自动提交'),
                    if (dependent) const Text('请先处理本回合前一条修改'),
                    if (!dependent)
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: _busy ? null : () => _openRoom(entry),
                            child: const Text('打开房间处理'),
                          ),
                          if (entry.status != 'conflict')
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                      await widget.services.queue.retry(
                                        entry.operationId,
                                      );
                                      await widget.services.flushSyncQueue();
                                    }),
                              child: const Text('重试'),
                            ),
                          TextButton(
                            onPressed: _busy ? null : () => _discard(entry),
                            child: const Text('放弃本地修改'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
