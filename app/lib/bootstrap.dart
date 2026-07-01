import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';

Future<void> bootstrap() async {
  Env.assertConfigured();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
}

SupabaseClient get supabase => Supabase.instance.client;
