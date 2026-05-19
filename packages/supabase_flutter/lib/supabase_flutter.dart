library supabase_flutter;

class SupabaseOptions {
  const SupabaseOptions({
    required this.url,
    required this.anonKey,
  });

  final String url;
  final String anonKey;
}

class SupabaseClient {
  const SupabaseClient(this.options);

  final SupabaseOptions options;
}

class Supabase {
  Supabase._(this.client);

  static Supabase? _instance;

  final SupabaseClient client;

  static Future<Supabase> initialize({
    required String url,
    required String anonKey,
  }) async {
    final instance = Supabase._(
      SupabaseClient(
        SupabaseOptions(url: url, anonKey: anonKey),
      ),
    );
    _instance = instance;
    return instance;
  }

  static Supabase get instance {
    final current = _instance;
    if (current == null) {
      throw StateError('Supabase has not been initialized.');
    }
    return current;
  }
}
