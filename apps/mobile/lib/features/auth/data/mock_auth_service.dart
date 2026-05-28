import '../../../core/errors/app_failure.dart';
import '../../../shared/models/playgrid_mock_data.dart';
import '../../../shared/models/playgrid_models.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  MockAuthService({
    PlayGridSession? initialSession,
  }) : _session = initialSession ?? PlayGridMockData.guestSession;

  PlayGridSession _session;

  @override
  Future<PlayGridSession> currentSession() async => _session;

  @override
  Future<PlayGridSession> signIn({
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || password.trim().length < 6) {
      throw const AppFailure('Enter valid credentials to continue.');
    }
    for (final ({String email, String userId, UserRole role, String name}) acc
        in PlayGridMockData.knownAccounts) {
      if (acc.email.toLowerCase() == normalized) {
        _session = PlayGridSession(
          userId: acc.userId,
          email: acc.email,
          isAuthenticated: true,
          profileComplete: true,
          role: acc.role,
        );
        return _session;
      }
    }
    _session = PlayGridMockData.memberSession.copyWith(email: email.trim());
    return _session;
  }

  @override
  Future<PlayGridSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().length < 6) {
      throw const AppFailure('Complete the signup form with valid data.');
    }
    _session = PlayGridSession(
      userId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      isAuthenticated: true,
      profileComplete: false,
      role: UserRole.member,
    );
    return _session;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    if (email.trim().isEmpty) {
      throw const AppFailure('Provide an email address.');
    }
  }

  @override
  Future<void> signOut() async {
    _session = PlayGridMockData.guestSession;
  }
}
