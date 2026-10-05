import 'models.dart';

abstract interface class AuthGateway {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<void> requestCode(String identifier);
  Future<User> verifyCode({
    required String identifier,
    required String code,
    required String nickname,
  });
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> updateNickname({required String nickname});
  Future<void> updateAvatar({
    required String avatarKey,
    String? avatarUrl,
    String? previousAvatarKey,
    String? previousAvatarUrl,
  });
  Future<void> clearAvatar({
    String? previousAvatarKey,
    String? previousAvatarUrl,
  });
}
