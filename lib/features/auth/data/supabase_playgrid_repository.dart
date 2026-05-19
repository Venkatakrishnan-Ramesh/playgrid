import '../../../core/config/app_config.dart';
import 'local_playgrid_repository.dart';

class SupabasePlayGridRepository extends LocalPlayGridRepository {
  SupabasePlayGridRepository();

  factory SupabasePlayGridRepository.fromConfig(AppConfig config) {
    return SupabasePlayGridRepository();
  }
}
