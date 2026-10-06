import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, AuthRetryableFetchException;

import '../domain/auth_gateway.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../infrastructure/backend/supabase_auth_repository.dart';

class SupabaseAuthService implements AuthGateway {
  const SupabaseAuthService({
    required this.authRepository,
    required this.roomRepository,
  });

  final SupabaseAuthRepository authRepository;
  final RoomRepository roomRepository;

  @override
  Future<void> requestCode(String identifier) async {
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      throw const PaizhangException('手机号或邮箱不能为空');
    }
    try {
      if (_looksLikePhone(normalized)) {
        await authRepository.requestPhoneCode(normalized);
      } else {
        await authRepository.requestEmailCode(normalized);
      }
    } on AuthException catch (error) {
      throw PaizhangException(_authErrorMessage(error));
    }
  }

  @override
  Future<User> verifyCode({
    required String identifier,
    required String code,
    required String nickname,
  }) async {
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      throw const PaizhangException('手机号或邮箱不能为空');
    }
    if (code.trim().isEmpty) {
      throw const PaizhangException('验证码不能为空');
    }
    if (nickname.trim().isEmpty) {
      throw const PaizhangException('昵称不能为空');
    }

    try {
      final response = _looksLikePhone(normalized)
          ? await authRepository.verifyPhoneCode(phone: normalized, code: code)
          : await authRepository.verifyEmailCode(email: normalized, code: code);
      final authUser = response.user ?? authRepository.currentUser;
      if (authUser == null) {
        throw const PaizhangException('登录未建立有效会话');
      }

      final normalizedNickname = nickname.trim();
      await authRepository.updateNickname(normalizedNickname);
      await roomRepository.ensureCurrentUserProfile(
        nickname: normalizedNickname,
        avatarKey: _avatarKeyFrom(authUser),
        avatarUrl: _avatarUrlFrom(authUser),
      );
      return User(
        id: authUser.id,
        nickname: normalizedNickname,
        avatarKey: _avatarKeyFrom(authUser),
        avatarUrl: _avatarUrlFrom(authUser),
        phone: authUser.phone,
        email: authUser.email,
      );
    } on AuthException catch (error) {
      throw PaizhangException(_authErrorMessage(error));
    }
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const PaizhangException('账号和密码不能为空');
    }

    try {
      final response = await authRepository.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final authUser = response.session?.user;
      if (authUser == null) {
        throw const PaizhangException('登录未建立有效会话');
      }

      final metadataNickname = authUser.userMetadata?['nickname'];
      final nickname =
          metadataNickname is String && metadataNickname.trim().isNotEmpty
          ? metadataNickname.trim()
          : normalizedEmail.split('@').first;
      if (metadataNickname is! String || metadataNickname.trim().isEmpty) {
        await authRepository.updateNickname(nickname);
      }
      await roomRepository.ensureCurrentUserProfile(
        nickname: nickname,
        avatarKey: _avatarKeyFrom(authUser),
        avatarUrl: _avatarUrlFrom(authUser),
      );
    } on AuthException catch (error) {
      throw PaizhangException(_authErrorMessage(error));
    }
  }

  @override
  Future<User> registerWithPassword({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedNickname = nickname.trim();
    if (normalizedEmail.isEmpty) {
      throw const PaizhangException('账号不能为空');
    }
    if (!_isEmail(normalizedEmail)) {
      throw const PaizhangException('账号必须使用有效邮箱地址');
    }
    if (password.length < 6) {
      throw const PaizhangException('密码至少需要 6 位');
    }
    if (normalizedNickname.isEmpty) {
      throw const PaizhangException('昵称不能为空');
    }
    if (normalizedNickname.length > 40) {
      throw const PaizhangException('昵称不能超过 40 个字符');
    }

    try {
      final response = await authRepository.registerWithPassword(
        email: normalizedEmail,
        password: password,
        nickname: normalizedNickname,
      );
      final authUser = response.session?.user;
      if (authUser == null) {
        throw const PaizhangException(
          '注册未建立登录会话，请联系管理员检查邮箱确认设置；已有账号请直接登录，不要重复注册。',
        );
      }

      await roomRepository.ensureCurrentUserProfile(
        nickname: normalizedNickname,
        avatarKey: _avatarKeyFrom(authUser),
        avatarUrl: _avatarUrlFrom(authUser),
      );
      return User(
        id: authUser.id,
        nickname: normalizedNickname,
        avatarKey: _avatarKeyFrom(authUser),
        avatarUrl: _avatarUrlFrom(authUser),
        email: authUser.email,
        phone: authUser.phone,
      );
    } on AuthRetryableFetchException {
      throw const PaizhangException(
        '网络中断，注册结果未确认。请勿重复注册，可稍后直接尝试登录；若仍无法登录请联系管理员。',
      );
    } on AuthException catch (error) {
      throw PaizhangException(_authErrorMessage(error));
    }
  }

  @override
  Future<void> signOut() => authRepository.signOut();

  @override
  Future<void> updateNickname({required String nickname}) async {
    final normalized = nickname.trim();
    if (normalized.isEmpty) {
      throw const PaizhangException('昵称不能为空');
    }
    if (normalized.length > 40) {
      throw const PaizhangException('昵称不能超过 40 个字符');
    }
    try {
      await authRepository.updateNickname(normalized);
      await roomRepository.ensureCurrentUserProfile(nickname: normalized);
    } on AuthException catch (error) {
      throw PaizhangException(_authErrorMessage(error));
    }
  }

  @override
  Future<void> updateAvatar({
    required String avatarKey,
    String? avatarUrl,
    String? previousAvatarKey,
    String? previousAvatarUrl,
  }) async {
    final normalized = avatarKey.trim();
    final normalizedUrl = avatarUrl?.trim();
    if (normalized.isEmpty ||
        (normalizedUrl != null && normalizedUrl.isEmpty)) {
      throw const PaizhangException('头像信息不完整');
    }
    var authUpdated = false;
    try {
      await authRepository.updateAvatar(
        avatarKey: normalized,
        avatarUrl: normalizedUrl,
      );
      authUpdated = true;
      await roomRepository.ensureCurrentUserProfile(
        nickname: _nicknameFrom(authRepository.currentUser),
        avatarKey: normalized,
        avatarUrl: normalizedUrl,
        replaceAvatar: true,
      );
    } catch (error) {
      if (authUpdated) {
        try {
          await authRepository.updateAvatar(
            avatarKey: previousAvatarKey,
            avatarUrl: previousAvatarUrl,
          );
          await roomRepository.ensureCurrentUserProfile(
            nickname: _nicknameFrom(authRepository.currentUser),
            avatarKey: previousAvatarKey,
            avatarUrl: previousAvatarUrl,
            replaceAvatar: true,
          );
        } catch (_) {}
      }
      if (error is AuthException) {
        throw PaizhangException(_authErrorMessage(error));
      }
      rethrow;
    }
  }

  @override
  Future<void> clearAvatar({
    String? previousAvatarKey,
    String? previousAvatarUrl,
  }) async {
    var authUpdated = false;
    try {
      await authRepository.updateAvatar();
      authUpdated = true;
      await roomRepository.ensureCurrentUserProfile(
        nickname: _nicknameFrom(authRepository.currentUser),
        clearAvatar: true,
      );
    } catch (error) {
      if (authUpdated) {
        try {
          await authRepository.updateAvatar(
            avatarKey: previousAvatarKey,
            avatarUrl: previousAvatarUrl,
          );
          await roomRepository.ensureCurrentUserProfile(
            nickname: _nicknameFrom(authRepository.currentUser),
            avatarKey: previousAvatarKey,
            avatarUrl: previousAvatarUrl,
            replaceAvatar: true,
          );
        } catch (_) {}
      }
      if (error is AuthException) {
        throw PaizhangException(_authErrorMessage(error));
      }
      rethrow;
    }
  }

  @override
  User? get currentUser {
    final user = authRepository.currentUser;
    if (user == null) return null;
    return User(
      id: user.id,
      nickname: _nicknameFrom(user),
      avatarKey: _avatarKeyFrom(user),
      avatarUrl: _avatarUrlFrom(user),
      email: user.email,
      phone: user.phone,
    );
  }

  @override
  Stream<User?> get authStateChanges =>
      authRepository.authStateChanges.map((_) => currentUser);

  bool _looksLikePhone(String value) =>
      RegExp(r'^\+?[0-9][0-9\- ]{5,}$').hasMatch(value);

  bool _isEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  String _nicknameFrom(dynamic user) {
    final metadataNickname = user?.userMetadata?['nickname'];
    if (metadataNickname is String && metadataNickname.trim().isNotEmpty) {
      return metadataNickname.trim();
    }
    return user?.email?.toString().split('@').first ?? '牌友';
  }

  String? _avatarKeyFrom(dynamic user) {
    final value = user?.userMetadata?['avatar_key'];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  String? _avatarUrlFrom(dynamic user) {
    final value = user?.userMetadata?['avatar_url'];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  String _authErrorMessage(AuthException error) {
    if (error is AuthRetryableFetchException) {
      return '网络暂不可用，请检查网络后重试。';
    }
    switch (error.code) {
      case 'phone_provider_disabled':
      case 'unsupported_phone_provider':
        return '手机号登录尚未配置短信服务，请先在 Supabase 开启 Phone Provider，或改用邮箱登录。';
      case 'otp_expired':
        return '验证码或邮件链接已过期，请重新获取最新验证码，不要继续使用旧邮件。';
      case 'invalid_otp':
        return '验证码不正确，请检查最新邮件中的 6 位验证码。';
      case 'email_not_confirmed':
        return '该账号尚未完成邮箱确认，请联系管理员检查注册配置。';
      case 'invalid_credentials':
        return '账号或密码不正确。';
      case 'user_already_exists':
      case 'email_exists':
        return '该账号已注册，请直接登录。';
      case 'weak_password':
        return '密码强度不足，请使用至少 6 位密码。';
      case 'signup_disabled':
        return '当前项目暂未开放账号注册。';
      default:
        return error.message;
    }
  }
}
