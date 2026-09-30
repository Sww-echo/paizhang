import 'package:drift/drift.dart';

import '../../domain/models.dart';
import 'app_database.dart';

class LocalRoomCache {
  const LocalRoomCache(this.database);

  final AppDatabase database;

  Future<void> saveUser(User user) {
    return database
        .into(database.cachedUsers)
        .insertOnConflictUpdate(
          CachedUsersCompanion.insert(
            id: user.id,
            nickname: user.nickname,
            phone: Value(user.phone),
            email: Value(user.email),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> saveRoom(Room room) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await database
          .into(database.cachedRooms)
          .insertOnConflictUpdate(
            CachedRoomsCompanion.insert(
              id: room.id,
              name: room.name,
              ownerId: room.ownerId,
              gameType: room.gameType,
              scoringMode: room.scoringMode.name,
              status: room.status.name,
              inputPermission: room.inputPermission.name,
              createdAt: room.createdAt.toUtc(),
              updatedAt: now,
            ),
          );
      await (database.delete(
        database.cachedRoomMembers,
      )..where((member) => member.roomId.equals(room.id))).go();
      for (final member in room.members) {
        await database
            .into(database.cachedRoomMembers)
            .insertOnConflictUpdate(
              CachedRoomMembersCompanion.insert(
                roomId: room.id,
                userId: member.userId,
                role: member.role.name,
                inputPermission: member.inputPermission.name,
                joinedAt: member.joinedAt.toUtc(),
                leftAt: Value(member.leftAt?.toUtc()),
                updatedAt: now,
              ),
            );
      }
    });
  }

  Future<CachedRoom?> findRoom(String roomId) {
    return (database.select(
      database.cachedRooms,
    )..where((room) => room.id.equals(roomId))).getSingleOrNull();
  }

  Future<List<CachedRoomMember>> findMembers(String roomId) {
    return (database.select(
      database.cachedRoomMembers,
    )..where((member) => member.roomId.equals(roomId))).get();
  }
}
