import 'dart:async';

import '../../domain/app_error.dart';
import '../../domain/repositories.dart';
import '../../domain/room_snapshot.dart';
import '../local/local_room_cache.dart';
import 'app_error_mapper.dart';

class RoomSyncCoordinator {
  RoomSyncCoordinator({required this.repository, required this.realtime,
    required this.cache, required this.isCurrent, this.onRefresh, this.onError});

  final RoomRepository repository;
  final RoomEvents realtime;
  final LocalRoomCache cache;
  final bool Function() isCurrent;
  final Future<void> Function(RoomSnapshot snapshot)? onRefresh;
  final Future<void> Function(Object error)? onError;
  StreamSubscription<RoomChange>? _subscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _refreshTimer;
  RoomSnapshot? _snapshot;
  String? _roomId;
  Future<void>? _refreshFuture;
  bool _refreshQueued = false;
  bool _starting = false;
  int _generation = 0;

  Future<void> start(String roomId) async {
    await stop();
    final generation = ++_generation;
    _roomId = roomId;
    _starting = true;
    _subscription = realtime.changes.listen((change) {
      if (_isRelevantChange(change)) _scheduleRefresh();
    });
    _connectionSubscription = realtime.connectionChanges.listen((connected) {
      if (connected && !_starting) _scheduleRefresh();
    });
    try {
      await realtime.start(roomId);
    } catch (error) {
      await onError?.call(mapAppError(error));
    }
    if (generation != _generation || !isCurrent()) return;
    _starting = false;
    await refresh();
  }

  Future<void> refresh() {
    if (_roomId == null || !isCurrent()) return Future.value();
    final active = _refreshFuture;
    if (active != null) {
      _refreshQueued = true;
      return active;
    }
    final run = _refresh(_roomId!, _generation);
    _refreshFuture = run;
    return run.whenComplete(() {
      if (identical(_refreshFuture, run)) _refreshFuture = null;
    });
  }

  Future<void> _refresh(String roomId, int generation) async {
    do {
      _refreshQueued = false;
      try {
        final snapshot = await repository.getRoomSnapshot(roomId);
        if (generation != _generation || !isCurrent()) return;
        if (!snapshot.room.hasActiveMember(cache.actorId)) {
          throw const AppError(AppErrorKind.forbidden, '你已不再是房间成员，请从历史记录查看');
        }
        _snapshot = snapshot;
        await cache.saveRoomSnapshot(room: snapshot.room, sessions: snapshot.sessions,
            rounds: snapshot.rounds, profiles: snapshot.profiles, closeVote: snapshot.closeVote);
        if (generation != _generation || !isCurrent()) return;
        await onRefresh?.call(snapshot);
      } catch (error) {
        if (generation != _generation || !isCurrent()) return;
        final failure = mapAppError(error);
        if (failure.isAccessError) await cache.invalidateRoom(roomId);
        await onError?.call(failure);
      }
    } while (_refreshQueued && generation == _generation && isCurrent());
  }

  Future<void> stop() async {
    _generation++;
    _roomId = null;
    _snapshot = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _refreshQueued = false;
    _refreshFuture = null;
    await _subscription?.cancel();
    await _connectionSubscription?.cancel();
    _subscription = null;
    _connectionSubscription = null;
    await realtime.stop();
  }

  Future<void> dispose() async {
    await stop();
    await realtime.dispose();
  }

  void _scheduleRefresh() {
    if (_starting) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 120), () {
      _refreshTimer = null;
      unawaited(refresh());
    });
  }

  bool _isRelevantChange(RoomChange change) {
    final snapshot = _snapshot;
    if (snapshot == null) return true;
    bool matches(String key, Iterable<String> values) {
      final ids = values.toSet();
      return [change.payload['new'], change.payload['old']].any(
          (row) => row is Map && ids.contains(row[key]));
    }
    return switch (change.table) {
      'rooms' => matches('id', [snapshot.room.id]),
      'room_members' || 'game_sessions' => true,
      'rounds' => matches('session_id', snapshot.sessions.map((s) => s.id)),
      'score_changes' => matches('round_id', snapshot.rounds.map((r) => r.id)),
      'room_close_proposals' => matches('room_id', [snapshot.room.id]),
      'room_close_votes' => snapshot.closeVote?.proposalId == null ||
          matches('proposal_id', [snapshot.closeVote!.proposalId!]),
      'profiles' => matches('id', snapshot.profiles.keys),
      _ => false,
    };
  }
}
