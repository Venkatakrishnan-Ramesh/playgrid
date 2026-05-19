import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/playgrid_controller.dart';
import '../config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((Ref ref) => AppConfig.fromEnvironment());
final playGridBackendServiceProvider = playGridControllerProvider;
