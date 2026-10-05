import '../domain/models.dart';
import '../domain/room_snapshot.dart';

int activeRoundCount(RemoteRoomSnapshot snapshot, GameSession session) {
  return snapshot.rounds
      .where((round) => round.sessionId == session.id && !round.isDeleted)
      .length;
}

DateTime sessionDate(GameSession session) {
  return session.finishedAt ?? session.startedAt ?? session.createdAt;
}

String sessionStatusLabel(GameSessionStatus status) {
  return switch (status) {
    GameSessionStatus.draft => '未开始',
    GameSessionStatus.active => '进行中',
    GameSessionStatus.finished => '已结束',
  };
}

String roomStatusLabel(RoomStatus status) {
  return switch (status) {
    RoomStatus.waiting => '等待中',
    RoomStatus.active => '进行中',
    RoomStatus.finished => '已结束',
    RoomStatus.archived => '已归档',
    RoomStatus.dissolved => '已解散',
  };
}

String formatHistoryDate(DateTime value) {
  final date = value.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}

Map<String, int> scoreTotalsForSession(
  Iterable<Round> rounds,
  String sessionId,
) {
  final totals = <String, int>{};
  for (final round in rounds) {
    if (round.sessionId != sessionId || round.isDeleted) continue;
    for (final change in round.changes) {
      totals.update(
        change.playerId,
        (value) => value + change.value,
        ifAbsent: () => change.value,
      );
    }
  }
  return totals;
}

String memberLabel(RoomMember member, Map<String, User> profiles) {
  return profiles[member.userId]?.nickname ?? '玩家 ${shortId(member.userId)}';
}

String scoreUnitLabel(ScoringMode mode) {
  return mode == ScoringMode.money ? '金额' : '积分';
}

int sumChanges(Iterable<ScoreChange> changes) {
  return changes.fold<int>(0, (sum, change) => sum + change.value);
}

String profileName(String userId, Map<String, User> profiles) {
  return profiles[userId]?.nickname ?? '玩家 ${shortId(userId)}';
}

String initialFor(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

String shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
