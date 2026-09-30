import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

class CachedUsers extends Table {
  TextColumn get id => text()();
  TextColumn get nickname => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedRooms extends Table {
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

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedRoomMembers extends Table {
  TextColumn get roomId => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  TextColumn get inputPermission => text()();
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get leftAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {roomId, userId};
}

class CachedGameSessions extends Table {
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
  Set<Column<Object>> get primaryKey => {id};
}

class CachedRounds extends Table {
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
  Set<Column<Object>> get primaryKey => {id};
}

class CachedScoreChanges extends Table {
  TextColumn get id => text()();
  TextColumn get roundId => text()();
  TextColumn get playerId => text()();
  IntColumn get value => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncQueueEntries extends Table {
  TextColumn get operationId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
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
  int get schemaVersion => 1;

  Future<void> enqueueOperation(SyncQueueEntriesCompanion entry) {
    return into(syncQueueEntries).insertOnConflictUpdate(entry);
  }

  Future<List<SyncQueueEntry>> pendingOperations() {
    return (select(syncQueueEntries)
          ..where((row) => row.syncedAt.isNull())
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
  }

  Future<void> markOperationSynced(String operationId, DateTime at) {
    return (update(syncQueueEntries)
          ..where((row) => row.operationId.equals(operationId)))
        .write(SyncQueueEntriesCompanion(syncedAt: Value(at)));
  }

  Future<void> markOperationFailed({
    required String operationId,
    required String error,
  }) async {
    final entry = await (select(
      syncQueueEntries,
    )..where((row) => row.operationId.equals(operationId))).getSingle();
    await (update(
      syncQueueEntries,
    )..where((row) => row.operationId.equals(operationId))).write(
      SyncQueueEntriesCompanion(
        attemptCount: Value(entry.attemptCount + 1),
        lastError: Value(error),
      ),
    );
  }
}
