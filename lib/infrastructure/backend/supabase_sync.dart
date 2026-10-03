import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class RemoteChange {
  const RemoteChange({
    required this.table,
    required this.eventType,
    required this.payload,
  });

  final String table;
  final PostgresChangeEvent eventType;
  final Map<String, dynamic> payload;
}

class SupabaseSync {
  SupabaseSync(this.client);

  final SupabaseClient client;
  final StreamController<RemoteChange> _changes = StreamController.broadcast();
  RealtimeChannel? _channel;

  Stream<RemoteChange> get changes => _changes.stream;

  Future<void> subscribeToRoom(String roomId) async {
    final previousChannel = _channel;
    _channel = null;
    await previousChannel?.unsubscribe();
    _channel = client
        .channel('room:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) => _emit('rooms', payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) => _emit('room_members', payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'game_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) => _emit('game_sessions', payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rounds',
          callback: (payload) => _emit('rounds', payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'score_changes',
          callback: (payload) => _emit('score_changes', payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_close_proposals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) => _emit('room_close_proposals', payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_close_votes',
          callback: (payload) => _emit('room_close_votes', payload),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) => _emit('profiles', payload),
        )
        .subscribe();
  }

  Future<void> dispose() async {
    await unsubscribe();
    await _changes.close();
  }

  Future<void> unsubscribe() async {
    final channel = _channel;
    _channel = null;
    await channel?.unsubscribe();
  }

  void _emit(String table, PostgresChangePayload payload) {
    if (_changes.isClosed) return;
    _changes.add(
      RemoteChange(
        table: table,
        eventType: payload.eventType,
        payload: {'new': payload.newRecord, 'old': payload.oldRecord},
      ),
    );
  }
}
