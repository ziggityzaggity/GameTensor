/// Compile-time environment config, supplied via
/// `flutter run --dart-define-from-file=env/dev.json`.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase config. Run with --dart-define-from-file=env/dev.json '
        '(copy env/dev.example.json to env/dev.json and fill in values from `supabase start`).',
      );
    }
  }
}
