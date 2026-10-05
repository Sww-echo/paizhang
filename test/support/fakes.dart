import 'dart:async';

import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/auth_gateway.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/domain/repositories.dart';
import 'package:paizhang/domain/room_snapshot.dart';

const ownerId = 'user-1';
const memberId = 'user-2';
final fixtureDate = DateTime.utc(2026, 10, 3);

Round fixtureRound({String id = 'round-1', String sessionId = 'session-1',
  int value = 10, int version = 1, int number = 1}) => Round(
  id: id, sessionId: sessionId, number: number,
  changes: [ScoreChange(playerId: ownerId, value: value), ScoreChange(playerId: memberId, value: -value)],
  createdBy: ownerId, createdAt: fixtureDate, version: version,
);

RoomSnapshot fixtureSnapshot({String roomId = 'room-1', String sessionId = 'session-1',
  List<Round> rounds = const [], int version = 1}) => RoomSnapshot(
  room: Room(id: roomId, name: '测试房间', ownerId: ownerId, gameType: '麻将',
    scoringMode: ScoringMode.money, createdAt: fixtureDate, version: version,
    members: [RoomMember(userId: ownerId, role: RoomRole.owner, joinedAt: fixtureDate),
      RoomMember(userId: memberId, role: RoomRole.member, joinedAt: fixtureDate)]),
  sessions: [GameSession(id: sessionId, roomId: roomId, name: '第一场',
    status: GameSessionStatus.active, createdAt: fixtureDate, version: version)],
  rounds: rounds,
  profiles: const {ownerId: User(id: ownerId, nickname: '房主', avatarKey: 'preset:tea'),
    memberId: User(id: memberId, nickname: '成员')},
);

class FakeRoomRepository implements RoomRepository {
  FakeRoomRepository({RoomSnapshot? snapshot}) : snapshot = snapshot ?? fixtureSnapshot();

  RoomSnapshot snapshot;
  String? actor = ownerId;
  @override
  String? get currentUserId => actor;
  int fetchCount = 0;
  int joinCount = 0;
  int historyRoomCalls = 0;
  int historySessionCalls = 0;
  int historyDetailCalls = 0;
  final List<RoundMutation> writes = [];
  final Map<String, Round> acknowledgements = {};
  Future<Round> Function(RoundMutation)? onWrite;
  Future<RoomSnapshot> Function(String)? onFetch;
  Future<String> Function(String)? onJoin;

  @override
  Future<Room> getRoom(String roomId) async => snapshot.room;
  @override
  Future<List<Room>> listMyRooms() async => [snapshot.room];
  @override
  Future<String> joinByToken(String token) async {
    joinCount++;
    return onJoin == null ? snapshot.room.id : await onJoin!(token);
  }
  @override
  Future<String> joinByCode(String code) => joinByToken(code);
  @override
  Future<RoomSnapshot> getRoomSnapshot(String roomId) async {
    fetchCount++;
    return onFetch == null ? snapshot : await onFetch!(roomId);
  }
  @override
  Future<Round> writeRound(RoundMutation mutation) async {
    writes.add(mutation);
    if (actor != mutation.actorId) throw const AppError(AppErrorKind.unauthenticated, '账号不匹配');
    if (onWrite != null) return onWrite!(mutation);
    final acknowledged = acknowledgements[mutation.operationId];
    if (acknowledged != null) return acknowledged;
    final matching = snapshot.rounds.where((round) => round.id == mutation.round.id);
    final previous = matching.isEmpty ? null : matching.first;
    if (mutation.operation != 'create' && previous?.version != mutation.expectedVersion) {
      throw const AppError(AppErrorKind.conflict, '版本冲突', code: 'version_conflict');
    }
    final result = Round(id: mutation.round.id, sessionId: mutation.round.sessionId,
      number: previous?.number ?? snapshot.rounds.length + 1,
      changes: mutation.round.changes, createdBy: mutation.actorId,
      createdAt: previous?.createdAt ?? mutation.round.createdAt,
      deletedAt: mutation.round.deletedAt, note: mutation.round.note,
      version: previous == null ? 1 : previous.version + 1);
    acknowledgements[mutation.operationId] = result;
    snapshot = snapshot.withRounds([
      ...snapshot.rounds.where((round) => round.id != result.id), result,
    ]);
    return result;
  }

  @override
  Future<List<HistoryRoomSummary>> listHistoryRooms({int limit = 20, HistoryRoomSummary? before}) async {
    historyRoomCalls++;
    if (before != null) return [];
    return [HistoryRoomSummary(roomId: snapshot.room.id, name: snapshot.room.name,
      gameType: snapshot.room.gameType, scoringMode: snapshot.room.scoringMode,
      isCurrentMember: true, sessionCount: snapshot.sessions.length, lastActivityAt: fixtureDate)];
  }
  @override
  Future<List<HistorySessionSummary>> listHistorySessions(String roomId,
      {int limit = 20, HistorySessionSummary? before}) async {
    historySessionCalls++;
    if (before != null) return [];
    return [HistorySessionSummary(session: snapshot.sessions.first,
      roundCount: snapshot.rounds.length, lastActivityAt: fixtureDate)];
  }
  @override
  Future<RoomSnapshot> getHistorySession(String roomId, String sessionId) async {
    historyDetailCalls++;
    return snapshot;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoomEvents implements RoomEvents {
  final eventController = StreamController<RoomChange>.broadcast(sync: true);
  final connectionController = StreamController<bool>.broadcast(sync: true);
  bool _disposed = false;
  @override
  Stream<RoomChange> get changes => eventController.stream;
  @override
  Stream<bool> get connectionChanges => connectionController.stream;
  @override
  Future<void> start(String roomId) async => connectionController.add(true);
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await eventController.close();
    await connectionController.close();
  }
}

class FakeConnection implements ConnectionMonitor {
  final controller = StreamController<bool>.broadcast(sync: true);
  bool online = true;
  @override
  Stream<bool> get changes => controller.stream;
  @override
  Future<bool> get isOnline async => online;
  void setOnline(bool value) { online = value; controller.add(value); }
  @override
  Future<void> dispose() async {
    if (!controller.isClosed) await controller.close();
  }
}

class FakeAuth implements AuthGateway {
  FakeAuth({User? user}) : _user = user ?? const User(id: ownerId, nickname: '房主');
  User? _user;
  final changes = StreamController<User?>.broadcast(sync: true);
  @override
  User? get currentUser => _user;
  @override
  Stream<User?> get authStateChanges => changes.stream;
  void setUser(User? user) { _user = user; changes.add(user); }
  @override
  Future<void> signOut() async => setUser(null);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
