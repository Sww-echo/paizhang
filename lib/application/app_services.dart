import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_service.dart';
import '../infrastructure/backend/room_sync_coordinator.dart';
import '../infrastructure/backend/supabase_auth_repository.dart';
import '../infrastructure/backend/supabase_room_repository.dart';
import '../infrastructure/backend/supabase_sync.dart';
import '../infrastructure/backend/supabase_sync_queue.dart';
import '../infrastructure/local/app_database.dart';
import '../infrastructure/local/local_room_cache.dart';
import '../infrastructure/local/sync_queue.dart';

class AppServices {
  AppServices._({
    required this.database,
    required this.cache,
    required this.queue,
    this.client,
    this.auth,
    this.rooms,
    this.realtime,
    this.remoteQueue,
  });

  final AppDatabase database;
  final LocalRoomCache cache;
  final SyncQueue queue;
  final SupabaseClient? client;
  final SupabaseAuthService? auth;
  final SupabaseRoomRepository? rooms;
  final SupabaseSync? realtime;
  final SupabaseSyncQueue? remoteQueue;

  bool get isConfigured => client != null;

  static AppServices create({required bool supabaseConfigured}) {
    final database = AppDatabase();
    final cache = LocalRoomCache(database);
    final queue = SyncQueue(database);
    if (!supabaseConfigured) {
      return AppServices._(database: database, cache: cache, queue: queue);
    }

    final client = Supabase.instance.client;
    final rooms = SupabaseRoomRepository(client);
    final realtime = SupabaseSync(client);
    return AppServices._(
      database: database,
      cache: cache,
      queue: queue,
      client: client,
      auth: SupabaseAuthService(
        authRepository: SupabaseAuthRepository(client),
        roomRepository: rooms,
      ),
      rooms: rooms,
      realtime: realtime,
      remoteQueue: SupabaseSyncQueue(queue: queue, repository: rooms),
    );
  }

  RoomSyncCoordinator createRoomSyncCoordinator({
    required Future<void> Function() onRefresh,
  }) {
    final repository = rooms;
    final realtimeClient = realtime;
    if (repository == null || realtimeClient == null) {
      throw StateError('Supabase 尚未配置');
    }
    return RoomSyncCoordinator(
      repository: repository,
      realtime: realtimeClient,
      cache: cache,
      onRefresh: onRefresh,
    );
  }

  Future<void> flushSyncQueue() async {
    await remoteQueue?.flush();
  }

  Future<void> dispose() async {
    await realtime?.dispose();
    await database.close();
  }
}
