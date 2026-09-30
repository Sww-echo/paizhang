import '../domain/models.dart';
import 'paizhang_service.dart';

class AuthService {
  AuthService({Clock? clock, IdFactory? idFactory})
    : _clock = clock ?? DateTime.now,
      _idFactory = idFactory ?? _defaultAuthIdFactory;

  final Clock _clock;
  final IdFactory _idFactory;
  final Map<String, AuthChallenge> _challenges = {};
  final Map<String, User> _usersByIdentifier = {};
  final Map<String, AuthSession> _sessions = {};

  AuthChallenge requestCode({required String identifier, Duration? ttl}) {
    final normalized = identifier.trim().toLowerCase();
    if (normalized.isEmpty) throw const PaizhangException('手机号或邮箱不能为空');
    final now = _clock();
    final challenge = AuthChallenge(
      id: _idFactory('challenge'),
      identifier: normalized,
      verificationCode: '123456',
      createdAt: now,
      expiresAt: now.add(ttl ?? const Duration(minutes: 5)),
    );
    _challenges[challenge.id] = challenge;
    return challenge;
  }

  AuthSession verifyCode({
    required String challengeId,
    required String code,
    required String nickname,
  }) {
    final challenge = _challenges[challengeId];
    if (challenge == null || !challenge.isValidAt(_clock())) {
      throw const PaizhangException('验证码已失效');
    }
    if (challenge.verificationCode != code.trim()) {
      throw const PaizhangException('验证码错误');
    }
    if (nickname.trim().isEmpty) {
      throw const PaizhangException('昵称不能为空');
    }

    final user = _usersByIdentifier.putIfAbsent(
      challenge.identifier,
      () => User(
        id: _idFactory('user'),
        nickname: nickname.trim(),
        phone: _looksLikePhone(challenge.identifier)
            ? challenge.identifier
            : null,
        email: _looksLikePhone(challenge.identifier)
            ? null
            : challenge.identifier,
      ),
    );
    final now = _clock();
    final session = AuthSession(
      token: _idFactory('session'),
      userId: user.id,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
    );
    _sessions[session.token] = session;
    _challenges.remove(challengeId);
    return session;
  }

  User userForSession(String token) {
    final session = _sessions[token];
    if (session == null || !session.isValidAt(_clock())) {
      throw const PaizhangException('登录已失效');
    }
    final user = _usersByIdentifier.values.firstWhere(
      (candidate) => candidate.id == session.userId,
      orElse: () => throw const PaizhangException('用户不存在'),
    );
    return user;
  }

  void revokeSession(String token) => _sessions.remove(token);
}

bool _looksLikePhone(String identifier) =>
    RegExp(r'^\+?[0-9\- ]+$').hasMatch(identifier);

String _defaultAuthIdFactory(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}';
