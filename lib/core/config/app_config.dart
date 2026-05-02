import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String get supabaseUrl => _getEnv('SUPABASE_URL');
  static String get supabaseAnonKey => _getEnv('SUPABASE_ANON_KEY');
  static String get apiUrl => _getEnv('API_URL');

  static String _getEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Missing environment variable: $key');
    }
    return value;
  }
}
