import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, SupabaseClient;

import '../domain/app_error.dart';
import '../domain/auth_gateway.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import '../infrastructure/backend/connection_monitor.dart';
import '../infrastructure/backend/supabase_auth_repository.dart';
import '../infrastructure/backend/supabase_room_repository.dart';
import '../infrastructure/backend/supabase_sync.dart';
import '../infrastructure/backend/supabase_sync_queue.dart';
import '../infrastructure/local/app_database.dart';
import '../infrastructure/local/local_room_cache.dart';
import '../infrastructure/local/sync_queue.dart';
import 'room_controller.dart';
import 'supabase_auth_service.dart';
import 'sync_service.dart';

class AppServices {
  AppServices({
    required this.database,
    this.client,
    this.auth,
    this.rooms,
    this._eventsFactory,
    ConnectionMonitor? connection,
    User? initialUser,
    bool startSync = true,
  }) {
    session = ValueNotifier(initialUser ?? auth?.currentUser);
    queue = SyncQueue(database, currentActorId: () => currentUser?.id);
    final repository = rooms;
    if (repository != null) {
      remoteQueue = SupabaseSyncQueue(
        queue: queue,
        repository: repository,
        cacheForActor: cacheForActor,
      );
      syncService = SyncService(
        queue: queue,
        remote: remoteQueue!,
        connection: connection ?? DeviceConnectionMonitor(),
      );
      if (startSync) syncService!.start();
    }
    _authSubscription = auth?.authStateChanges.listen(_handleUser);
  }

  final AppDatabase database;
  final SupabaseClient? client;
  final AuthGateway? auth;
  final RoomRepository? rooms;
  final RoomEvents Function()? _eventsFactory;
  late final SyncQueue queue;
  late final ValueNotifier<User?> session;
  final roomList = ValueNotifier<List<Room>>([]);
  final roomsLoading = ValueNotifier<bool>(false);
  final roomsError = ValueNotifier<AppError?>(null);
  Future<List<Room>>? _roomsInFlight;
  bool _roomsRefreshQueued = false;
  SupabaseSyncQueue? remoteQueue;
  SyncService? syncService;
  StreamSubscription<User?>? _authSubscription;
  final Set<RoomController> _controllers = {};
  int _roomsRequestGeneration = 0;
  bool _disposed = false;

  User? get currentUser => session.value;
  bool get isConfigured => rooms != null;
  LocalRoomCache get cache => cacheForActor(currentUser?.id ?? '');
  LocalRoomCache cacheForActor(String actorId) =>
      LocalRoomCache(database, actorId: actorId);

  static AppServices create({required bool supabaseConfigured}) {
    final database = AppDatabase();
    if (!supabaseConfigured) return AppServices(database: database);
    final client = Supabase.instance.client;
    final repository = SupabaseRoomRepository(client);
    return AppServices(
      database: database,
      client: client,
      rooms: repository,
      auth: SupabaseAuthService(
        authRepository: SupabaseAuthRepository(client),
        roomRepository: repository,
      ),
      eventsFactory: () => SupabaseSync(client),
    );
  }

  void _handleUser(User? user) {
    if (_disposed) return;
    final changed = currentUser?.id != user?.id;
    if (!changed) {
      session.value = user;
      return;
    }
    _roomsRequestGeneration++;
    _roomsInFlight = null;
    _roomsRefreshQueued = false;
    queue.invalidateSession();
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    roomList.value = const [];
    roomsError.value = null;
    roomsLoading.value = false;
    session.value = user;
    unawaited(syncService?.activateSession());
  }

  RoomController createRoomController(String roomId) {
    final actor = currentUser?.id;
    final repository = rooms;
    final eventsFactory = _eventsFactory;
    if (actor == null || repository == null || eventsFactory == null) {
      throw const AppError(AppErrorKind.unauthenticated, '请先登录');
    }
    final controller = RoomController(
      roomId: roomId,
      actorId: actor,
      repository: repository,
      cache: cacheForActor(actor),
      queue: queue,
      events: eventsFactory(),
      requestSync: flushSyncQueue,
    );
    _controllers.add(controller);
    return controller;
  }

  void releaseRoomController(RoomController controller) {
    _controllers.remove(controller);
    controller.dispose();
  }

  /// Single-flight room list loading: concurrent callers share one request and
  /// a forced refresh requested while a load is running is queued once.
  Future<List<Room>> loadRooms({bool force = false}) {
    if (_disposed) {
      return Future.error(const AppError(AppErrorKind.sessionChanged, '应用已关闭'));
    }
    final actor = currentUser?.id;
    if (actor == null || rooms == null) {
      roomsLoading.value = false;
      roomsError.value = null;
      return Future.value(const <Room>[]);
    }
    final active = _roomsInFlight;
    if (active != null) {
      if (force) _roomsRefreshQueued = true;
      return active;
    }
    final generation = queue.generation;
    final requestGeneration = ++_roomsRequestGeneration;
    late final Future<List<Room>> run;
    run = _loadRooms(force, actor, generation, requestGeneration)
        .then((values) {
          _requireRoomsRequestCurrent(actor, generation, requestGeneration);
          return values;
        })
        .whenComplete(() {
          if (!identical(_roomsInFlight, run)) return;
          _roomsInFlight = null;
          if (_roomsRefreshQueued && !_disposed) {
            _roomsRefreshQueued = false;
            unawaited(
              loadRooms(force: true).catchError((Object _) => const <Room>[]),
            );
          }
        });
    _roomsInFlight = run;
    return run;
  }

  void _requireRoomsRequestCurrent(
    String actor,
    int generation,
    int requestGeneration,
  ) {
    if (_disposed ||
        !queue.isCurrent(actor, generation) ||
        requestGeneration != _roomsRequestGeneration) {
      throw const AppError(AppErrorKind.sessionChanged, '账号已切换，请重新加载房间');
    }
  }

  Future<List<Room>> _loadRooms(
    bool force,
    String actor,
    int generation,
    int requestGeneration,
  ) async {
    final local = cacheForActor(actor);
    var cached = const <Room>[];
    roomsLoading.value = true;
    roomsError.value = null;
    try {
      cached = await local.listRooms();
      _requireRoomsRequestCurrent(actor, generation, requestGeneration);
      if (!force && cached.isNotEmpty) {
        roomList.value = cached;
        _roomsRefreshQueued = true;
        return cached;
      }
      final values = await rooms!.listMyRooms().timeout(
        const Duration(seconds: 20),
      );
      _requireRoomsRequestCurrent(actor, generation, requestGeneration);
      await local.saveRooms(values);
      _requireRoomsRequestCurrent(actor, generation, requestGeneration);
      roomList.value = values;
      roomsError.value = null;
      return values;
    } catch (error) {
      _requireRoomsRequestCurrent(actor, generation, requestGeneration);
      final failure = mapAppError(error);
      if (failure.isRetryable && cached.isNotEmpty) {
        roomsError.value = null;
        return cached;
      }
      roomsError.value = failure;
      throw failure;
    } finally {
      if (!_disposed && requestGeneration == _roomsRequestGeneration) {
        roomsLoading.value = false;
      }
    }
  }

  void invalidateRooms() {
    unawaited(
      loadRooms(force: true).catchError((Object error) => roomList.value),
    );
  }

  Future<void> flushSyncQueue() async {
    if (syncService != null) {
      await syncService!.flush();
    } else {
      await remoteQueue?.flush();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    queue.invalidateSession();
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    await _authSubscription?.cancel();
    await syncService?.dispose();
    session.dispose();
    roomList.dispose();
    roomsLoading.dispose();
    roomsError.dispose();
    await database.close();
  }
}
