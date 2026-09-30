import 'dart:async';

import 'supabase_room_repository.dart';
import 'supabase_sync.dart';
import '../local/local_room_cache.dart';

class RoomSyncCoordinator {
  RoomSyncCoordinator({
    required this.repository,
    required this.realtime,
    required this.cache,
  });

  final SupabaseRoomRepository repository;
  final SupabaseSync realtime;
  final LocalRoomCache cache;

  StreamSubscription<RemoteChange>? _subscription;
  String? _roomId;
  bool _refreshing = false;
  bool _refreshQueued = false;

  Future<void> start(String roomId) async {
    await stop();
    _roomId = roomId;
    _subscription = realtime.changes.listen((change) {
      if (_isRelevantChange(change)) {
        unawaited(_refreshAfterChange());
      }
    });
    realtime.subscribeToRoom(roomId);
    await refresh();
  }

  Future<void> refresh() async {
    final roomId = _roomId;
    if (roomId == null) return;
    final snapshot = await repository.getRoomSnapshot(roomId);
    await cache.saveRoomSnapshot(
      room: snapshot.room,
      sessions: snapshot.sessions,
      rounds: snapshot.rounds,
    );
  }

  Future<void> stop() async {
    _roomId = null;
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
    } finally {
      _refreshing = false;
    }
  }

  bool _isRelevantChange(RemoteChange change) {
    return switch (change.table) {
      'rooms' ||
      'room_members' ||
      'game_sessions' ||
      'rounds' ||
      'score_changes' => true,
      _ => false,
    };
  }
}
