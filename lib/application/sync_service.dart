import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/repositories.dart';
import '../infrastructure/backend/supabase_sync_queue.dart';
import '../infrastructure/local/app_database.dart';
import '../infrastructure/local/sync_queue.dart';

class SyncService with WidgetsBindingObserver {
  SyncService({required this.queue, required this.remote,
    required this.connection, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final SyncQueue queue;
  final SupabaseSyncQueue remote;
  final ConnectionMonitor connection;
  final DateTime Function() _clock;
  StreamSubscription<bool>? _networkSubscription;
  StreamSubscription<List<SyncQueueEntry>>? _operationSubscription;
  List<SyncQueueEntry> _entries = const [];
  Timer? _timer;
  bool _online = true;
  bool _disposed = false;
  bool _started = false;
  DateTime? _serviceRetryAt;
  bool _requested = false;
  Future<void>? _running;
  int? _runningGeneration;
  int _generation = 0;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _networkSubscription = connection.changes.listen((online) {
      _online = online;
      if (online) unawaited(flush());
    }, onError: (Object error) {});
    unawaited(_checkConnection());
    unawaited(activateSession());
  }

  Future<void> _checkConnection() async {
    try {
      _online = await connection.isOnline;
    } catch (_) {
      // Connectivity is advisory; an HTTP request remains the final check.
      _online = true;
    }
    if (!_disposed && _online) await flush();
  }

  Future<void> activateSession() async {
    if (!_started || _disposed) return;
    final generation = ++_generation;
    _timer?.cancel();
    _entries = const [];
    await _operationSubscription?.cancel();
    if (_disposed || generation != _generation) return;
    final actor = queue.currentActorId();
    if (actor == null) return;
    _operationSubscription = queue.database.watchOperations(actor).listen((entries) {
      if (_disposed || generation != _generation) return;
      _entries = entries;
      _schedule();
    });
    await flush();
  }

  Future<void> flush() async {
    if (_disposed || !_online || queue.currentActorId() == null) return;
    _requested = true;
    final running = _running;
    if (running != null) {
      final runningGeneration = _runningGeneration;
      await running;
      if (!_disposed && runningGeneration != _generation) {
        await flush();
      }
      return;
    }
    final run = _flush();
    _running = run;
    _runningGeneration = _generation;
    try {
      await run;
    } finally {
      if (identical(_running, run)) {
        _running = null;
        _runningGeneration = null;
      }
      _schedule();
    }
  }

  Future<void> _flush() async {
    do {
      _requested = false;
      try {
        await remote.flush();
        _serviceRetryAt = null;
      } catch (_) {
        // A storage failure must not create a zero-delay retry loop.
        _serviceRetryAt = _clock().add(const Duration(seconds: 10));
        return;
      }
    } while (_requested && !_disposed && _online);
  }

  void _schedule() {
    _timer?.cancel();
    if (_disposed || !_online || queue.currentActorId() == null) return;
    final unresolved = _entries.map((entry) => entry.operationId).toSet();
    DateTime? earliest;
    for (final entry in _entries) {
      if (!['pending', 'retrying'].contains(entry.status)) continue;
      if (entry.dependsOn != null && unresolved.contains(entry.dependsOn)) continue;
      final next = entry.nextAttemptAt ?? _clock();
      if (earliest == null || next.isBefore(earliest)) earliest = next;
    }
    if (earliest == null) return;
    if (_serviceRetryAt != null && earliest.isBefore(_serviceRetryAt!)) {
      earliest = _serviceRetryAt;
    }
    final delay = earliest!.difference(_clock());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (_running != null) {
        _requested = true;
      } else {
        unawaited(flush());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_checkConnection());
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    await _networkSubscription?.cancel();
    await _operationSubscription?.cancel();
    await connection.dispose();
  }
}
