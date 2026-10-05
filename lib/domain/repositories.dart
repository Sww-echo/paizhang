import 'dart:typed_data';

import 'invite_service.dart';
import 'models.dart';
import 'room_snapshot.dart';

class RemoteInvite {
  const RemoteInvite({required this.id, required this.roomId, required this.token,
    required this.code, required this.kind, required this.expiresAt,
    this.createdAt, this.revokedAt});

  final String id;
  final String roomId;
  final String token;
  final String code;
  final InviteKind kind;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? revokedAt;
  bool get hasSecret => token.isNotEmpty;
  String get shareLink => hasSecret ? const InviteService().createWebLink(token) : '';
}

class RemoteAvatarUpload {
  const RemoteAvatarUpload({required this.key, required this.url});
  final String key;
  final String url;
}

abstract interface class RoomRepository {
  String? get currentUserId;
  Future<void> ensureCurrentUserProfile({required String nickname,
    String? avatarKey, String? avatarUrl, bool clearAvatar = false, bool replaceAvatar = false});
  Future<Room> createRoom({required String name, required String gameType, required ScoringMode scoringMode});
  Future<void> leaveRoom(String roomId);
  Future<String> joinByToken(String token);
  Future<String> joinByCode(String code);
  Future<RemoteInvite> createInvite({required String roomId, required InviteKind kind, Duration? ttl});
  Future<List<RemoteInvite>> listInvites(String roomId);
  Future<void> revokeInvite(String inviteId);
  Future<RemoteInvite> refreshInvite({required String inviteId, required String roomId,
    required InviteKind kind, Duration? ttl});
  Future<Room> setInputPermission({required String roomId, required InputPermission permission});
  Future<Room> removeMember({required String roomId, required String userId});
  Future<Room> transferOwnership({required String roomId, required String userId});
  Future<void> updateRoomDetails(Room room, {required String name,
    required String gameType, required ScoringMode scoringMode});
  Future<GameSession> createGameSession({required String roomId, required String name});
  Future<GameSession> startGameSession(String sessionId, {int? expectedVersion});
  Future<GameSession> finishGameSession(String sessionId, {int? expectedVersion});
  Future<void> manageGameSession(String sessionId, String action, {String? name, int? expectedVersion});
  Future<void> castCloseVote(Room room, bool approved,
    {RoomCloseVoteSummary? vote, RoomStatus targetStatus = RoomStatus.archived});
  Future<void> cancelCloseVote(Room room, String proposalId);
  Future<RemoteAvatarUpload> uploadAvatar(Uint8List bytes, String extension);
  Future<void> removeAvatarFile(String? key);
  Future<Room> getRoom(String roomId);
  Future<List<Room>> listMyRooms();
  Future<RoomSnapshot> getRoomSnapshot(String roomId);
  Future<Round> writeRound(RoundMutation mutation);
  Future<List<HistoryRoomSummary>> listHistoryRooms({
    int limit = 20,
    HistoryRoomSummary? before,
  });
  Future<List<HistorySessionSummary>> listHistorySessions(
    String roomId, {
    int limit = 20,
    HistorySessionSummary? before,
  });
  Future<RoomSnapshot> getHistorySession(String roomId, String sessionId);
}

class RoomChange {
  const RoomChange({required this.table, required this.payload});
  final String table;
  final Map<String, dynamic> payload;
}

abstract interface class RoomEvents {
  Stream<RoomChange> get changes;
  Stream<bool> get connectionChanges;
  Future<void> start(String roomId);
  Future<void> stop();
  Future<void> dispose();
}

abstract interface class ConnectionMonitor {
  Stream<bool> get changes;
  Future<bool> get isOnline;
  Future<void> dispose();
}
