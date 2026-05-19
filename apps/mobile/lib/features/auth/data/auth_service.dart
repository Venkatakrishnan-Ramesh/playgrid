import '../../../shared/models/playgrid_models.dart';

abstract class AuthService {
  Future<PlayGridSession> currentSession();

  Future<PlayGridSession> signIn({
    required String email,
    required String password,
  });

  Future<PlayGridSession> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset({required String email});

  Future<void> signOut();
}
