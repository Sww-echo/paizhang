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
    if (_looksLikePhone(normalized)) {
      await authRepository.requestPhoneCode(normalized);
    } else {
      await authRepository.requestEmailCode(normalized);
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

    final response = _looksLikePhone(normalized)
        ? await authRepository.verifyPhoneCode(phone: normalized, code: code)
        : await authRepository.verifyEmailCode(email: normalized, code: code);
    final authUser = response.user ?? authRepository.currentUser;
    if (authUser == null) {
      throw const PaizhangException('登录未建立有效会话');
    }

    await roomRepository.ensureCurrentUserProfile(nickname: nickname);
    return User(
      id: authUser.id,
      nickname: nickname.trim(),
      phone: authUser.phone,
      email: authUser.email,
    );
  }

  Future<void> signOut() => authRepository.signOut();

  Stream<dynamic> get authStateChanges => authRepository.authStateChanges;

  bool _looksLikePhone(String value) =>
      RegExp(r'^\+?[0-9][0-9\- ]{5,}$').hasMatch(value);
}
