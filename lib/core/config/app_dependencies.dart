import '../../features/auth/data/auth_service.dart';
import '../../features/auth/data/local_playgrid_repository.dart';
import '../../features/auth/data/mock_auth_service.dart';
import '../../features/auth/data/supabase_auth_service.dart';
import '../../features/auth/data/supabase_playgrid_repository.dart';
import '../../features/auth/domain/playgrid_repository.dart';
import 'app_config.dart';

class AppDependencies {
  const AppDependencies._();

  static late AuthService authService;
  static late PlayGridRepository repository;

  static void initialize(AppConfig config) {
    authService = config.hasSupabaseCredentials
        ? SupabaseAuthService()
        : MockAuthService();
    repository = config.hasSupabaseCredentials
        ? SupabasePlayGridRepository.fromConfig(config)
        : LocalPlayGridRepository();
  }
}
