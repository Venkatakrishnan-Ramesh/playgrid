import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final AppConfig config = AppConfig.fromEnvironment();
  if (config.hasSupabaseCredentials) {
    await Supabase.initialize(
      url: config.supabaseUrl!,
      anonKey: config.supabaseAnonKey!,
    );
  }
  runApp(const ProviderScope(child: PlayGridClubApp()));
}
