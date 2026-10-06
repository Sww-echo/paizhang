import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository {
  const SupabaseAuthRepository(this.client);

  final SupabaseClient client;

  Future<void> requestEmailCode(String email) {
    return client.auth.signInWithOtp(email: email.trim().toLowerCase());
  }

  Future<void> requestPhoneCode(String phone) {
    return client.auth.signInWithOtp(phone: phone.trim());
  }

  Future<AuthResponse> verifyEmailCode({
    required String email,
    required String code,
  }) {
    return client.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: code.trim(),
      type: OtpType.email,
    );
  }

  Future<AuthResponse> verifyPhoneCode({
    required String phone,
    required String code,
  }) {
    return client.auth.verifyOTP(
      phone: phone.trim(),
      token: code.trim(),
      type: OtpType.sms,
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<AuthResponse> registerWithPassword({
    required String email,
    required String password,
    required String nickname,
  }) {
    return client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'nickname': nickname.trim()},
    );
  }

  Future<UserResponse> updateNickname(String nickname) {
    return client.auth.updateUser(
      UserAttributes(data: {'nickname': nickname.trim()}),
    );
  }

  Future<UserResponse> updateAvatar({String? avatarKey, String? avatarUrl}) {
    return client.auth.updateUser(
      UserAttributes(
        data: {
          'avatar_key': avatarKey?.trim(),
          'avatar_url': avatarUrl?.trim(),
        },
      ),
    );
  }

  Future<void> signOut() => client.auth.signOut();

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
