import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../domain/models.dart';
import '../infrastructure/backend/supabase_auth_repository.dart';
import '../infrastructure/backend/supabase_room_repository.dart';

class SupabaseAuthService {
  const SupabaseAuthService({
    required this.authRepository,
    required this.roomRepository,
  });

  final SupabaseAuthRepository authRepository;
  final SupabaseRoomRepository roomRepository;

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

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const PaizhangException('测试账号信息不完整');
    }

    try {
      final response = await authRepository.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final authUser = response.user ?? authRepository.currentUser;
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

  Future<void> signOut() => authRepository.signOut();

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

  Stream<dynamic> get authStateChanges => authRepository.authStateChanges;

  bool _looksLikePhone(String value) =>
      RegExp(r'^\+?[0-9][0-9\- ]{5,}$').hasMatch(value);

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
    switch (error.code) {
      case 'phone_provider_disabled':
      case 'unsupported_phone_provider':
        return '手机号登录尚未配置短信服务，请先在 Supabase 开启 Phone Provider，或改用邮箱登录。';
      case 'otp_expired':
        return '验证码或邮件链接已过期，请重新获取最新验证码，不要继续使用旧邮件。';
      case 'invalid_otp':
        return '验证码不正确，请检查最新邮件中的 6 位验证码。';
      case 'email_not_confirmed':
        return '邮箱还未验证，请先完成最新邮件中的验证。';
      case 'invalid_credentials':
        return '测试账号或密码不正确。';
      default:
        return error.message;
    }
  }
}
