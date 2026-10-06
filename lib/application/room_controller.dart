import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/app_error.dart';
import '../domain/models.dart';
import '../domain/operation_id.dart';
import '../domain/repositories.dart';
import '../domain/room_snapshot.dart';
import '../domain/settlement_calculator.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import '../infrastructure/backend/room_sync_coordinator.dart';
import '../infrastructure/local/app_database.dart';
import '../infrastructure/local/local_room_cache.dart';
import '../infrastructure/local/sync_queue.dart';

class ReapplyDraft {
  const ReapplyDraft({
    required this.entry,
    required this.desired,
    this.current,
  });
  final SyncQueueEntry entry;
  final Round desired;
  final Round? current;
}

class RoomController extends ChangeNotifier {
  RoomController({
    required this.roomId,
    required this.actorId,
    required this.repository,
    required this.cache,
    required this.queue,
    required RoomEvents events,
    required this.requestSync,
    DateTime Function()? clock,
    String Function()? idFactory,
  }) : _clock = clock ?? DateTime.now,
       _idFactory = idFactory ?? newOperationId,
       _sessionGeneration = queue.generation {
    _sync = RoomSyncCoordinator(
      repository: repository,
      realtime: events,
      cache: cache,
      isCurrent: () => isCurrent,
      onRefresh: (_) async {
        if (!isCurrent) return;
        error = null;
        loading = false;
        await _loadLocal();
      },
      onError: (failure) async {
        if (!isCurrent) return;
        error = mapAppError(failure);
        if (error!.isAccessError) _setSnapshot(null);
        loading = false;
        notifyListeners();
      },
    );
  }

  final String roomId;
  final String actorId;
  final RoomRepository repository;
  final LocalRoomCache cache;
  final SyncQueue queue;
  final Future<void> Function() requestSync;
  final DateTime Function() _clock;
  final String Function() _idFactory;
  final int _sessionGeneration;
  late final RoomSyncCoordinator _sync;
  StreamSubscription<RoomSnapshot?>? _cacheSubscription;
  StreamSubscription<List<SyncQueueEntry>>? _operationSubscription;
  RoomSnapshot? snapshot;
  AppError? error;
  List<SyncQueueEntry> operations = const [];
  Map<String, List<Round>> roundsBySession = const {};
  Map<String, Map<String, int>> totalsBySession = const {};
  String? selectedSessionId;
  bool loading = true;
  bool refreshing = false;
  bool busy = false;
  bool _disposed = false;

  bool get isCurrent =>
      !_disposed && queue.isCurrent(actorId, _sessionGeneration);
  bool get canManage =>
      snapshot != null &&
      !snapshot!.room.isClosed &&
      snapshot!.room.ownerId == actorId &&
      snapshot!.room.hasActiveMember(actorId) &&
      error?.isAccessError != true;
  bool get canInput =>
      snapshot != null &&
      !snapshot!.room.isClosed &&
      snapshot!.room.hasActiveMember(actorId) &&
      error?.isAccessError != true &&
      (snapshot!.room.inputPermission == InputPermission.all || canManage);
  int get pendingCount => operations
      .where((entry) => entry.status == 'pending' || entry.status == 'retrying')
      .length;
  List<SyncQueueEntry> get failures {
    final unresolved = operations.map((entry) => entry.operationId).toSet();
    return operations
        .where(
          (entry) =>
              (entry.status == 'rejected' || entry.status == 'conflict') &&
              (entry.dependsOn == null ||
                  !unresolved.contains(entry.dependsOn)),
        )
        .toList();
  }

  bool canEdit(Round round) =>
      canInput &&
      round.createdBy == actorId &&
      snapshot!.sessions.any(
        (session) =>
            session.id == round.sessionId &&
            session.status == GameSessionStatus.active,
      );

  Future<void> start() async {
    if (!isCurrent) return;
    _cacheSubscription = cache
        .watchRoomSnapshot(roomId)
        .listen(
          (value) {
            if (!isCurrent) return;
            _setSnapshot(value);
            if (value != null) loading = false;
            notifyListeners();
          },
          onError: (Object failure) {
            if (!isCurrent) return;
            error = mapAppError(failure);
            loading = false;
            notifyListeners();
          },
        );
    _operationSubscription = queue.database
        .watchOperations(actorId, roomId: roomId)
        .listen((entries) {
          if (!isCurrent) return;
          operations = entries;
          notifyListeners();
        });
    try {
      await _loadLocal();
    } catch (failure) {
      error = mapAppError(failure);
    }
    if (isCurrent) await _sync.start(roomId);
  }

