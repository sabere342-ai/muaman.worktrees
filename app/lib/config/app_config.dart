/// Compile-time configuration for Supabase integration.
///
/// Values are injected via `--dart-define` at build time:
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=xxx
/// ```
///
/// NEVER commit real credentials. The defaults below are placeholders for
/// local development only and will not connect to a real project.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-ref.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  /// Returns `true` when both values appear to be configured (not placeholders).
  static bool get isConfigured =>
      supabaseUrl != 'https://your-project-ref.supabase.co' &&
      supabaseAnonKey != 'your-anon-key' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
