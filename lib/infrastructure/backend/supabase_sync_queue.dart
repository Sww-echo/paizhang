import '../local/sync_queue.dart';
import 'supabase_room_repository.dart';

class SupabaseSyncQueue {
  const SupabaseSyncQueue({required this.queue, required this.repository});

  final SyncQueue queue;
  final SupabaseRoomRepository repository;

  Future<void> flush() => queue.flush(repository.pushQueuedOperation);
}
