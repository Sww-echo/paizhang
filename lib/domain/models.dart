enum ScoringMode { points, money }

enum RoomStatus { waiting, active, finished, archived, dissolved }

enum RoomRole { owner, member }

enum InputPermission { all, ownerOnly }

enum InviteKind { qr, link, code }

enum GameSessionStatus { draft, active, finished }

class User {
  const User({
    required this.id,
    required this.nickname,
    this.avatarKey,
    this.avatarUrl,
    this.phone,
    this.email,
  });

  final String id;
  final String nickname;
  final String? avatarKey;
  final String? avatarUrl;
  final String? phone;
  final String? email;
}

class RoomCloseVoteSummary {
  const RoomCloseVoteSummary({
    required this.activeMemberCount,
    required this.approvedCount,
    this.currentUserApproved,
    this.proposalId,
    this.targetStatus = RoomStatus.archived,
    this.expiresAt,
    this.createdBy,
  });

  final int activeMemberCount;
  final int approvedCount;
  final bool? currentUserApproved;
  final String? proposalId;
  final RoomStatus targetStatus;
  final DateTime? expiresAt;
  final String? createdBy;

  bool get isPassed =>
      activeMemberCount > 0 && approvedCount * 2 >= activeMemberCount;

  RoomCloseVoteSummary copyWith({
    int? activeMemberCount,
    int? approvedCount,
    bool? currentUserApproved,
    bool clearCurrentUserApproved = false,
  }) {
    return RoomCloseVoteSummary(
      activeMemberCount: activeMemberCount ?? this.activeMemberCount,
      approvedCount: approvedCount ?? this.approvedCount,
      currentUserApproved: clearCurrentUserApproved
          ? null
          : (currentUserApproved ?? this.currentUserApproved),
      proposalId: proposalId,
      targetStatus: targetStatus,
      expiresAt: expiresAt,
      createdBy: createdBy,
    );
  }
}

class AuthChallenge {
  const AuthChallenge({
    required this.id,
    required this.identifier,
    required this.verificationCode,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String identifier;
  final String verificationCode;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isValidAt(DateTime now) => expiresAt.isAfter(now);
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
  });

  final String token;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool isValidAt(DateTime now) => expiresAt.isAfter(now);
}

class RoomMember {
  const RoomMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.inputPermission = InputPermission.all,
    this.leftAt,
  });

  final String userId;
  final RoomRole role;
  final InputPermission inputPermission;
  final DateTime joinedAt;
  final DateTime? leftAt;

  bool get isActive => leftAt == null;

  RoomMember copyWith({
    RoomRole? role,
    InputPermission? inputPermission,
    DateTime? leftAt,
    bool clearLeftAt = false,
  }) {
    return RoomMember(
      userId: userId,
      role: role ?? this.role,
      inputPermission: inputPermission ?? this.inputPermission,
      joinedAt: joinedAt,
      leftAt: clearLeftAt ? null : (leftAt ?? this.leftAt),
    );
  }
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.gameType,
    required this.scoringMode,
    required this.createdAt,
    required this.members,
    this.status = RoomStatus.waiting,
    this.inputPermission = InputPermission.all,
    this.version = 1,
  });

  final String id;
  final String name;
  final String ownerId;
  final String gameType;
  final ScoringMode scoringMode;
  final RoomStatus status;
  final InputPermission inputPermission;
  final DateTime createdAt;
  final List<RoomMember> members;
  final int version;

  bool get isClosed =>
      status == RoomStatus.archived || status == RoomStatus.dissolved;

  RoomMember? memberOf(String userId) {
    for (final member in members) {
      if (member.userId == userId && member.isActive) return member;
    }
    return null;
  }

  bool hasActiveMember(String userId) => memberOf(userId) != null;

  Room copyWith({
    RoomStatus? status,
    InputPermission? inputPermission,
    List<RoomMember>? members,
  }) {
    return Room(
      id: id,
      name: name,
      ownerId: ownerId,
      gameType: gameType,
      scoringMode: scoringMode,
      status: status ?? this.status,
      inputPermission: inputPermission ?? this.inputPermission,
      createdAt: createdAt,
      members: List.unmodifiable(members ?? this.members),
      version: version,
    );
  }
}

class InviteToken {
  const InviteToken({
    required this.id,
    required this.roomId,
    required this.token,
    required this.kind,
    required this.createdAt,
    this.expiresAt,
    this.revokedAt,
  });

  final String id;
  final String roomId;
  final String token;
  final InviteKind kind;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  bool isValidAt(DateTime now) {
    final expired = expiresAt != null && !expiresAt!.isAfter(now);
    return revokedAt == null && !expired;
  }
}

class GameSession {
  const GameSession({
    required this.id,
    required this.roomId,
    required this.name,
    required this.createdAt,
    this.status = GameSessionStatus.draft,
    this.startedAt,
    this.finishedAt,
    this.roundIds = const [],
    this.version = 1,
  });

  final String id;
  final String roomId;
  final String name;
  final GameSessionStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final List<String> roundIds;
  final int version;

  GameSession copyWith({
    GameSessionStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<String>? roundIds,
  }) {
    return GameSession(
      id: id,
      roomId: roomId,
      name: name,
      status: status ?? this.status,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      roundIds: List.unmodifiable(roundIds ?? this.roundIds),
      version: version,
    );
  }
}

class ScoreChange {
  const ScoreChange({required this.playerId, required this.value});

  final String playerId;
  final int value;
}

class Round {
  const Round({
    required this.id,
    required this.sessionId,
    required this.number,
    required this.changes,
    required this.createdBy,
    required this.createdAt,
    this.note,
    this.deletedAt,
    this.version = 1,
  });

  final String id;
  final String sessionId;
  final int number;
  final List<ScoreChange> changes;
  final String createdBy;
  final DateTime createdAt;
  final String? note;
  final DateTime? deletedAt;
  final int version;

  bool get isDeleted => deletedAt != null;

  Round copyWith({
    List<ScoreChange>? changes,
    String? note,
    bool clearNote = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    int? version,
  }) {
    return Round(
      id: id,
      sessionId: sessionId,
      number: number,
      changes: List.unmodifiable(changes ?? this.changes),
      createdBy: createdBy,
      createdAt: createdAt,
      note: clearNote ? null : (note ?? this.note),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
    );
  }
}

class SettlementTransfer {
  const SettlementTransfer({
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.amount,
  });

  final String fromPlayerId;
  final String toPlayerId;
  final int amount;
}

class SettlementResult {
  const SettlementResult({
    required this.totals,
    required this.transfers,
    required this.isBalanced,
    this.unbalancedAmount = 0,
  });

  final Map<String, int> totals;
  final List<SettlementTransfer> transfers;
  final bool isBalanced;
  final int unbalancedAmount;
}

class PaizhangException implements Exception {
  const PaizhangException(this.message);

  final String message;

  @override
  String toString() => message;
}
