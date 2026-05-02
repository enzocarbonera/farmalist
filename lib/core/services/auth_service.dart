import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> logout() {
    return _client.auth.signOut();
  }

  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updatePassword(String password) {
    return _client.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Session? getCurrentSession() {
    return _client.auth.currentSession;
  }
}
