import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/infrastructure/local/local_room_cache.dart';
import 'package:paizhang/infrastructure/local/sync_queue.dart';

import '../support/fakes.dart';

void main() {
  test('v1 升级保留旧缓存和队列，但未知归属数据不可由新账号读取或同步', () async {
    final executor = NativeDatabase.memory(
      setup: (sqlite) {
        for (final sql in [
          'CREATE TABLE cached_users (id TEXT NOT NULL PRIMARY KEY, nickname TEXT NOT NULL, phone TEXT, email TEXT, updated_at INTEGER NOT NULL)',
          'CREATE TABLE cached_rooms (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, owner_id TEXT NOT NULL, game_type TEXT NOT NULL, scoring_mode TEXT NOT NULL, status TEXT NOT NULL, input_permission TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, version INTEGER NOT NULL DEFAULT 1)',
          'CREATE TABLE cached_room_members (room_id TEXT NOT NULL, user_id TEXT NOT NULL, role TEXT NOT NULL, input_permission TEXT NOT NULL, joined_at INTEGER NOT NULL, left_at INTEGER, updated_at INTEGER NOT NULL, PRIMARY KEY (room_id, user_id))',
          'CREATE TABLE cached_game_sessions (id TEXT NOT NULL PRIMARY KEY, room_id TEXT NOT NULL, name TEXT NOT NULL, status TEXT NOT NULL, created_at INTEGER NOT NULL, started_at INTEGER, finished_at INTEGER, updated_at INTEGER NOT NULL, version INTEGER NOT NULL DEFAULT 1)',
          'CREATE TABLE cached_rounds (id TEXT NOT NULL PRIMARY KEY, session_id TEXT NOT NULL, round_number INTEGER NOT NULL, created_by TEXT NOT NULL, note TEXT, created_at INTEGER NOT NULL, deleted_at INTEGER, updated_at INTEGER NOT NULL, version INTEGER NOT NULL DEFAULT 1)',
          'CREATE TABLE cached_score_changes (id TEXT NOT NULL PRIMARY KEY, round_id TEXT NOT NULL, player_id TEXT NOT NULL, value INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
          'CREATE TABLE sync_queue_entries (operation_id TEXT NOT NULL PRIMARY KEY, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL, operation TEXT NOT NULL, payload_json TEXT NOT NULL, created_at INTEGER NOT NULL, attempt_count INTEGER NOT NULL DEFAULT 0, last_error TEXT, synced_at INTEGER)',
          "INSERT INTO cached_users VALUES ('old-user', '旧成员', NULL, NULL, 1)",
          "INSERT INTO cached_rooms VALUES ('old-room', '旧房间', 'old-user', '麻将', 'money', 'active', 'all', 1, 1, 5)",
          "INSERT INTO sync_queue_entries(operation_id, entity_type, entity_id, operation, payload_json, created_at) VALUES ('old-operation', 'round', 'old-round', 'create', '{\"value\":20}', 1)",
          'PRAGMA user_version = 1',
        ]) {
          sqlite.execute(sql);
        }
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);
    final old = await database
        .customSelect('SELECT * FROM sync_queue_entries')
        .getSingle();
    expect(old.read<String>('status'), 'quarantined');
    expect(old.read<String>('actor_id'), '');
    expect(old.read<String>('payload_json'), '{"value":20}');
    final rooms = await database
        .customSelect('SELECT * FROM cached_rooms')
        .get();
    expect(rooms, hasLength(1));
    expect(rooms.single.read<int>('version'), 5);
    expect(
      await LocalRoomCache(database, actorId: ownerId).listRooms(),
      isEmpty,
    );
    expect(await database.pendingOperations(actorId: ownerId), isEmpty);
    final queue = SyncQueue(database, currentActorId: () => ownerId);
    var pushes = 0;
    await queue.flush((_) async {
      pushes++;
    });
    expect(pushes, 0);
  });

  test('关闭并重新打开数据库后可恢复账号快照和待同步修改', () async {
    final directory = await Directory.systemTemp.createTemp(
      'paizhang-cache-test-',
    );
    final file = File('${directory.path}/cache.sqlite');
    var database = AppDatabase(NativeDatabase(file));
    try {
      final local = LocalRoomCache(database, actorId: ownerId);
      final snapshot = fixtureSnapshot(rounds: [fixtureRound()], version: 5);
      await local.saveRoomSnapshot(
        room: snapshot.room,
        sessions: snapshot.sessions,
        rounds: snapshot.rounds,
        profiles: snapshot.profiles,
      );
      final queue = SyncQueue(database, currentActorId: () => ownerId);
      await queue.enqueueRound(
        operationId: 'restart-edit',
        roomId: 'room-1',
        operation: 'update',
        round: fixtureRound(value: 35, version: 2),
        baseVersion: 1,
      );
      await database.close();
      database = AppDatabase(NativeDatabase(file));
      final restored = await LocalRoomCache(
        database,
        actorId: ownerId,
      ).loadRoomSnapshot('room-1');
      expect(restored!.rounds.single.changes.first.value, 35);
      expect(restored.room.version, 5);
      expect(restored.sessions.single.version, 5);
      expect(restored.profiles[ownerId]!.avatarKey, 'preset:tea');
      expect(
        await LocalRoomCache(
          database,
          actorId: memberId,
        ).loadRoomSnapshot('room-1'),
        isNull,
      );
    } finally {
      await database.close();
      await directory.delete(recursive: true);
    }
  });
}