  void _setSnapshot(RoomSnapshot? value) {
    snapshot = value;
    final grouped = <String, List<Round>>{};
    for (final round in value?.rounds ?? const <Round>[]) {
      grouped.putIfAbsent(round.sessionId, () => []).add(round);
    }
    roundsBySession = Map.unmodifiable(grouped);
    totalsBySession = {
      for (final entry in grouped.entries)
        entry.key: const SettlementCalculator()
            .calculate(entry.value, value!.room.scoringMode)
            .totals,
    };
  }

  Future<void> _loadLocal() async {
    final value = await cache.loadRoomSnapshot(roomId);
    if (!isCurrent) return;
    _setSnapshot(value);
    if (value != null) loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!isCurrent) return;
    refreshing = true;
    notifyListeners();
    try {
      await _sync.refresh();
    } finally {
      if (isCurrent) {
        refreshing = false;
        notifyListeners();
      }
    }
  }

  Future<void> runAction(Future<void> Function() action) async {
    if (!isCurrent || busy) return;
    busy = true;
    notifyListeners();
    try {
      await action();
    } catch (failure) {
      throw mapAppError(failure);
    } finally {
      if (isCurrent) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void _validate(
    String sessionId,
    List<ScoreChange> changes, {
    Round? previous,
  }) {
    if (!isCurrent) throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    if (!canInput) throw const AppError(AppErrorKind.forbidden, '当前房间不允许录入');
    if (!snapshot!.sessions.any(
      (s) => s.id == sessionId && s.status == GameSessionStatus.active,
    )) {
      throw const AppError(AppErrorKind.validation, '当前牌局不允许写入');
    }
    if (previous != null && previous.createdBy != actorId) {
      throw const AppError(AppErrorKind.forbidden, '只有回合创建者可以修改记录');
    }
    if (changes.isEmpty || changes.every((change) => change.value == 0)) {
      throw const AppError(AppErrorKind.validation, '至少填写一项非零分数');
    }
    if (changes.map((c) => c.playerId).toSet().length != changes.length) {
      throw const AppError(AppErrorKind.validation, '同一成员不能重复录入');
    }
    for (final change in changes) {
      if (!snapshot!.room.hasActiveMember(change.playerId) &&
          !(previous?.changes.any((old) => old.playerId == change.playerId) ??
              false)) {
        throw const AppError(AppErrorKind.validation, '只能为有效房间成员录入新分数');
      }
    }
    if (snapshot!.room.scoringMode == ScoringMode.money &&
        changes.fold<int>(0, (sum, change) => sum + change.value) != 0) {
      throw const AppError(AppErrorKind.validation, '金额模式每局必须平账');
    }
  }

  Future<void> recordRound(
    String sessionId,
    List<ScoreChange> changes, {
    String? note,
  }) async {
    _validate(sessionId, changes);
    final rounds = roundsBySession[sessionId] ?? const <Round>[];
    final number =
        rounds.fold<int>(
          0,
          (max, round) => round.number > max ? round.number : max,
        ) +
        1;
    await _enqueue(
      'create',
      Round(
        id: _idFactory(),
        sessionId: sessionId,
        number: number,
        changes: List.unmodifiable(changes),
        createdBy: actorId,
        createdAt: _clock(),
        note: note,
      ),
    );
  }

  String? inputDisabledReason(String? sessionId) {
    if (!isCurrent) return '账号已切换，请重新进入房间';
    final value = snapshot;
    if (value == null) {
      // Access errors carry the server's reason (removed, no longer a
      // member); without one the cached view is simply unconfirmed.
      return error?.isAccessError == true ? error!.message : '房间访问尚未确认，请刷新后再试';
    }
    if (value.room.isClosed) return '房间已关闭，当前仅可查看记录';
    if (!value.room.hasActiveMember(actorId)) return '你已不再是房间成员';
    if (error?.isAccessError == true) return '房间访问尚未确认，请刷新后再试';
    if (!canInput) return '当前仅房主可以录入分数';
    if (!value.sessions.any(
      (s) => s.id == sessionId && s.status == GameSessionStatus.active,
    )) {
      return '暂无进行中的牌局，请先开始一场';
    }
    if (busy) return '正在提交，请稍候';
    return null;
  }

  Future<void> transferScores(
    String sessionId,
    Map<String, int> amountsByRecipient,
  ) async {
    if (amountsByRecipient.isEmpty) {
      throw const AppError(AppErrorKind.validation, '请至少选择一位接收人');
    }
    var total = 0;
    final changes = <ScoreChange>[];
    for (final entry in amountsByRecipient.entries) {
      if (entry.key == actorId) {
        throw const AppError(AppErrorKind.validation, '不能给自己转分');
      }
      if (entry.value <= 0 || entry.value > 2147483647) {
        throw const AppError(AppErrorKind.validation, '每项分值必须为有效的正整数');
      }
      total += entry.value;
      if (total > 2147483647) {
        throw const AppError(AppErrorKind.validation, '本次转出总额超出允许范围');
      }
      changes.add(ScoreChange(playerId: entry.key, value: entry.value));
    }
    await recordRound(sessionId, [
      ScoreChange(playerId: actorId, value: -total),
      ...changes,
    ], note: amountsByRecipient.length == 1 ? '分数转换' : '多人转分');
  }

  Future<void> updateRound(
    Round previous,
    List<ScoreChange> changes, {
    String? note,
  }) async {
    _validate(previous.sessionId, changes, previous: previous);
    await _enqueue(
      'update',
      previous.copyWith(
        changes: changes,
        note: note,
        clearNote: note == null,
        clearDeletedAt: true,
        version: previous.version + 1,
      ),
      baseVersion: previous.version,
    );
  }

  Future<void> deleteRound(Round previous) async {
    _validate(previous.sessionId, previous.changes, previous: previous);
    await _enqueue(
      'delete',
      previous.copyWith(deletedAt: _clock(), version: previous.version + 1),
      baseVersion: previous.version,
    );
  }

  Future<void> _enqueue(
    String operation,
    Round round, {
    int? baseVersion,
  }) async {
    if (round.note != null && round.note!.length > 120) {
      throw const AppError(AppErrorKind.validation, '备注不能超过 120 个字符');
    }
    await queue.enqueueRound(
      operationId: _idFactory(),
      roomId: roomId,
      operation: operation,
      round: round,
      baseVersion: baseVersion,
      expectedActorId: actorId,
      expectedGeneration: _sessionGeneration,
    );
    await _loadLocal();
    unawaited(requestSync());
  }

  Future<ReapplyDraft> prepareReapply(SyncQueueEntry entry) async {
    final dependents = await queue.dependentOperations(
      actorId,
      entry.operationId,
    );
    final last = dependents.isEmpty ? entry : dependents.last;
    final desired = queue.mutationFromEntry(last).round;
    await refresh();
    if (!isCurrent) throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    if (error != null) throw error!;
    final fresh = await cache.loadRoomSnapshot(roomId, includePending: false);
    if (!isCurrent) throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    if (fresh == null) {
      throw const AppError(AppErrorKind.notFound, '房间不存在或已无法访问');
    }
    Round? current;
    for (final round in fresh.rounds) {
      if (round.id == desired.id) current = round;
    }
    if (current == null && entry.operation != 'create') {
      throw const AppError(AppErrorKind.notFound, '服务器已没有这条回合，不能重新覆盖');
    }
    return ReapplyDraft(entry: entry, desired: desired, current: current);
  }

  Future<void> applyRebased(ReapplyDraft draft) async {
    final current = draft.current;
    _validate(
      draft.desired.sessionId,
      draft.desired.changes,
      previous: current,
    );
    await queue.database.transaction(() async {
      await queue.discard(draft.entry.operationId);
      final operation = current == null
          ? 'create'
          : draft.desired.isDeleted
          ? 'delete'
          : 'update';
      await queue.enqueueRound(
        operationId: _idFactory(),
        roomId: roomId,
        operation: operation,
        round: draft.desired.copyWith(
          version: current == null ? 1 : current.version + 1,
        ),
        baseVersion: current?.version,
        expectedActorId: actorId,
        expectedGeneration: _sessionGeneration,
      );
    });
    await _loadLocal();
    unawaited(requestSync());
  }

  Future<void> retry(SyncQueueEntry entry) async {
    await queue.retry(entry.operationId);
    await requestSync();
  }

  Future<void> discard(SyncQueueEntry entry) async {
    if (!isCurrent) throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    await queue.discard(entry.operationId);
    await _loadLocal();
    await refresh();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_cacheSubscription?.cancel());
    unawaited(_operationSubscription?.cancel());
    unawaited(_sync.dispose());
    super.dispose();
  }
}
