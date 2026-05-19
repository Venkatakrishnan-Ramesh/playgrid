import '../../../shared/models/playgrid_mock_data.dart';
import '../../../shared/models/playgrid_models.dart';
import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService();

  PlayGridSession _session = PlayGridMockData.guestSession;

  @override
  Future<PlayGridSession> currentSession() async => _session;

  @override
  Future<PlayGridSession> signIn({
    required String email,
    required String password,
  }) async {
    _session = PlayGridMockData.memberSession.copyWith(email: email.trim());
    return _session;
  }

  @override
  Future<PlayGridSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _session = PlayGridSession(
      userId: 'supabase-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      isAuthenticated: true,
      profileComplete: false,
      role: UserRole.member,
    );
    return _session;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> signOut() async {
    _session = PlayGridMockData.guestSession;
  }
}
