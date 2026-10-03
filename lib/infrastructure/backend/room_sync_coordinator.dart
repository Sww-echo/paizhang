import 'dart:async';

import 'supabase_room_repository.dart';
import 'supabase_sync.dart';
import '../local/local_room_cache.dart';

class RoomSyncCoordinator {
  RoomSyncCoordinator({
    required this.repository,
    required this.realtime,
    required this.cache,
    this.onRefresh,
    this.onError,
  });

  final SupabaseRoomRepository repository;
  final SupabaseSync realtime;
  final LocalRoomCache cache;
  final Future<void> Function(RemoteRoomSnapshot snapshot)? onRefresh;
  final Future<void> Function(Object error)? onError;

  StreamSubscription<RemoteChange>? _subscription;
  Timer? _refreshTimer;
  RemoteRoomSnapshot? _snapshot;
  String? _roomId;
  bool _refreshing = false;
  bool _refreshQueued = false;
  int _generation = 0;

  Future<void> start(String roomId) async {
    await stop();
    final generation = ++_generation;
    _roomId = roomId;
    _subscription = realtime.changes.listen((change) {
      if (_isRelevantChange(change)) {
        _scheduleRefresh();
      }
    });
    await realtime.subscribeToRoom(roomId);
    await refresh(generation: generation);
  }

  Future<void> refresh({int? generation}) async {
    final roomId = _roomId;
    if (roomId == null) return;
    final snapshot = await repository.getRoomSnapshot(roomId);
    if (generation != null && generation != _generation) return;
    if (_roomId != roomId) return;
    _snapshot = snapshot;
    await cache.saveRoomSnapshot(
      room: snapshot.room,
      sessions: snapshot.sessions,
      rounds: snapshot.rounds,
    );
    await onRefresh?.call(snapshot);
  }

  Future<void> stop() async {
    _generation++;
    _roomId = null;
    _snapshot = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _refreshQueued = false;
    await _subscription?.cancel();
    _subscription = null;
    await realtime.unsubscribe();
  }

  Future<void> _refreshAfterChange() async {
    if (_refreshing) {
      _refreshQueued = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        await refresh();
      } while (_refreshQueued);
    } catch (error) {
      await onError?.call(error);
    } finally {
      _refreshing = false;
    }
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 120), () {
      _refreshTimer = null;
      unawaited(_refreshAfterChange());
    });
  }

  bool _isRelevantChange(RemoteChange change) {
    final snapshot = _snapshot;
    if (snapshot == null) return true;
    final closeVoteProposalId = snapshot.closeVote?.proposalId;

    bool matchesRecord(String key, Iterable<String> ids) {
      final idSet = ids.toSet();
      final records = [change.payload['new'], change.payload['old']];
      return records.any(
        (record) =>
            record is Map<String, dynamic> && idSet.contains(record[key]),
      );
    }

    return switch (change.table) {
      'rooms' => matchesRecord('id', [snapshot.room.id]),
      'room_members' || 'game_sessions' => true,
      'rounds' => matchesRecord(
        'session_id',
        snapshot.sessions.map((session) => session.id),
      ),
      'score_changes' => matchesRecord(
        'round_id',
        snapshot.rounds.map((round) => round.id),
      ),
      'room_close_proposals' => matchesRecord('room_id', [snapshot.room.id]),
      'room_close_votes' =>
        closeVoteProposalId == null ||
            matchesRecord('proposal_id', [closeVoteProposalId]),
      'profiles' => matchesRecord('id', snapshot.profiles.keys),
      _ => false,
    };
  }
}
