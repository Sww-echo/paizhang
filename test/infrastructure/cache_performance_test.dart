import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/infrastructure/local/app_database.dart';
import 'package:paizhang/infrastructure/local/local_room_cache.dart';

import '../support/fakes.dart';

void main() {
  test('5001 回合重复快照不重写明细，单回合修改只写差量', () async {
    const count = 5001;
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final cache = LocalRoomCache(database, actorId: ownerId);
    final rounds = [
      for (var n = 1; n <= count; n++) fixtureRound(id: 'round-$n', number: n),
    ];
    final snapshot = fixtureSnapshot(rounds: rounds);
    Future<int> changes() async =>
        (await database
                .customSelect('SELECT total_changes() AS count')
                .getSingle())
            .read<int>('count');

    Future<Map<String, int>> save() async {
      final before = await changes();
      final watch = Stopwatch()..start();
      await cache.saveRoomSnapshot(
        room: snapshot.room,
        sessions: snapshot.sessions,
        rounds: rounds,
        profiles: snapshot.profiles,
      );
      watch.stop();
      final written = await changes() - before;
      expect(cache.lastWriteCount, written);
      return {'changedRows': written, 'elapsedUs': watch.elapsedMicroseconds};
    }

    final cold = await save();
    expect(cold['changedRows'], count * 3 + 6);
    final unchanged = await save();
    // The snapshot timestamp may change; no round, score or profile should.
    expect(unchanged['changedRows'], lessThanOrEqualTo(1));

    rounds[2500] = fixtureRound(
      id: 'round-2501',
      number: 2501,
      value: 25,
      version: 2,
    );
    final delta = await save();
    expect(delta['changedRows'], inInclusiveRange(3, 4));

    final watch = Stopwatch()..start();
    final restored = await cache.loadRoomSnapshot('room-1');
    watch.stop();
    expect(restored!.rounds, hasLength(count));
    expect(restored.rounds[2500].version, 2);
    expect(restored.rounds[2500].changes.first.value, 25);
    // Real SQLite changes, but synthetic data and local timings, not a device SLO.
    debugPrint(
      jsonEncode({
        'benchmark': 'sqlite-snapshot-fixture',
        'rounds': count,
        'scores': count * 2,
        'cold': cold,
        'unchanged': unchanged,
        'oneRoundChanged': delta,
        'restoreUs': watch.elapsedMicroseconds,
      }),
    );
  });
}
