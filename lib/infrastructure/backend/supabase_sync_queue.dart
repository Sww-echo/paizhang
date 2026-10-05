import '../../domain/app_error.dart';
import '../../domain/repositories.dart';
import '../local/local_room_cache.dart';
import '../local/sync_queue.dart';

class SupabaseSyncQueue {
  const SupabaseSyncQueue({required this.queue, required this.repository,
    required this.cacheForActor});

  final SyncQueue queue;
  final RoomRepository repository;
  final LocalRoomCache Function(String actorId) cacheForActor;

  Future<void> flush() => queue.flush((entry) async {
    final generation = queue.generation;
    if (!queue.isCurrent(entry.actorId, generation)) {
      throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    }
    final round = await repository.writeRound(queue.mutationFromEntry(entry))
        .timeout(const Duration(seconds: 20));
    if (!queue.isCurrent(entry.actorId, generation)) {
      throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    }
    await cacheForActor(entry.actorId).acknowledgeRound(entry, round);
  });
}
