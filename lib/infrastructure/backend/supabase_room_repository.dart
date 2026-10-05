import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, FileOptions;

import '../../domain/models.dart';
import '../../domain/app_error.dart';
import '../../domain/repositories.dart';
import '../../domain/room_snapshot.dart';
import 'app_error_mapper.dart';

export '../../domain/repositories.dart' show RemoteInvite, RemoteAvatarUpload;
export '../../domain/room_snapshot.dart';

class SupabaseRoomRepository implements RoomRepository {
  SupabaseRoomRepository(this.client, {Random? random})
    : _random = random ?? Random.secure();

  final SupabaseClient client;
  final Random _random;

  @override
  String? get currentUserId => client.auth.currentUser?.id;

  @override
  Future<Round> writeRound(RoundMutation mutation) => guardRemote(() async {
    if (_requireUserId() != mutation.actorId) {
      throw const AppError(AppErrorKind.sessionChanged, '账号已切换，请重新操作');
    }
    final result = await client.rpc('upsert_round_with_scores_v2', params: {
      'p_round_id': mutation.round.id,
      'p_session_id': mutation.round.sessionId,
      'p_round_number': mutation.round.number,
      'p_note': mutation.round.note,
      'p_changes': [for (final change in mutation.round.changes)
        {'player_id': change.playerId, 'value': change.value}],
      'p_operation_id': mutation.operationId,
      'p_actor_id': mutation.actorId,
      'p_operation': mutation.operation,
      'p_expected_version': mutation.expectedVersion,
    });
    return roundFromJson(Map<String, dynamic>.from(result as Map));
  });

