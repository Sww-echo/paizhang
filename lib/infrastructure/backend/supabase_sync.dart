import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories.dart';

class SupabaseSync implements RoomEvents {
  SupabaseSync(this.client);

  final SupabaseClient client;
  final _changes = StreamController<RoomChange>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  RealtimeChannel? _channel;
  int _generation = 0;

  @override
  Stream<RoomChange> get changes => _changes.stream;
  @override
  Stream<bool> get connectionChanges => _connections.stream;

  @override
  Future<void> start(String roomId) async {
    await stop();
    final generation = ++_generation;
    final ready = Completer<void>();
    var channel = client.channel('room:$roomId:${identityHashCode(this)}');
    for (final table in [
      'rooms',
      'room_members',
      'game_sessions',
      'rounds',
      'score_changes',
      'room_close_proposals',
      'room_close_votes',
      'profiles',
    ]) {
      final column = switch (table) {
        'rooms' => 'id',
        'room_members' ||
        'game_sessions' ||
        'room_close_proposals' => 'room_id',
        _ => null,
      };
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: column == null
            ? null
            : PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: column,
                value: roomId,
              ),
        callback: (payload) {
          if (_changes.isClosed || generation != _generation) return;
          _changes.add(
            RoomChange(
              table: table,
              payload: {'new': payload.newRecord, 'old': payload.oldRecord},
            ),
          );
        },
      );
    }
    _channel = channel.subscribe((status, error) {
      if (_connections.isClosed || generation != _generation) return;
      _connections.add(status == RealtimeSubscribeStatus.subscribed);
      if (!ready.isCompleted) ready.complete();
    });
    await ready.future.timeout(const Duration(seconds: 3), onTimeout: () {});
  }

  @override
  Future<void> stop() async {
    _generation++;
    final channel = _channel;
    _channel = null;
    if (channel != null) await client.removeChannel(channel);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _changes.close();
    await _connections.close();
  }
}
