import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models.dart';

class RemoteInvite {
  const RemoteInvite({
    required this.id,
    required this.roomId,
    required this.token,
    required this.code,
    required this.kind,
    required this.expiresAt,
  });

  final String id;
  final String roomId;
  final String token;
  final String code;
  final InviteKind kind;
  final DateTime? expiresAt;

  String get shareLink => 'https://paizhang.app/join/$token';
}

class RemoteRoomSnapshot {
  const RemoteRoomSnapshot({
    required this.room,
    required this.sessions,
    required this.rounds,
  });

  final Room room;
  final List<GameSession> sessions;
  final List<Round> rounds;
}

class SupabaseRoomRepository {
  SupabaseRoomRepository(this.client, {Random? random})
    : _random = random ?? Random.secure();

  final SupabaseClient client;
  final Random _random;

  Future<void> upsertProfile({
    required String userId,
    required String nickname,
    String? phone,
    String? email,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'nickname': nickname.trim(),
      'phone': phone,
      'email': email,
    });
  }

  Future<void> ensureCurrentUserProfile({required String nickname}) async {
    final user = client.auth.currentUser;
    if (user == null) throw const PaizhangException('请先登录');
    await upsertProfile(
      userId: user.id,
      nickname: nickname,
      phone: user.phone,
      email: user.email,
    );
  }

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

  Future<void> leaveRoom(String roomId) async {
    await client.rpc('leave_room', params: {'target_room_id': roomId});
  }

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
    );
  }

  Future<String> joinByToken(String token) async {
    final result = await client.rpc(
      'join_room_by_invite',
      params: {'p_token_hash': _hash(token)},
    );
    return result as String;
  }

  Future<String> joinByCode(String code) async {
    final result = await client.rpc(
      'join_room_by_invite_code',
      params: {'p_invite_code': code.trim().toUpperCase()},
    );
    return result as String;
  }

  Future<Room> getRoom(String roomId) async {
    final row = await client
        .from('rooms')
        .select('*, room_members(*)')
        .eq('id', roomId)
        .single();
    return _roomFromRow(row);
  }

  Future<List<Room>> listMyRooms() async {
    final rows = await client
        .from('rooms')
        .select('*, room_members!inner(*)')
        .eq('room_members.user_id', _requireUserId())
        .isFilter('room_members.left_at', null)
        .order('updated_at', ascending: false);
    return rows.map<Room>(_roomFromRow).toList();
  }

  Future<RemoteRoomSnapshot> getRoomSnapshot(String roomId) async {
    final room = await getRoom(roomId);
    final sessions = await listGameSessions(roomId);
    final rounds = <Round>[];
    for (final session in sessions) {
      rounds.addAll(await listRounds(session.id));
    }
    return RemoteRoomSnapshot(
      room: room,
      sessions: List.unmodifiable(sessions),
      rounds: List.unmodifiable(rounds),
    );
  }

  Future<GameSession> createGameSession({
    required String roomId,
    required String name,
  }) async {
    final row = await client
        .from('game_sessions')
        .insert({'room_id': roomId, 'name': name.trim(), 'status': 'draft'})
        .select()
        .single();
    return _gameSessionFromRow(row);
  }

  Future<GameSession> startGameSession(String sessionId) async {
    final row = await client
        .from('game_sessions')
        .update({
          'status': 'active',
          'started_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId)
        .select()
        .single();
    return _gameSessionFromRow(row);
  }

  Future<GameSession> finishGameSession(String sessionId) async {
    final row = await client
        .from('game_sessions')
        .update({
          'status': 'finished',
          'finished_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId)
        .select()
        .single();
    return _gameSessionFromRow(row);
  }

  Future<List<GameSession>> listGameSessions(String roomId) async {
    final rows = await client
        .from('game_sessions')
        .select()
        .eq('room_id', roomId)
        .order('updated_at', ascending: false);
    return rows.map<GameSession>(_gameSessionFromRow).toList();
  }

  Future<Round> recordRound({
    required String sessionId,
    required int roundNumber,
    required List<ScoreChange> changes,
    String? note,
  }) async {
    final createdBy = _requireUserId();
    final round = await client
        .from('rounds')
        .insert({
          'session_id': sessionId,
          'round_number': roundNumber,
          'created_by': createdBy,
          'note': note,
        })
        .select()
        .single();
    try {
      await client
          .from('score_changes')
          .insert(
            changes
                .map(
                  (change) => {
                    'round_id': round['id'],
                    'player_id': change.playerId,
                    'created_by': createdBy,
                    'value': change.value,
                  },
                )
                .toList(),
          );
    } catch (_) {
      await client.from('rounds').delete().eq('id', round['id']);
      rethrow;
    }
    return _roundFromRow({...round, 'score_changes': changes});
  }

  Future<List<Round>> listRounds(String sessionId) async {
    final rows = await client
        .from('rounds')
        .select('*, score_changes(*)')
        .eq('session_id', sessionId)
        .order('round_number');
    return rows.map<Round>(_roundFromRow).toList();
  }

  String _requireUserId() {
    final userId = client.auth.currentUser?.id;
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
    );
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
}
