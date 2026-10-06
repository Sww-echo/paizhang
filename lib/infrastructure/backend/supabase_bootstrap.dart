import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_http_client.dart';

class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static Future<bool> initializeIfConfigured() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (url.isEmpty || publishableKey.isEmpty) return false;
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      httpClient: AuthHttpClient(http.Client()),
    );
    return true;
  }

  static Future<void> initialize() async {
    if (!await initializeIfConfigured()) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. '
        'Pass them with --dart-define.',
      );
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
