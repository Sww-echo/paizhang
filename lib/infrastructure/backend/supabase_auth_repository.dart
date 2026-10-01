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

  Future<void> signOut() => client.auth.signOut();

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
