import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

class CachedUsers extends Table {
  TextColumn get actorId => text().withDefault(const Constant(''))();
  TextColumn get id => text()();
  TextColumn get nickname => text()();
  TextColumn get avatarKey => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {actorId, id};
}

class CachedRooms extends Table {
  TextColumn get actorId => text().withDefault(const Constant(''))();
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ownerId => text()();
  TextColumn get gameType => text()();
  TextColumn get scoringMode => text()();
  TextColumn get status => text()();
  TextColumn get inputPermission => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get closeVoteJson => text().nullable()();
  DateTimeColumn get snapshotAt => dateTime().nullable()();
  BoolColumn get isAccessible => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {actorId, id};
}

class CachedRoomMembers extends Table {
  TextColumn get actorId => text().withDefault(const Constant(''))();
  TextColumn get roomId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  TextColumn get inputPermission => text()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get leftAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {actorId, roomId, userId};
}

class CachedGameSessions extends Table {
  TextColumn get actorId => text().withDefault(const Constant(''))();
  TextColumn get id => text()();
  TextColumn get roomId => text()();
  TextColumn get name => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {actorId, id};
}

class CachedRounds extends Table {
  TextColumn get actorId => text().withDefault(const Constant(''))();
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  IntColumn get roundNumber => integer()();
  TextColumn get createdBy => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {actorId, id};
}

class CachedScoreChanges extends Table {
  TextColumn get actorId => text().withDefault(const Constant(''))();
  TextColumn get id => text()();
  TextColumn get roundId => text()();
  TextColumn get playerId => text()();
  IntColumn get value => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {actorId, id};
}

class SyncQueueEntries extends Table {
  TextColumn get operationId => text()();
  TextColumn get actorId => text().withDefault(const Constant(''))();
  TextColumn get roomId => text().withDefault(const Constant(''))();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sequence => integer().withDefault(const Constant(0))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get dependsOn => text().nullable()();
  TextColumn get ackJson => text().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {operationId};
}

@DriftDatabase(
  tables: [
    CachedUsers,
    CachedRooms,
    CachedRoomMembers,
    CachedGameSessions,
    CachedRounds,
    CachedScoreChanges,
    SyncQueueEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'paizhang',
              web: kIsWeb
                  ? DriftWebOptions(
                      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                      driftWorker: Uri.parse('drift_worker.js'),
                    )
                  : null,
            ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await transaction(() async {
          await m.alterTable(
            TableMigration(
              cachedUsers,
              newColumns: [
                cachedUsers.actorId,
                cachedUsers.avatarKey,
                cachedUsers.avatarUrl,
              ],
            ),
          );
          await m.alterTable(
            TableMigration(
              cachedRooms,
              newColumns: [
                cachedRooms.actorId,
                cachedRooms.closeVoteJson,
                cachedRooms.snapshotAt,
                cachedRooms.isAccessible,
              ],
            ),
          );
          await m.alterTable(
            TableMigration(
              cachedRoomMembers,
              newColumns: [cachedRoomMembers.actorId],
            ),
          );
          await m.alterTable(
            TableMigration(
              cachedGameSessions,
              newColumns: [cachedGameSessions.actorId],
            ),
          );
          await m.alterTable(
            TableMigration(cachedRounds, newColumns: [cachedRounds.actorId]),
          );
          await m.alterTable(
            TableMigration(
              cachedScoreChanges,
              newColumns: [cachedScoreChanges.actorId],
            ),
          );
          await m.alterTable(
            TableMigration(
              syncQueueEntries,
              newColumns: [
                syncQueueEntries.actorId,
                syncQueueEntries.roomId,
                syncQueueEntries.sequence,
                syncQueueEntries.status,
                syncQueueEntries.baseVersion,
                syncQueueEntries.dependsOn,
                syncQueueEntries.ackJson,
                syncQueueEntries.nextAttemptAt,
              ],
            ),
          );
          await customStatement(
            "UPDATE sync_queue_entries SET status = CASE WHEN synced_at IS NULL THEN 'quarantined' ELSE 'synced' END",
          );
          await _createIndexes();
        });
      }
    },
  );

  Future<void> _createIndexes() async {
    for (final sql in [
      'CREATE INDEX IF NOT EXISTS cached_sessions_room ON cached_game_sessions(actor_id, room_id)',
      'CREATE INDEX IF NOT EXISTS cached_rounds_session ON cached_rounds(actor_id, session_id, round_number)',
      'CREATE INDEX IF NOT EXISTS cached_scores_round ON cached_score_changes(actor_id, round_id)',
      'CREATE INDEX IF NOT EXISTS sync_actor_status ON sync_queue_entries(actor_id, status, sequence)',
      'CREATE INDEX IF NOT EXISTS sync_actor_room ON sync_queue_entries(actor_id, room_id, sequence)',
    ]) {
      await customStatement(sql);
    }
  }

  Future<void> enqueueOperation(SyncQueueEntriesCompanion entry) async {
    await transaction(() async {
      final maxSequence = syncQueueEntries.sequence.max();
      final row = await (selectOnly(
        syncQueueEntries,
      )..addColumns([maxSequence])).getSingle();
      await into(syncQueueEntries).insert(
        entry.copyWith(sequence: Value((row.read(maxSequence) ?? 0) + 1)),
      );
    });
  }

  Future<List<SyncQueueEntry>> pendingOperations({required String actorId}) =>
      (select(syncQueueEntries)
            ..where(
              (row) =>
                  row.actorId.equals(actorId) &
                  row.status.isIn(['pending', 'retrying']),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
          .get();

  Future<List<SyncQueueEntry>> unresolvedOperations({
    required String actorId,
  }) =>
      (select(syncQueueEntries)
            ..where(
              (row) =>
                  row.actorId.equals(actorId) &
                  row.status.isIn([
                    'pending',
                    'retrying',
                    'conflict',
                    'rejected',
                  ]),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
          .get();

  Stream<List<SyncQueueEntry>> watchOperations(
    String actorId, {
    String? roomId,
  }) =>
      (select(syncQueueEntries)
            ..where(
              (row) =>
                  row.actorId.equals(actorId) &
                  (roomId == null
                      ? const Constant(true)
                      : row.roomId.equals(roomId)) &
                  row.status.isIn([
                    'pending',
                    'retrying',
                    'conflict',
                    'rejected',
                  ]),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.sequence)]))
          .watch();

  Future<SyncQueueEntry?> operation(String actorId, String operationId) =>
      (select(syncQueueEntries)..where(
            (row) =>
                row.actorId.equals(actorId) &
                row.operationId.equals(operationId),
          ))
          .getSingleOrNull();

  Future<void> updateOperation(
    String actorId,
    String operationId,
    SyncQueueEntriesCompanion changes,
  ) async {
    await (update(syncQueueEntries)..where(
          (row) =>
              row.actorId.equals(actorId) & row.operationId.equals(operationId),
        ))
        .write(changes);
  }

  Future<void> markOperationSynced(
    String actorId,
    String operationId,
    DateTime at, {
    String? ackJson,
  }) => updateOperation(
    actorId,
    operationId,
    SyncQueueEntriesCompanion(
      status: const Value('synced'),
      syncedAt: Value(at),
      ackJson: Value(ackJson),
      lastError: const Value(null),
      nextAttemptAt: const Value(null),
    ),
  );
}
