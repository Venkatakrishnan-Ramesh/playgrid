class AppConfig {
  const AppConfig({
    required this.appName,
    required this.packageName,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String appName;
  final String packageName;
  final String? supabaseUrl;
  final String? supabaseAnonKey;

  bool get hasSupabaseCredentials =>
      supabaseUrl != null && supabaseUrl!.isNotEmpty && supabaseAnonKey != null && supabaseAnonKey!.isNotEmpty;

  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    return AppConfig(
      appName: 'PlayGrid Club',
      packageName: 'com.venkat.playgridclub',
      supabaseUrl: url.isEmpty ? null : url,
      supabaseAnonKey: key.isEmpty ? null : key,
    );
  }

  @override
  String toString() {
    return 'AppConfig(appName: $appName, packageName: $packageName, hasSupabaseCredentials: $hasSupabaseCredentials)';
  }
}
