import '../../domain/app_error.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../local/local_room_cache.dart';
import '../local/sync_queue.dart';
import 'app_error_mapper.dart';

class SupabaseSyncQueue {
  const SupabaseSyncQueue({
    required this.queue,
    required this.repository,
    required this.cacheForActor,
  });

  final SyncQueue queue;
  final RoomRepository repository;
  final LocalRoomCache Function(String actorId) cacheForActor;

  Future<void> flush() => queue.flush((entry) async {
    final generation = queue.generation;
    if (!queue.isCurrent(entry.actorId, generation)) {
      throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    }
    final Round round;
    try {
      round = await repository
          .writeRound(queue.mutationFromEntry(entry))
          .timeout(const Duration(seconds: 20));
    } catch (error) {
      final failure = mapAppError(error);
      await _reconcileAccess(entry.actorId, entry.roomId, generation, failure);
      throw failure;
    }
    if (!queue.isCurrent(entry.actorId, generation)) {
      throw const AppError(AppErrorKind.sessionChanged, '账号已切换');
    }
    await cacheForActor(entry.actorId).acknowledgeRound(entry, round);
  });

  Future<void> _reconcileAccess(
    String actorId,
    String roomId,
    int generation,
    AppError failure,
  ) async {
    if (!queue.isCurrent(actorId, generation)) return;
    final roomRevoked =
        failure.code == 'room_member_required' ||
        failure.code == 'room_not_found';
    final needsRecheck =
        failure.kind == AppErrorKind.forbidden &&
        failure.code != 'round_edit_forbidden' &&
        failure.code != 'room_owner_required';
    if (!roomRevoked && !needsRecheck) return;

    final cache = cacheForActor(actorId);
    // A denied write makes cached permissions unconfirmed. Preserve the data,
    // but restore access only after a successful room-level reconciliation.
    await cache.invalidateRoom(roomId);
    if (roomRevoked || !queue.isCurrent(actorId, generation)) return;
    try {
      final snapshot = await repository
          .getRoomSnapshot(roomId)
          .timeout(const Duration(seconds: 20));
      if (!queue.isCurrent(actorId, generation) ||
          !snapshot.room.hasActiveMember(actorId)) {
        return;
      }
      await cache.saveRoomSnapshot(
        room: snapshot.room,
        sessions: snapshot.sessions,
        rounds: snapshot.rounds,
        profiles: snapshot.profiles,
        closeVote: snapshot.closeVote,
      );
    } catch (_) {
      // Reconciliation failure must not replace the original write rejection
      // with a retryable network error. A later refresh can restore the cache.
    }
  }
}
