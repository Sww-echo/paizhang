import 'models.dart';

class RoomSnapshot {
  const RoomSnapshot({
    required this.room,
    required this.sessions,
    required this.rounds,
    this.profiles = const {},
    this.closeVote,
  });

  final Room room;
  final List<GameSession> sessions;
  final List<Round> rounds;
  final Map<String, User> profiles;
  final RoomCloseVoteSummary? closeVote;

  RoomSnapshot withRounds(List<Round> values) => RoomSnapshot(
    room: room,
    sessions: sessions,
    rounds: List.unmodifiable(values),
    profiles: profiles,
    closeVote: closeVote,
  );
}

typedef RemoteRoomSnapshot = RoomSnapshot;

class RoundMutation {
  const RoundMutation({
    required this.operationId,
    required this.actorId,
    required this.roomId,
    required this.operation,
    required this.round,
    this.expectedVersion,
  });

  final String operationId;
  final String actorId;
  final String roomId;
  final String operation;
  final Round round;
  final int? expectedVersion;
}

class HistoryRoomSummary {
  const HistoryRoomSummary({
    required this.roomId,
    required this.name,
    required this.gameType,
    required this.scoringMode,
    required this.isCurrentMember,
    required this.sessionCount,
    required this.lastActivityAt,
  });

  final String roomId;
  final String name;
  final String gameType;
  final ScoringMode scoringMode;
  final bool isCurrentMember;
  final int sessionCount;
  final DateTime lastActivityAt;
}

class HistorySessionSummary {
  const HistorySessionSummary({
    required this.session,
    required this.roundCount,
    required this.lastActivityAt,
  });

  final GameSession session;
  final int roundCount;
  final DateTime lastActivityAt;
}

Map<String, Object?> roundToJson(Round round) => {
  'id': round.id,
  'session_id': round.sessionId,
  'round_number': round.number,
  'created_by': round.createdBy,
  'created_at': round.createdAt.toUtc().toIso8601String(),
  'note': round.note,
  'deleted_at': round.deletedAt?.toUtc().toIso8601String(),
  'version': round.version,
  'score_changes': [
    for (final change in round.changes)
      {'player_id': change.playerId, 'value': change.value},
  ],
};

Round roundFromJson(Map<String, dynamic> row) => Round(
  id: row['id'] as String,
  sessionId: row['session_id'] as String,
  number: (row['round_number'] as num).toInt(),
  createdBy: row['created_by'] as String,
  createdAt: DateTime.parse(row['created_at'] as String),
  note: row['note'] as String?,
  deletedAt: row['deleted_at'] == null
      ? null
      : DateTime.parse(row['deleted_at'] as String),
  version: (row['version'] as num?)?.toInt() ?? 1,
  changes: List.unmodifiable([
    for (final change in (row['score_changes'] as List? ?? const []))
      ScoreChange(
        playerId: change['player_id'] as String,
        value: (change['value'] as num).toInt(),
      ),
  ]),
);
