import 'dart:convert';

import 'app_database.dart';

class SyncQueue {
  SyncQueue(this.database);

  final AppDatabase database;
  Future<void>? _flushFuture;

  Future<void> enqueue({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) {
    return database.enqueueOperation(
      SyncQueueEntriesCompanion.insert(
        operationId: operationId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payloadJson: jsonEncode(payload),
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> flush(Future<void> Function(SyncQueueEntry entry) push) async {
    final activeFlush = _flushFuture;
    if (activeFlush != null) {
      await activeFlush;
      return;
    }

    final currentFlush = _flushPending(push);
    _flushFuture = currentFlush;
    try {
      await currentFlush;
    } finally {
      if (identical(_flushFuture, currentFlush)) {
        _flushFuture = null;
      }
    }
  }

  Future<void> _flushPending(
    Future<void> Function(SyncQueueEntry entry) push,
  ) async {
    final entries = await database.pendingOperations();
    for (final entry in entries) {
      try {
        await push(entry);
        await database.markOperationSynced(
          entry.operationId,
          DateTime.now().toUtc(),
        );
      } catch (error) {
        await database.markOperationFailed(
          operationId: entry.operationId,
          error: error.toString(),
        );
        break;
      }
    }
  }
}
