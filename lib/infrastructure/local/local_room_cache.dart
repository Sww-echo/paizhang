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
      await _saveRoomAndMembers(room, now);
    });
  }

  Future<void> saveRoomSnapshot({
    required Room room,
    required List<GameSession> sessions,
    required List<Round> rounds,
  }) async {
    final now = DateTime.now().toUtc();
    await database.transaction(() async {
      await _saveRoomAndMembers(room, now);

      final cachedSessions = await (database.select(
        database.cachedGameSessions,
      )..where((session) => session.roomId.equals(room.id))).get();
      for (final session in cachedSessions) {
        final cachedRounds = await (database.select(
          database.cachedRounds,
        )..where((round) => round.sessionId.equals(session.id))).get();
        for (final round in cachedRounds) {
          await (database.delete(
            database.cachedScoreChanges,
          )..where((change) => change.roundId.equals(round.id))).go();
        }
        await (database.delete(
          database.cachedRounds,
        )..where((round) => round.sessionId.equals(session.id))).go();
      }
      await (database.delete(
        database.cachedGameSessions,
      )..where((session) => session.roomId.equals(room.id))).go();

      for (final session in sessions) {
        await database
            .into(database.cachedGameSessions)
            .insertOnConflictUpdate(
              CachedGameSessionsCompanion.insert(
                id: session.id,
                roomId: session.roomId,
                name: session.name,
                status: session.status.name,
                createdAt: session.createdAt.toUtc(),
                startedAt: Value(session.startedAt?.toUtc()),
                finishedAt: Value(session.finishedAt?.toUtc()),
                updatedAt: now,
              ),
            );
      }

      for (final round in rounds) {
        await database
            .into(database.cachedRounds)
            .insertOnConflictUpdate(
              CachedRoundsCompanion.insert(
                id: round.id,
                sessionId: round.sessionId,
                roundNumber: round.number,
                createdBy: round.createdBy,
                note: Value(round.note),
                createdAt: round.createdAt.toUtc(),
                deletedAt: Value(round.deletedAt?.toUtc()),
                updatedAt: now,
              ),
            );
        for (var index = 0; index < round.changes.length; index++) {
          final change = round.changes[index];
          await database
              .into(database.cachedScoreChanges)
              .insertOnConflictUpdate(
                CachedScoreChangesCompanion.insert(
                  id: '${round.id}:$index',
                  roundId: round.id,
                  playerId: change.playerId,
                  value: change.value,
                  updatedAt: now,
                ),
              );
        }
      }
    });
  }

  Future<void> _saveRoomAndMembers(Room room, DateTime now) async {
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

  Future<List<CachedGameSession>> findGameSessions(String roomId) {
    return (database.select(
      database.cachedGameSessions,
    )..where((session) => session.roomId.equals(roomId))).get();
  }

  Future<List<CachedRound>> findRounds(String sessionId) {
    return (database.select(
      database.cachedRounds,
    )..where((round) => round.sessionId.equals(sessionId))).get();
  }

  Future<List<CachedScoreChange>> findScoreChanges(String roundId) {
    return (database.select(
      database.cachedScoreChanges,
    )..where((change) => change.roundId.equals(roundId))).get();
  }
}
