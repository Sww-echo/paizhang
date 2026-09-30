import '../domain/invite_service.dart';
import '../domain/models.dart';
import '../domain/settlement_calculator.dart';

typedef Clock = DateTime Function();
typedef IdFactory = String Function(String prefix);

class PaizhangService {
  PaizhangService({Clock? clock, IdFactory? idFactory})
    : _clock = clock ?? DateTime.now,
      _idFactory = idFactory ?? _defaultIdFactory;

  final Clock _clock;
  final IdFactory _idFactory;
  final InviteService _inviteService = const InviteService();
  final SettlementCalculator _settlementCalculator =
      const SettlementCalculator();
  final Map<String, User> _users = {};
  final Map<String, Room> _rooms = {};
  final Map<String, InviteToken> _invites = {};
  final Map<String, GameSession> _sessions = {};
  final Map<String, Round> _rounds = {};

  User registerUser({required String nickname, String? phone, String? email}) {
    if (nickname.trim().isEmpty) {
      throw const PaizhangException('昵称不能为空');
    }
    final user = User(
      id: _idFactory('user'),
      nickname: nickname.trim(),
      phone: phone,
      email: email,
    );
    _users[user.id] = user;
    return user;
  }

  Room createRoom({
    required String ownerId,
    required String name,
    required String gameType,
    required ScoringMode scoringMode,
  }) {
    _requireUser(ownerId);
    if (name.trim().isEmpty) throw const PaizhangException('房间名称不能为空');
    final room = Room(
      id: _idFactory('room'),
      name: name.trim(),
      ownerId: ownerId,
      gameType: gameType,
      scoringMode: scoringMode,
      createdAt: _clock(),
      members: [
        RoomMember(userId: ownerId, role: RoomRole.owner, joinedAt: _clock()),
      ],
    );
    _rooms[room.id] = room;
    return room;
  }

  InviteToken createInvite({
    required String roomId,
    required InviteKind kind,
    Duration? ttl,
  }) {
    final room = _requireRoom(roomId);
    if (room.status == RoomStatus.dissolved) {
      throw const PaizhangException('房间已解散');
    }
    final token = _idFactory('invite');
    final invite = InviteToken(
      id: _idFactory('invite-record'),
      roomId: roomId,
      token: token,
      kind: kind,
      createdAt: _clock(),
      expiresAt: ttl == null ? null : _clock().add(ttl),
    );
    _invites[token] = invite;
    return invite;
  }

  String inviteCode(InviteToken invite) =>
      _inviteService.createCode(invite.token);

  String inviteLink(InviteToken invite) =>
      _inviteService.createWebLink(invite.token);

  InviteToken revokeInvite({
    required String roomId,
    required String actorId,
    required String token,
  }) {
    final room = _requireRoom(roomId);
    _requireOwner(room, actorId);
    final invite = _invites[token];
    if (invite == null || invite.roomId != roomId) {
      throw const PaizhangException('邀请不存在');
    }
    final revoked = InviteToken(
      id: invite.id,
      roomId: invite.roomId,
      token: invite.token,
      kind: invite.kind,
      createdAt: invite.createdAt,
      expiresAt: invite.expiresAt,
      revokedAt: _clock(),
    );
    _invites[token] = revoked;
    return revoked;
  }

  Room joinByToken({required String userId, required String token}) {
    final invite = _invites[token];
    if (invite == null || !invite.isValidAt(_clock())) {
      throw const PaizhangException('邀请已失效');
    }
    return _joinRoom(userId: userId, roomId: invite.roomId);
  }

  Room joinByCode({required String userId, required String code}) {
    final normalized = _inviteService.normalizeCode(code);
    for (final invite in _invites.values) {
      if (invite.kind != InviteKind.code || !invite.isValidAt(_clock())) {
        continue;
      }
      if (inviteCode(invite) == normalized) {
        return _joinRoom(userId: userId, roomId: invite.roomId);
      }
    }
    throw const PaizhangException('邀请码无效或已失效');
  }

  Room setInputPermission({
    required String roomId,
    required String actorId,
    required InputPermission permission,
  }) {
    final room = _requireRoom(roomId);
    _requireOwner(room, actorId);
    final updated = room.copyWith(inputPermission: permission);
    _rooms[roomId] = updated;
    return updated;
  }

  GameSession startGame({
    required String roomId,
    required String actorId,
    required String name,
  }) {
    final room = _requireRoom(roomId);
    _requireOwner(room, actorId);
    if (room.status == RoomStatus.dissolved) {
      throw const PaizhangException('房间已解散');
    }
    if (name.trim().isEmpty) throw const PaizhangException('牌局名称不能为空');
    final session = GameSession(
      id: _idFactory('game'),
      roomId: roomId,
      name: name.trim(),
      status: GameSessionStatus.active,
      createdAt: _clock(),
      startedAt: _clock(),
    );
    _sessions[session.id] = session;
    _rooms[roomId] = room.copyWith(status: RoomStatus.active);
    return session;
  }

