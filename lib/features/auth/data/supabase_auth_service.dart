import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/errors/app_failure.dart';
import '../../../shared/models/playgrid_models.dart';
import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService({sb.SupabaseClient? client})
      : _client = client ?? sb.Supabase.instance.client;

  final sb.SupabaseClient _client;

  @override
  Future<PlayGridSession> currentSession() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const PlayGridSession.guest();
    }
    return _sessionFor(user);
  }

  @override
  Future<PlayGridSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AppFailure('Sign in did not return a user.');
      }
      return _sessionFor(user);
    } on sb.AuthException catch (error) {
      throw AppFailure(error.message);
    }
  }

  @override
  Future<PlayGridSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{'name': name.trim()},
      );
      final user = response.user;
      if (user == null) {
        throw const AppFailure(
            'Confirm your email to finish creating the account.');
      }
      return _sessionFor(user);
    } on sb.AuthException catch (error) {
      throw AppFailure(error.message);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on sb.AuthException catch (error) {
      throw AppFailure(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<PlayGridSession> _sessionFor(sb.User user) async {
    final profile = await _client
        .from('profiles')
        .select('role, name, department')
        .eq('id', user.id)
        .maybeSingle();

    final role = _parseRole(profile?['role'] as String?);
    final profileComplete = profile != null &&
        ((profile['name'] as String?)?.trim().isNotEmpty ?? false) &&
        ((profile['department'] as String?)?.trim().isNotEmpty ?? false);

    return PlayGridSession(
      userId: user.id,
      email: user.email ?? '',
      isAuthenticated: true,
      profileComplete: profileComplete,
      role: role,
    );
  }

  static UserRole _parseRole(String? raw) {
    return switch (raw) {
      'admin' => UserRole.admin,
      'super_admin' => UserRole.superAdmin,
      _ => UserRole.member,
    };
  }
}
