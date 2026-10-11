/// Central application configuration.
///
/// Secrets are NEVER hard-coded. Supabase connection values are injected at
/// build/run time via `--dart-define` (or `--dart-define-from-file`), e.g.:
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
/// ```
///
/// When Supabase is not configured, the app automatically falls back to the
/// in-memory [MockRepository] so it runs end-to-end out of the box for
/// development, demos, and UI work. Set `USE_MOCK_DATA=true` to force mock mode
/// even when Supabase values are present.
library;

class AppConfig {
  const AppConfig._();

  /// Supabase project URL. Empty when not configured.
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Supabase anon (publishable) key. Safe to ship in clients — RLS enforces
  /// per-user access. Service-role keys NEVER live in the client.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Optional native Google OAuth client IDs (used by google_sign_in on
  /// mobile/desktop). Web uses the Supabase-hosted OAuth redirect.
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');

  /// Deep-link redirect used to return to the app after OAuth on mobile/desktop.
  static const String authRedirectScheme =
      String.fromEnvironment('AUTH_REDIRECT', defaultValue: 'canyonsconnect://login-callback');

  static const bool _forceMock =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);

  /// True when real Supabase credentials are present.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Whether to use the mock data layer. Mock is used when forced, or whenever
  /// Supabase is not configured.
  static bool get useMockData => _forceMock || !hasSupabase;
}
