import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../../domain/room_snapshot.dart';
import 'app_database.dart';

class LocalRoomCache {
  LocalRoomCache(this.database, {required this.actorId});

  final AppDatabase database;
  final String actorId;
  int lastWriteCount = 0;

  Future<void> _syncRows<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    List<D> oldRows,
    List<D> nextRows,
    String Function(D) key,
  ) async {
    final old = {for (final row in oldRows) key(row): row};
    final next = {for (final row in nextRows) key(row): row};
    bool same(D a, D b) {
      final left = a.toJson()..remove('updatedAt');
      final right = b.toJson()..remove('updatedAt');
      return jsonEncode(left) == jsonEncode(right);
    }

    await database.batch((batch) {
      for (final row in oldRows) {
        if (!next.containsKey(key(row))) {
          batch.delete(table, row as Insertable<D>);
          lastWriteCount++;
        }
      }
      for (final row in nextRows) {
        final previous = old[key(row)];
        if (previous == null || !same(previous, row)) {
          batch.insertAllOnConflictUpdate(table, [row as Insertable<D>]);
          lastWriteCount++;
        }
      }
    });
  }

  Future<void> saveUser(User user) async {
    final previous =
        await (database.select(database.cachedUsers)..where(
              (row) => row.actorId.equals(actorId) & row.id.equals(user.id),
            ))
            .get();
    await _syncRows(database.cachedUsers, previous, [
      _userRow(user),
    ], (row) => row.id);
  }

  CachedUser _userRow(User user) => CachedUser(
    actorId: actorId,
    id: user.id,
    nickname: user.nickname,
    avatarKey: user.avatarKey,
    avatarUrl: user.avatarUrl,
    phone: user.phone,
    email: user.email,
    updatedAt: DateTime.now().toUtc(),
  );

  Future<void> saveRoom(Room room) async {
    await database.transaction(() async {
      final old = await findRoom(room.id);
      await _saveRoomAndMembers(
        room,
        snapshotAt: old?.snapshotAt,
        closeVoteJson: old?.closeVoteJson,
      );
    });
  }

  Future<void> saveRooms(List<Room> rooms) async {
    await database.transaction(() async {
      final oldRooms =
          await (database.select(database.cachedRooms)..where(
                (row) =>
                    row.actorId.equals(actorId) & row.isAccessible.equals(true),
              ))
              .get();
      final ids = rooms.map((room) => room.id).toSet();
      for (final old in oldRooms) {
        if (!ids.contains(old.id)) await invalidateRoom(old.id);
      }
      for (final room in rooms) {
        await saveRoom(room);
      }
    });
  }

  Future<void> saveRoomSnapshot({
    required Room room,
    required List<GameSession> sessions,
    required List<Round> rounds,
    Map<String, User> profiles = const {},
    RoomCloseVoteSummary? closeVote,
  }) async {
    lastWriteCount = 0;
    await database.transaction(() async {
      await _saveRoomAndMembers(
        room,
        snapshotAt: DateTime.now().toUtc(),
        closeVoteJson: closeVote == null
            ? null
            : jsonEncode(_voteToJson(closeVote)),
      );
      final oldSessions = await findGameSessions(room.id);
      final ids = {
        ...oldSessions.map((s) => s.id),
        ...sessions.map((s) => s.id),
      };
      final oldRounds =
          await (database.select(database.cachedRounds)..where(
                (row) => row.actorId.equals(actorId) & row.sessionId.isIn(ids),
              ))
              .get();
      final roundIds = {
        ...oldRounds.map((r) => r.id),
        ...rounds.map((r) => r.id),
      };
      final oldScores =
          await (database.select(database.cachedScoreChanges)..where(
                (row) =>
                    row.actorId.equals(actorId) & row.roundId.isIn(roundIds),
              ))
              .get();
      final effectiveRounds = {for (final round in rounds) round.id: round};
      final visibleSessions = sessions.map((session) => session.id).toSet();
      for (final old in oldRounds) {
        final incoming = effectiveRounds[old.id];
        if (visibleSessions.contains(old.sessionId) &&
            (incoming == null || old.version > incoming.version)) {
          effectiveRounds[old.id] = Round(
            id: old.id,
            sessionId: old.sessionId,
            number: old.roundNumber,
            createdBy: old.createdBy,
            createdAt: old.createdAt,
            version: old.version,
            note: old.note,
            deletedAt: old.deletedAt,
            changes: [
              for (final score in oldScores)
                if (score.roundId == old.id)
                  ScoreChange(playerId: score.playerId, value: score.value),
            ],
          );
        }
      }
      await _syncRows(database.cachedScoreChanges, oldScores, [
        for (final round in effectiveRounds.values) ..._scoreRows(round),
      ], (row) => row.id);
      await _syncRows(
        database.cachedRounds,
        oldRounds,
        effectiveRounds.values.map(_roundRow).toList(),
        (row) => row.id,
      );
      await _syncRows(
        database.cachedGameSessions,
        oldSessions,
        sessions.map(_sessionRow).toList(),
        (row) => row.id,
      );
      if (profiles.isNotEmpty) {
        final oldUsers =
            await (database.select(database.cachedUsers)..where(
                  (row) =>
                      row.actorId.equals(actorId) & row.id.isIn(profiles.keys),
                ))
                .get();
        await _syncRows(
          database.cachedUsers,
          oldUsers,
          profiles.values.map(_userRow).toList(),
          (row) => row.id,
        );
      }
    });
  }

  Future<void> _saveRoomAndMembers(
    Room room, {
    DateTime? snapshotAt,
    String? closeVoteJson,
  }) async {
    final now = DateTime.now().toUtc();
    final previous = await findRoom(room.id);
    final next = CachedRoom(
      actorId: actorId,
      id: room.id,
      name: room.name,
      ownerId: room.ownerId,
      gameType: room.gameType,
      scoringMode: room.scoringMode.name,
      status: room.status.name,
      inputPermission: room.inputPermission.name,
      createdAt: room.createdAt.toUtc(),
      updatedAt: now,
      version: room.version,
      closeVoteJson: closeVoteJson,
      snapshotAt: snapshotAt,
      isAccessible: true,
    );
    await _syncRows(database.cachedRooms, [?previous], [next], (row) => row.id);
    await _syncRows(database.cachedRoomMembers, await findMembers(room.id), [
      for (final member in room.members)
        CachedRoomMember(
          actorId: actorId,
          roomId: room.id,
          userId: member.userId,
          role: member.role.name,
          inputPermission: member.inputPermission.name,
          joinedAt: member.joinedAt.toUtc(),
          leftAt: member.leftAt?.toUtc(),
          updatedAt: now,
        ),
    ], (row) => row.userId);
  }

  CachedGameSession _sessionRow(GameSession session) => CachedGameSession(
    actorId: actorId,
    id: session.id,
    roomId: session.roomId,
    name: session.name,
    status: session.status.name,
    createdAt: session.createdAt.toUtc(),
    startedAt: session.startedAt?.toUtc(),
    finishedAt: session.finishedAt?.toUtc(),
    updatedAt: DateTime.now().toUtc(),
    version: session.version,
  );

  CachedRound _roundRow(Round round) => CachedRound(
    actorId: actorId,
    id: round.id,
    sessionId: round.sessionId,
    roundNumber: round.number,
    createdBy: round.createdBy,
    note: round.note,
    createdAt: round.createdAt.toUtc(),
    deletedAt: round.deletedAt?.toUtc(),
    updatedAt: DateTime.now().toUtc(),
    version: round.version,
  );

  List<CachedScoreChange> _scoreRows(Round round) => [
    for (final change in round.changes)
      CachedScoreChange(
        actorId: actorId,
        id: '${round.id}:${change.playerId}',
        roundId: round.id,
        playerId: change.playerId,
        value: change.value,
        updatedAt: DateTime.now().toUtc(),
      ),
  ];

  Future<void> saveRound(Round round) async {
    await database.transaction(() async {
      final old =
          await (database.select(database.cachedRounds)..where(
                (row) => row.actorId.equals(actorId) & row.id.equals(round.id),
              ))
              .get();
      if (old.isNotEmpty && old.first.version > round.version) return;
      await _syncRows(database.cachedRounds, old, [
        _roundRow(round),
      ], (row) => row.id);
      await _syncRows(
        database.cachedScoreChanges,
        await findScoreChanges(round.id),
        _scoreRows(round),
        (row) => row.id,
      );
    });
  }

  Future<void> acknowledgeRound(SyncQueueEntry entry, Round round) async {
    if (entry.actorId != actorId) throw StateError('Cache account mismatch');
    await database.transaction(() async {
      await saveRound(round);
      await database.markOperationSynced(
        actorId,
        entry.operationId,
        DateTime.now().toUtc(),
        ackJson: jsonEncode(roundToJson(round)),
      );
      await (database.update(database.syncQueueEntries)..where(
            (row) =>
                row.actorId.equals(actorId) &
                row.dependsOn.equals(entry.operationId) &
                row.status.isIn(['pending', 'retrying']),
          ))
          .write(SyncQueueEntriesCompanion(baseVersion: Value(round.version)));
    });
  }

  Future<void> invalidateRoom(String roomId) async {
    await (database.update(database.cachedRooms)
          ..where((row) => row.actorId.equals(actorId) & row.id.equals(roomId)))
        .write(const CachedRoomsCompanion(isAccessible: Value(false)));
  }

  Stream<RoomSnapshot?> watchRoomSnapshot(String roomId) => database
      .customSelect(
        'SELECT id FROM cached_rooms WHERE actor_id = ? AND id = ?',
        variables: [Variable<String>(actorId), Variable<String>(roomId)],
        readsFrom: {
          database.cachedRooms,
          database.cachedRoomMembers,
          database.cachedGameSessions,
          database.cachedRounds,
          database.cachedScoreChanges,
          database.cachedUsers,
          database.syncQueueEntries,
        },
      )
      .watch()
      .asyncMap((_) => loadRoomSnapshot(roomId));

  Future<RoomSnapshot?> loadRoomSnapshot(
    String roomId, {
    bool includePending = true,
  }) => database.transaction(() async {
    final cached = await findRoom(roomId);
    if (cached == null || !cached.isAccessible || cached.snapshotAt == null) {
      return null;
    }
    final room = await _roomFromCache(cached);
    final sessions = await findGameSessions(roomId);
    final storedRounds =
        await (database.select(database.cachedRounds)..where(
              (row) =>
                  row.actorId.equals(actorId) &
                  row.sessionId.isIn(sessions.map((s) => s.id)),
            ))
            .get();
    final scores =
        await (database.select(database.cachedScoreChanges)..where(
              (row) =>
                  row.actorId.equals(actorId) &
                  row.roundId.isIn(storedRounds.map((r) => r.id)),
            ))
            .get();
    final scoresByRound = <String, List<ScoreChange>>{};
    for (final score in scores) {
      scoresByRound
          .putIfAbsent(score.roundId, () => [])
          .add(ScoreChange(playerId: score.playerId, value: score.value));
    }
    final rounds = <String, Round>{
      for (final row in storedRounds)
        row.id: Round(
          id: row.id,
          sessionId: row.sessionId,
          number: row.roundNumber,
          changes: scoresByRound[row.id] ?? const [],
          createdBy: row.createdBy,
          createdAt: row.createdAt,
          note: row.note,
          deletedAt: row.deletedAt,
          version: row.version,
        ),
    };
    if (includePending) {
      for (final entry in await database.unresolvedOperations(
        actorId: actorId,
      )) {
        if (entry.roomId != roomId || entry.entityType != 'round') continue;
        final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
        final value = payload['round'];
        if (value is Map<String, dynamic>) {
          final round = roundFromJson(value);
          rounds[round.id] = round;
        }
      }
    }
    final profiles =
        await (database.select(database.cachedUsers)..where(
              (row) =>
                  row.actorId.equals(actorId) &
                  row.id.isIn(room.members.map((m) => m.userId)),
            ))
            .get();
    final sorted = rounds.values.toList()
      ..sort((a, b) {
        final sessionOrder = a.sessionId.compareTo(b.sessionId);
        if (sessionOrder != 0) return sessionOrder;
        final numberOrder = a.number.compareTo(b.number);
        return numberOrder != 0 ? numberOrder : a.id.compareTo(b.id);
      });
    return RoomSnapshot(
      room: room,
      sessions: List.unmodifiable([
        for (final row in sessions)
          GameSession(
            id: row.id,
            roomId: row.roomId,
            name: row.name,
            status: GameSessionStatus.values.byName(row.status),
            createdAt: row.createdAt,
            startedAt: row.startedAt,
            finishedAt: row.finishedAt,
            version: row.version,
            roundIds: [
              for (final r in sorted)
                if (r.sessionId == row.id) r.id,
            ],
          ),
      ]),
      rounds: List.unmodifiable(sorted),
      profiles: Map.unmodifiable({
        for (final row in profiles)
          row.id: User(
            id: row.id,
            nickname: row.nickname,
            avatarKey: row.avatarKey,
            avatarUrl: row.avatarUrl,
          ),
      }),
      closeVote: cached.closeVoteJson == null
          ? null
          : _voteFromJson(
              jsonDecode(cached.closeVoteJson!) as Map<String, dynamic>,
            ),
    );
  });

  Future<List<Room>> listRooms() async {
    final rows =
        await (database.select(database.cachedRooms)..where(
              (row) =>
                  row.actorId.equals(actorId) & row.isAccessible.equals(true),
            ))
            .get();
    return [for (final row in rows) await _roomFromCache(row)];
  }

  Future<Room> _roomFromCache(CachedRoom row) async => Room(
    id: row.id,
    name: row.name,
    ownerId: row.ownerId,
    gameType: row.gameType,
    scoringMode: ScoringMode.values.byName(row.scoringMode),
    status: RoomStatus.values.byName(row.status),
    inputPermission: InputPermission.values.byName(row.inputPermission),
    createdAt: row.createdAt,
    version: row.version,
    members: [
      for (final member in await findMembers(row.id))
        RoomMember(
          userId: member.userId,
          role: RoomRole.values.byName(member.role),
          inputPermission: InputPermission.values.byName(
            member.inputPermission,
          ),
          joinedAt: member.joinedAt,
          leftAt: member.leftAt,
        ),
    ],
  );

  Future<CachedRoom?> findRoom(String roomId) =>
      (database.select(database.cachedRooms)..where(
            (row) => row.actorId.equals(actorId) & row.id.equals(roomId),
          ))
          .getSingleOrNull();

  Future<List<CachedRoomMember>> findMembers(String roomId) =>
      (database.select(database.cachedRoomMembers)..where(
            (row) => row.actorId.equals(actorId) & row.roomId.equals(roomId),
          ))
          .get();

  Future<List<CachedGameSession>> findGameSessions(String roomId) =>
      (database.select(database.cachedGameSessions)..where(
            (row) => row.actorId.equals(actorId) & row.roomId.equals(roomId),
          ))
          .get();

  Future<List<CachedRound>> findRounds(String sessionId) =>
      (database.select(database.cachedRounds)..where(
            (row) =>
                row.actorId.equals(actorId) & row.sessionId.equals(sessionId),
          ))
          .get();

  Future<List<CachedScoreChange>> findScoreChanges(String roundId) =>
      (database.select(database.cachedScoreChanges)..where(
            (row) => row.actorId.equals(actorId) & row.roundId.equals(roundId),
          ))
          .get();
}

Map<String, Object?> _voteToJson(RoomCloseVoteSummary vote) => {
  'activeMemberCount': vote.activeMemberCount,
  'approvedCount': vote.approvedCount,
  'currentUserApproved': vote.currentUserApproved,
  'proposalId': vote.proposalId,
  'targetStatus': vote.targetStatus.name,
  'expiresAt': vote.expiresAt?.toIso8601String(),
  'createdBy': vote.createdBy,
};

RoomCloseVoteSummary _voteFromJson(Map<String, dynamic> json) =>
    RoomCloseVoteSummary(
      activeMemberCount: json['activeMemberCount'] as int,
      approvedCount: json['approvedCount'] as int,
      currentUserApproved: json['currentUserApproved'] as bool?,
      proposalId: json['proposalId'] as String?,
      targetStatus: RoomStatus.values.byName(json['targetStatus'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdBy: json['createdBy'] as String?,
    );
