import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';

Future<void> bootstrap() async {
  Env.assertConfigured();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    // The publishable/anon key: `supabase start` prints it as the "anon key",
    // hence the env var name; supabase_flutter renamed the param to publishableKey.
    publishableKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
}

SupabaseClient get supabase => Supabase.instance.client;