  Future<void> upsertProfile({
    required String userId,
    required String nickname,
    String? avatarKey,
    String? avatarUrl,
    String? phone,
    String? email,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'nickname': nickname.trim(),
      'avatar_key': avatarKey,
      'avatar_url': avatarUrl,
      'phone': phone,
      'email': email,
    });
  }

  @override
  Future<void> ensureCurrentUserProfile({
    required String nickname,
    String? avatarKey,
    String? avatarUrl,
    bool clearAvatar = false,
    bool replaceAvatar = false,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw const PaizhangException('请先登录');

    Map<String, dynamic>? existingProfile;
    if (!clearAvatar &&
        !replaceAvatar &&
        avatarKey == null &&
        avatarUrl == null) {
      existingProfile = await client
          .from('profiles')
          .select('avatar_key, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
    }
    final metadataAvatarKey = user.userMetadata?['avatar_key'];
    final metadataAvatarUrl = user.userMetadata?['avatar_url'];
    await upsertProfile(
      userId: user.id,
      nickname: nickname,
      avatarKey: clearAvatar
          ? null
          : replaceAvatar
          ? avatarKey
          : avatarKey ??
                (metadataAvatarKey is String ? metadataAvatarKey : null) ??
                existingProfile?['avatar_key'] as String?,
      avatarUrl: clearAvatar
          ? null
          : replaceAvatar
          ? avatarUrl
          : avatarUrl ??
                (metadataAvatarUrl is String ? metadataAvatarUrl : null) ??
                existingProfile?['avatar_url'] as String?,
      phone: user.phone,
      email: user.email,
    );
  }

  @override
  Future<Room> createRoom({
    required String name,
    required String gameType,
    required ScoringMode scoringMode,
  }) async {
    _requireUserId();
    final roomId = await client.rpc(
      'create_room',
      params: {
        'p_name': name.trim(),
        'p_game_type': gameType.trim(),
        'p_scoring_mode': scoringMode.name,
      },
    ) as String;
    return getRoom(roomId);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    await client.rpc('leave_room', params: {'target_room_id': roomId});
  }

  @override
  Future<RemoteInvite> createInvite({
    required String roomId,
    required InviteKind kind,
    Duration? ttl,
  }) async {
    final token = _randomToken();
    final code = _randomCode();
    final expiresAt = ttl == null ? null : DateTime.now().toUtc().add(ttl);
    final row = await client
        .from('invite_tokens')
        .insert({
          'room_id': roomId,
          'token_hash': _hash(token),
          'invite_code': code,
          'kind': kind.name,
          'expires_at': expiresAt?.toIso8601String(),
        })
        .select()
        .single();
    return RemoteInvite(
      id: row['id'] as String,
      roomId: row['room_id'] as String,
      token: token,
      code: row['invite_code'] as String,
      kind: kind,
      expiresAt: expiresAt,
      createdAt: _dateTimeOrNull(row['created_at']),
      revokedAt: _dateTimeOrNull(row['revoked_at']),
    );
  }

  @override
  Future<List<RemoteInvite>> listInvites(String roomId) async {
    final rows = await client
        .from('invite_tokens')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: false);
    return rows.map<RemoteInvite>(_inviteFromRow).toList();
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    await client.rpc(
      'revoke_room_invite',
      params: {'target_invite_id': inviteId},
    );
  }

  @override
  Future<RemoteInvite> refreshInvite({
    required String inviteId,
    required String roomId,
    required InviteKind kind,
    Duration? ttl,
  }) async {
    final token = _randomToken();
    final code = _randomCode();
    final expiresAt = ttl == null ? null : DateTime.now().toUtc().add(ttl);
    final newInviteId = await client.rpc(
      'refresh_room_invite',
      params: {
        'target_invite_id': inviteId,
        'p_token_hash': _hash(token),
        'p_invite_code': code,
        'p_kind': kind.name,
        'p_expires_at': expiresAt?.toIso8601String(),
      },
    ) as String;
    return RemoteInvite(
      id: newInviteId,
      roomId: roomId,
      token: token,
      code: code,
      kind: kind,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Room> setInputPermission({
    required String roomId,
    required InputPermission permission,
  }) async {
    await client.rpc(
      'set_room_input_permission',
      params: {'target_room_id': roomId, 'p_input_permission': permission.name},
    );
    return getRoom(roomId);
  }

  @override
  Future<Room> removeMember({
    required String roomId,
    required String userId,
  }) async {
    await client.rpc(
      'remove_room_member',
      params: {'target_room_id': roomId, 'target_user_id': userId},
    );
    return getRoom(roomId);
  }

  @override
  Future<Room> transferOwnership({
    required String roomId,
    required String userId,
  }) async {
    await client.rpc(
      'transfer_room_ownership',
      params: {'target_room_id': roomId, 'new_owner_id': userId},
    );
    return getRoom(roomId);
  }

  @override
  Future<String> joinByToken(String token) async {
    final result = await client.rpc(
      'join_room_by_invite',
      params: {'p_token_hash': _hash(token)},
    );
    return result as String;
  }

  @override
  Future<String> joinByCode(String code) async {
    final result = await client.rpc(
      'join_room_by_invite_code',
      params: {'p_invite_code': code.trim().toUpperCase()},
    );
    return result as String;
  }

  @override
  Future<Room> getRoom(String roomId) async {
    final row = await client
        .from('rooms')
        .select('*, room_members(*)')
        .eq('id', roomId)
        .single();
    return _roomFromRow(row);
  }

  @override
  Future<List<Room>> listMyRooms() async {
    final rows = await client
        .from('rooms')
        .select('*, room_members(*), mine:room_members!inner(user_id, left_at)')
        .eq('mine.user_id', _requireUserId())
        .isFilter('mine.left_at', null)
        .order('updated_at', ascending: false);
    return rows.map<Room>(_roomFromRow).toList();
  }

  @override
  Future<RoomSnapshot> getRoomSnapshot(String roomId) => guardRemote(() async {
    final initial = await Future.wait<Object>([getRoom(roomId), listGameSessions(roomId)]);
    final room = initial[0] as Room;
    final sessions = initial[1] as List<GameSession>;
    final values = await Future.wait<dynamic>([
      listRoundsForSessions(sessions.map((session) => session.id)),
      _listMemberProfiles(room.members),
      getCloseVote(room),
    ]);
    return RoomSnapshot(
      room: room,
      sessions: List.unmodifiable(sessions),
      rounds: List.unmodifiable(values[0] as List<Round>),
      profiles: Map.unmodifiable(values[1] as Map<String, User>),
      closeVote: values[2] as RoomCloseVoteSummary?,
    );
  });

  Future<Map<String, User>> _listMemberProfiles(
    Iterable<RoomMember> members,
  ) async {
    final userIds = members.map((member) => member.userId).toSet().toList();
    if (userIds.isEmpty) return {};
    final rows = await client
        .from('profiles')
        .select('id, nickname, avatar_key, avatar_url')
        .inFilter('id', userIds);
    return {
      for (final row in rows)
        row['id'] as String: User(
          id: row['id'] as String,
          nickname: row['nickname'] as String,
          avatarKey: row['avatar_key'] as String?,
          avatarUrl: row['avatar_url'] as String?,
        ),
    };
  }

  @override
  Future<GameSession> createGameSession({
    required String roomId,
    required String name,
  }) async {
    final sessionId = await client.rpc(
      'create_game_draft',
      params: {'target_room_id': roomId, 'p_name': name.trim()},
    );
    return _getGameSession(sessionId as String);
  }

  @override
  Future<GameSession> startGameSession(
    String sessionId, {
    int? expectedVersion,
  }) async {
    await manageGameSession(
      sessionId,
      'start',
      expectedVersion: expectedVersion,
    );
    return _getGameSession(sessionId);
  }

  @override
  Future<GameSession> finishGameSession(
    String sessionId, {
    int? expectedVersion,
  }) async {
    await manageGameSession(
      sessionId,
      'finish',
      expectedVersion: expectedVersion,
    );
    return _getGameSession(sessionId);
  }

  @override
  Future<void> manageGameSession(
    String sessionId,
    String action, {
    String? name,
    int? expectedVersion,
  }) async {
    await client.rpc(
      'manage_game_session',
      params: {
        'p_session_id': sessionId,
        'p_action': action,
        'p_name': name,
        'p_expected_version': expectedVersion,
      },
    );
  }

  Future<GameSession> _getGameSession(String sessionId) async {
    final row = await client
        .from('game_sessions')
        .select()
        .eq('id', sessionId)
        .single();
    return _gameSessionFromRow(row);
  }

  @override
  Future<void> updateRoomDetails(
    Room room, {
    required String name,
    required String gameType,
    required ScoringMode scoringMode,
  }) async {
    await client.rpc(
      'update_room_details',
      params: {
        'target_room_id': room.id,
        'p_name': name.trim(),
        'p_game_type': gameType.trim(),
        'p_scoring_mode': scoringMode.name,
        'p_expected_version': room.version,
      },
    );
  }

  Future<RoomCloseVoteSummary?> getCloseVote(Room room) async {
    final proposals = await client
        .from('room_close_proposals')
        .select('*, room_close_votes(*)')
        .eq('room_id', room.id)
        .eq('status', room.isClosed ? 'passed' : 'pending')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(1);
    if (proposals.isEmpty) {
      return null;
    }
    final proposal = proposals.first;
    final votes = (proposal['room_close_votes'] as List)
        .cast<Map<String, dynamic>>();
    final mine = votes.where((vote) => vote['user_id'] == _requireUserId());
    return RoomCloseVoteSummary(
      activeMemberCount: room.members.where((member) => member.isActive).length,
      approvedCount: votes.where((vote) => vote['approved'] == true).length,
      currentUserApproved: mine.isEmpty
          ? null
          : mine.first['approved'] as bool?,
      proposalId: proposal['id'] as String,
      targetStatus: RoomStatus.values.byName(
        proposal['target_status'] as String,
      ),
      expiresAt: DateTime.parse(proposal['expires_at'] as String).toLocal(),
      createdBy: proposal['created_by'] as String,
    );
  }

  @override
  Future<void> castCloseVote(
    Room room,
    bool approved, {
    RoomCloseVoteSummary? vote,
    RoomStatus targetStatus = RoomStatus.archived,
  }) async {
    await client.rpc(
      'cast_room_close_vote',
      params: {
        'target_room_id': room.id,
        'p_approved': approved,
        'p_target_status':
            (vote?.proposalId != null ? vote!.targetStatus : targetStatus).name,
        'p_proposal_id': vote?.proposalId,
      },
    );
  }

  @override
  Future<void> cancelCloseVote(Room room, String proposalId) async {
    await client.rpc(
      'cancel_room_close_vote',
      params: {'target_room_id': room.id, 'p_proposal_id': proposalId},
    );
  }

  @override
  Future<List<HistoryRoomSummary>> listHistoryRooms({
    int limit = 20, HistoryRoomSummary? before,
  }) => guardRemote(() async {
    final rows = await client.rpc('get_room_history_page', params: {
      'p_limit': limit,
      'p_before_at': before?.lastActivityAt.toUtc().toIso8601String(),
      'p_before_id': before?.roomId,
    }) as List;
    return [for (final row in rows) HistoryRoomSummary(
      roomId: row['room_id'] as String, name: row['room_name'] as String,
      gameType: row['game_type'] as String,
      scoringMode: ScoringMode.values.byName(row['scoring_mode'] as String),
      isCurrentMember: row['is_current_member'] as bool,
      sessionCount: (row['session_count'] as num).toInt(),
      lastActivityAt: DateTime.parse(row['last_activity_at'] as String),
    )];
  });

  @override
  Future<List<HistorySessionSummary>> listHistorySessions(String roomId, {
    int limit = 20, HistorySessionSummary? before,
  }) => guardRemote(() async {
    final rows = await client.rpc('get_room_history_sessions', params: {
      'p_room_id': roomId, 'p_limit': limit,
      'p_before_at': before?.lastActivityAt.toUtc().toIso8601String(),
      'p_before_id': before?.session.id,
    }) as List;
    return [for (final row in rows) HistorySessionSummary(
      session: _gameSessionFromRow(Map<String, dynamic>.from(row as Map)),
      roundCount: (row['round_count'] as num).toInt(),
      lastActivityAt: DateTime.parse(row['last_activity_at'] as String),
    )];
  });

  @override
  Future<RoomSnapshot> getHistorySession(String roomId, String sessionId) =>
      guardRemote(() async {
    final rounds = <String, Round>{};
    Map<String, dynamic>? data;
    int? afterNumber;
    String? afterId;
    while (true) {
      data = Map<String, dynamic>.from(await client.rpc(
        'get_room_history_snapshot', params: {
          'p_room_id': roomId, 'p_session_id': sessionId, 'p_limit': 500,
          'p_after_number': afterNumber, 'p_after_id': afterId,
        }) as Map);
      for (final value in data['rounds'] as List) {
        final round = roundFromJson(Map<String, dynamic>.from(value as Map));
        rounds[round.id] = round;
      }
      if (data['has_more'] != true) break;
      final nextNumber = (data['next_number'] as num).toInt();
      final nextId = data['next_id'] as String;
      if (nextNumber == afterNumber && nextId == afterId) {
        throw const AppError(AppErrorKind.unknown, '历史分页未前进，请重新加载');
      }
      afterNumber = nextNumber;
      afterId = nextId;
    }
    return RoomSnapshot(
      room: _roomFromRow(Map<String, dynamic>.from(data['room'] as Map)),
      sessions: [for (final value in data['sessions'] as List)
        _gameSessionFromRow(Map<String, dynamic>.from(value as Map))],
      rounds: List.unmodifiable(rounds.values),
      profiles: {for (final profile in data['profiles'] as List)
        profile['id'] as String: User(id: profile['id'] as String,
          nickname: profile['nickname'] as String,
          avatarKey: profile['avatar_key'] as String?,
          avatarUrl: profile['avatar_url'] as String?)},
    );
  });

  @override
  Future<RemoteAvatarUpload> uploadAvatar(
    Uint8List bytes,
    String extension,
  ) async {
    if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension) ||
        bytes.length > 2 * 1024 * 1024 ||
        bytes.isEmpty) {
      throw const PaizhangException('请选择 2MB 以内的 JPG、PNG 或 WebP 图片');
    }
    final path = '${_requireUserId()}/${_randomUuid()}.$extension';
    await client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: extension == 'jpg' ? 'image/jpeg' : 'image/$extension',
          ),
        );
    return RemoteAvatarUpload(
      key: path,
      url: client.storage.from('avatars').getPublicUrl(path),
    );
  }

  @override
  Future<void> removeAvatarFile(String? key) async {
    if (key == null || key.startsWith('preset:')) return;
    final userId = _requireUserId();
    if (!key.startsWith('$userId/')) return;
    await client.storage.from('avatars').remove([key]);
  }

  Future<List<GameSession>> listGameSessions(String roomId) async {
    final rows = await client
        .from('game_sessions')
        .select()
        .eq('room_id', roomId)
        .order('updated_at', ascending: false);
    return rows.map<GameSession>(_gameSessionFromRow).toList();
  }

  Future<List<Round>> listRounds(String sessionId) async {
    return listRoundsForSessions([sessionId]);
  }

  Future<List<Round>> listRoundsForSessions(Iterable<String> sessionIds) async {
    final ids = sessionIds.toSet().toList();
    if (ids.isEmpty) return const [];
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    Map<String, dynamic>? after;
    while (true) {
      var query = client.from('rounds').select('*, score_changes(*)')
          .inFilter('session_id', ids);
      if (after != null) {
        final session = after['session_id'] as String;
        final number = (after['round_number'] as num).toInt();
        final id = after['id'] as String;
        query = query.or('session_id.gt.$session,'
            'and(session_id.eq.$session,round_number.gt.$number),'
            'and(session_id.eq.$session,round_number.eq.$number,id.gt.$id)');
      }
      final page = await query.order('session_id', ascending: true)
          .order('round_number', ascending: true)
          .order('id', ascending: true).limit(pageSize);
      final typedPage = page.cast<Map<String, dynamic>>();
      rows.addAll(typedPage);
      if (typedPage.length < pageSize) break;
      after = typedPage.last;
    }
    return rows.map<Round>(_roundFromRow).toList();
  }

  String _requireUserId() {
    final userId = currentUserId;
    if (userId == null) throw const PaizhangException('请先登录');
    return userId;
  }

  Room _roomFromRow(Map<String, dynamic> row) {
    final rawMembers = row['room_members'] as List<dynamic>? ?? const [];
    final members = rawMembers.map((item) {
      final member = item as Map<String, dynamic>;
      return RoomMember(
        userId: member['user_id'] as String,
        role: RoomRole.values.byName(member['role'] as String),
        inputPermission: InputPermission.values.byName(
          member['input_permission'] as String,
        ),
        joinedAt: DateTime.parse(member['joined_at'] as String).toLocal(),
        leftAt: member['left_at'] == null
            ? null
            : DateTime.parse(member['left_at'] as String).toLocal(),
      );
    }).toList();
    return Room(
      id: row['id'] as String,
      name: row['name'] as String,
      ownerId: row['owner_id'] as String,
      gameType: row['game_type'] as String,
      scoringMode: ScoringMode.values.byName(row['scoring_mode'] as String),
      status: RoomStatus.values.byName(row['status'] as String),
      inputPermission: InputPermission.values.byName(
        row['input_permission'] as String,
      ),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      members: List.unmodifiable(members),
      version: (row['version'] as num?)?.toInt() ?? 1,
    );
  }

  RemoteInvite _inviteFromRow(Map<String, dynamic> row) {
    return RemoteInvite(
      id: row['id'] as String,
      roomId: row['room_id'] as String,
      token: '',
      code: row['invite_code'] as String? ?? '',
      kind: InviteKind.values.byName(row['kind'] as String),
      expiresAt: _dateTimeOrNull(row['expires_at']),
      createdAt: _dateTimeOrNull(row['created_at']),
      revokedAt: _dateTimeOrNull(row['revoked_at']),
    );
  }

  DateTime? _dateTimeOrNull(Object? value) {
    if (value is! String) return null;
    return DateTime.parse(value).toLocal();
  }

  GameSession _gameSessionFromRow(Map<String, dynamic> row) {
    return GameSession(
      id: row['id'] as String,
      roomId: row['room_id'] as String,
      name: row['name'] as String,
      status: GameSessionStatus.values.byName(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      startedAt: row['started_at'] == null
          ? null
          : DateTime.parse(row['started_at'] as String).toLocal(),
      finishedAt: row['finished_at'] == null
          ? null
          : DateTime.parse(row['finished_at'] as String).toLocal(),
      version: (row['version'] as num?)?.toInt() ?? 1,
    );
  }

  Round _roundFromRow(Map<String, dynamic> row) {
    final rawChanges = row['score_changes'] as List<dynamic>? ?? const [];
    final changes = rawChanges.map((item) {
      if (item is ScoreChange) return item;
      final change = item as Map<String, dynamic>;
      return ScoreChange(
        playerId: change['player_id'] as String,
        value: change['value'] as int,
      );
    }).toList();
    return Round(
      id: row['id'] as String,
      sessionId: row['session_id'] as String,
      number: row['round_number'] as int,
      changes: List.unmodifiable(changes),
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      note: row['note'] as String?,
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String).toLocal(),
      version: (row['version'] as num?)?.toInt() ?? 1,
    );
  }

  String _randomToken() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _randomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();

  String _randomUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

}
