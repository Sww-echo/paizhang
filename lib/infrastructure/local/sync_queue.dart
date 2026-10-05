import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/app_error.dart';
import '../../domain/models.dart';
import '../../domain/room_snapshot.dart';
import '../backend/app_error_mapper.dart';
import 'app_database.dart';

class SyncQueue {
  SyncQueue(this.database, {
    required this.currentActorId,
    DateTime Function()? clock,
    this.retryBase = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now;

  final AppDatabase database;
  final String? Function() currentActorId;
  final DateTime Function() _clock;
  final Duration retryBase;
  Future<void>? _flushFuture;
  int? _flushGeneration;
  String? _activeOperationId;
  int _generation = 0;

  void invalidateSession() => _generation++;
  int get generation => _generation;

  String _requireActor() {
    final actor = currentActorId();
    if (actor == null || actor.isEmpty) {
      throw const AppError(AppErrorKind.unauthenticated, '请先登录');
    }
    return actor;
  }

  Future<void> enqueue({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    String roomId = '',
    int? baseVersion,
    String? dependsOn,
  }) => database.enqueueOperation(SyncQueueEntriesCompanion.insert(
    operationId: operationId,
    actorId: Value(_requireActor()),
    roomId: Value(roomId),
    entityType: entityType,
    entityId: entityId,
    operation: operation,
    payloadJson: jsonEncode(payload),
    createdAt: _clock().toUtc(),
    baseVersion: Value(baseVersion),
    dependsOn: Value(dependsOn),
  ));

  Future<void> enqueueRound({
    required String operationId,
    required String roomId,
    required String operation,
    required Round round,
    int? baseVersion,
    String? expectedActorId,
    int? expectedGeneration,
  }) async {
    final actor = _requireActor();
    final epoch = _generation;
    if ((expectedActorId != null && expectedActorId != actor) ||
        (expectedGeneration != null && expectedGeneration != epoch)) {
      throw const AppError(AppErrorKind.sessionChanged, '账号已切换，请重新操作');
    }
    await database.transaction(() async {
      final preceding = await (database.select(database.syncQueueEntries)
            ..where((row) => row.actorId.equals(actor) & row.entityId.equals(round.id) &
                row.status.isIn(['pending', 'retrying', 'conflict', 'rejected']))
            ..orderBy([(row) => OrderingTerm.desc(row.sequence)])
            ..limit(1))
          .getSingleOrNull();
      if (preceding != null && ['conflict', 'rejected'].contains(preceding.status)) {
        throw const AppError(AppErrorKind.conflict, '请先处理这条回合已有的同步失败');
      }
      if (!isCurrent(actor, epoch)) {
        throw const AppError(AppErrorKind.sessionChanged, '账号已切换，请重新操作');
      }
      await enqueue(operationId: operationId, entityType: 'round', entityId: round.id,
          operation: operation, payload: {'round': roundToJson(round)}, roomId: roomId,
          baseVersion: baseVersion, dependsOn: preceding?.operationId);
    });
  }

  bool isCurrent(String actor, int epoch) =>
      currentActorId() == actor && _generation == epoch;

  Future<void> flush(Future<void> Function(SyncQueueEntry entry) push) async {
    final active = _flushFuture;
    if (active != null) {
      final activeGeneration = _flushGeneration;
      await active;
      if (activeGeneration != _generation && currentActorId() != null) {
        await flush(push);
      }
      return;
    }
    final actor = currentActorId();
    if (actor == null || actor.isEmpty) return;
    final run = _flushPending(actor, _generation, push);
    _flushFuture = run;
    _flushGeneration = _generation;
    try {
      await run;
    } finally {
      if (identical(_flushFuture, run)) {
        _flushFuture = null;
        _flushGeneration = null;
      }
    }
  }

  Future<void> _flushPending(String actor, int epoch,
      Future<void> Function(SyncQueueEntry entry) push) async {
    while (isCurrent(actor, epoch)) {
      final entries = await database.pendingOperations(actorId: actor);
      var progressed = false;
      for (final queued in entries) {
        if (!isCurrent(actor, epoch)) return;
        final entry = await database.operation(actor, queued.operationId);
        if (entry == null || !['pending', 'retrying'].contains(entry.status)) continue;
        if (entry.nextAttemptAt?.isAfter(_clock()) ?? false) continue;
        if (entry.dependsOn != null) {
          final parent = await database.operation(actor, entry.dependsOn!);
          if (parent?.status != 'synced') continue;
        }
        if (!isCurrent(actor, epoch)) return;
        _activeOperationId = entry.operationId;
        try {
          await push(entry);
          if (!isCurrent(actor, epoch)) return;
          final current = await database.operation(actor, entry.operationId);
          if (current?.status != 'synced') {
            await database.markOperationSynced(actor, entry.operationId, _clock().toUtc());
          }
          progressed = true;
        } catch (error) {
          if (!isCurrent(actor, epoch)) return;
          final failure = mapAppError(error);
          if (failure.kind == AppErrorKind.sessionChanged) return;
          final retryable = failure.isRetryable || failure.kind == AppErrorKind.unauthenticated;
          final delay = min(300000, retryBase.inMilliseconds * (1 << min(entry.attemptCount, 8)));
          await database.updateOperation(actor, entry.operationId, SyncQueueEntriesCompanion(
            attemptCount: Value(entry.attemptCount + 1),
            status: Value(retryable ? 'retrying' :
                failure.kind == AppErrorKind.conflict ? 'conflict' : 'rejected'),
            lastError: Value(failure.message),
            nextAttemptAt: Value(retryable ? _clock().toUtc().add(Duration(milliseconds: delay)) : null),
          ));
          if (retryable) return;
          await _blockDependents(actor, entry.operationId);
          progressed = true;
        } finally {
          _activeOperationId = null;
        }
      }
      if (!progressed) return;
    }
  }

  Future<void> _blockDependents(String actor, String operationId) async {
    final descendants = await dependentOperations(actor, operationId);
    for (final entry in descendants) {
      await database.updateOperation(actor, entry.operationId, const SyncQueueEntriesCompanion(
        status: Value('rejected'), lastError: Value('前一条修改未提交，请先处理依赖记录'),
      ));
    }
  }

  Future<List<SyncQueueEntry>> dependentOperations(String actor, String operationId) async {
    final result = <SyncQueueEntry>[];
    var parents = [operationId];
    while (parents.isNotEmpty) {
      final children = await (database.select(database.syncQueueEntries)..where((row) =>
          row.actorId.equals(actor) & row.dependsOn.isIn(parents) &
          row.status.isIn(['pending', 'retrying', 'conflict', 'rejected'])))
          .get();
      result.addAll(children);
      parents = children.map((entry) => entry.operationId).toList();
    }
    result.sort((a, b) => a.sequence.compareTo(b.sequence));
    return result;
  }

  Future<void> retry(String operationId) async {
    final actor = _requireActor();
    final entry = await database.operation(actor, operationId);
    if (entry == null || entry.status == 'synced' || entry.status == 'discarded') return;
    if (entry.status == 'conflict') {
      throw const AppError(AppErrorKind.conflict, '请先查看最新记录并重新确认，不能直接覆盖冲突');
    }
    await database.transaction(() async {
      final values = [entry, ...await dependentOperations(actor, operationId)];
      for (final value in values) {
        await database.updateOperation(actor, value.operationId, const SyncQueueEntriesCompanion(
          status: Value('pending'), nextAttemptAt: Value(null), lastError: Value(null),
        ));
      }
    });
  }

  Future<void> discard(String operationId) async {
    final actor = _requireActor();
    final entry = await database.operation(actor, operationId);
    if (entry == null || entry.status == 'synced') return;
    final values = [entry, ...await dependentOperations(actor, operationId)];
    if (values.any((value) => value.operationId == _activeOperationId)) {
      throw const AppError(AppErrorKind.validation, '记录正在同步，请稍后处理');
    }
    await database.transaction(() async {
      for (final value in values) {
        await database.updateOperation(actor, value.operationId,
            const SyncQueueEntriesCompanion(status: Value('discarded')));
      }
    });
  }

  RoundMutation mutationFromEntry(SyncQueueEntry entry) {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    return RoundMutation(operationId: entry.operationId, actorId: entry.actorId,
        roomId: entry.roomId, operation: entry.operation,
        round: roundFromJson(payload['round'] as Map<String, dynamic>),
        expectedVersion: entry.baseVersion);
  }
}
