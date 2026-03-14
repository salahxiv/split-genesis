// SECURITY: Do NOT hardcode credentials here.
// Pass values at build time via --dart-define:
//   flutter run \
//     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=your-anon-key
//
// For CI/CD, set SUPABASE_URL and SUPABASE_ANON_KEY as environment secrets
// and pass them via --dart-define in your build script.
//
// See: https://docs.flutter.dev/deployment/obfuscate#dart-define

class SupabaseConfig {
  // Values are injected at compile time via --dart-define.
  // The fallback strings will cause Supabase init to fail loudly
  // in debug mode if the defines are missing — intentional.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'SUPABASE_URL_NOT_SET',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'SUPABASE_ANON_KEY_NOT_SET',
  );

  static bool get isConfigured =>
      url != 'SUPABASE_URL_NOT_SET' && anonKey != 'SUPABASE_ANON_KEY_NOT_SET';
}