  Round recordRound({
    required String sessionId,
    required String actorId,
    required List<ScoreChange> changes,
    String? note,
  }) {
    final session = _requireSession(sessionId);
    final room = _requireRoom(session.roomId);
    _requireCanRecord(room, actorId);
    if (session.status != GameSessionStatus.active) {
      throw const PaizhangException('当前牌局不是进行中状态');
    }
    _validateChanges(room, changes);
    final round = Round(
      id: _idFactory('round'),
      sessionId: sessionId,
      number: session.roundIds.length + 1,
      changes: List.unmodifiable(changes),
      createdBy: actorId,
      createdAt: _clock(),
      note: note,
    );
    _rounds[round.id] = round;
    _sessions[sessionId] = session.copyWith(
      roundIds: [...session.roundIds, round.id],
    );
    return round;
  }

  Round updateRound({
    required String sessionId,
    required String roundId,
    required String actorId,
    required List<ScoreChange> changes,
    String? note,
  }) {
    final session = _requireSession(sessionId);
    final room = _requireRoom(session.roomId);
    _requireCanRecord(room, actorId);
    final current = _rounds[roundId];
    if (current == null ||
        current.sessionId != sessionId ||
        current.isDeleted) {
      throw const PaizhangException('回合不存在');
    }
    _validateChanges(room, changes);
    final updated = current.copyWith(changes: changes, note: note);
    _rounds[roundId] = updated;
    return updated;
  }

  Round deleteRound({
    required String sessionId,
    required String roundId,
    required String actorId,
  }) {
    final session = _requireSession(sessionId);
    final room = _requireRoom(session.roomId);
    _requireCanRecord(room, actorId);
    final current = _rounds[roundId];
    if (current == null ||
        current.sessionId != sessionId ||
        current.isDeleted) {
      throw const PaizhangException('回合不存在');
    }
    final deleted = current.copyWith(deletedAt: _clock());
    _rounds[roundId] = deleted;
    return deleted;
  }

  Room leaveRoom({required String roomId, required String userId}) {
    final room = _requireRoom(roomId);
    if (room.ownerId == userId) {
      throw const PaizhangException('房主不能直接退出房间，请先转让房主');
    }
    if (room.memberOf(userId) == null) {
      throw const PaizhangException('你不是当前房间成员');
    }
    final updatedMembers = room.members
        .map(
          (member) => member.userId == userId
              ? member.copyWith(leftAt: _clock())
              : member,
        )
        .toList();
    final updated = room.copyWith(members: updatedMembers);
    _rooms[roomId] = updated;
    return updated;
  }

  GameSession finishGame({required String sessionId, required String actorId}) {
    final session = _requireSession(sessionId);
    final room = _requireRoom(session.roomId);
    _requireOwner(room, actorId);
    final finished = session.copyWith(
      status: GameSessionStatus.finished,
      finishedAt: _clock(),
    );
    _sessions[sessionId] = finished;
    _rooms[room.id] = room.copyWith(status: RoomStatus.finished);
    return finished;
  }

  SettlementResult settlement(String sessionId) {
    final session = _requireSession(sessionId);
    final room = _requireRoom(session.roomId);
    final rounds = session.roundIds
        .map((roundId) => _rounds[roundId]!)
        .toList();
    return _settlementCalculator.calculate(rounds, room.scoringMode);
  }

  Room room(String roomId) => _requireRoom(roomId);

  GameSession session(String sessionId) => _requireSession(sessionId);

  User _requireUser(String userId) {
    final user = _users[userId];
    if (user == null) throw const PaizhangException('用户不存在');
    return user;
  }

  Room _requireRoom(String roomId) {
    final room = _rooms[roomId];
    if (room == null) throw const PaizhangException('房间不存在');
    return room;
  }

  GameSession _requireSession(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) throw const PaizhangException('牌局不存在');
    return session;
  }

  void _requireOwner(Room room, String actorId) {
    if (room.ownerId != actorId) throw const PaizhangException('只有房主可以执行此操作');
  }

  void _requireCanRecord(Room room, String actorId) {
    final member = room.memberOf(actorId);
    if (member == null) throw const PaizhangException('你不是当前房间成员');
    if (room.inputPermission == InputPermission.ownerOnly &&
        room.ownerId != actorId) {
      throw const PaizhangException('当前房间仅允许房主录入');
    }
  }

  void _validateChanges(Room room, List<ScoreChange> changes) {
    if (changes.isEmpty) {
      throw const PaizhangException('至少需要一名玩家的分数变化');
    }
    for (final change in changes) {
      if (!room.hasActiveMember(change.playerId)) {
        throw const PaizhangException('只能为房间成员记录分数');
      }
    }
    if (room.scoringMode == ScoringMode.money) {
      final sum = changes.fold<int>(0, (total, change) => total + change.value);
      if (sum != 0) {
        throw const PaizhangException('金额模式下本局金额必须平衡');
      }
    }
  }

  Room _joinRoom({required String userId, required String roomId}) {
    _requireUser(userId);
    final room = _requireRoom(roomId);
    if (room.status == RoomStatus.dissolved ||
        room.status == RoomStatus.archived) {
      throw const PaizhangException('房间已关闭');
    }
    if (room.hasActiveMember(userId)) return room;
    final members = [
      ...room.members,
      RoomMember(userId: userId, role: RoomRole.member, joinedAt: _clock()),
    ];
    final updated = room.copyWith(members: members);
    _rooms[roomId] = updated;
    return updated;
  }
}

String _defaultIdFactory(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}';
