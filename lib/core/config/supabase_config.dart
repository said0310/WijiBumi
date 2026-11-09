import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _keyUrl = 'supabase_url';
  static const String _keyAnonKey = 'supabase_anon_key';

  // Environment variables or defaults
  static const String envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static String currentUrl = envUrl;
  static String currentAnonKey = envAnonKey;
  static bool isInitialized = false;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_keyUrl);
      final savedAnonKey = prefs.getString(_keyAnonKey);

      currentUrl = savedUrl?.isNotEmpty == true ? savedUrl! : envUrl;
      currentAnonKey = savedAnonKey?.isNotEmpty == true ? savedAnonKey! : envAnonKey;

      if (currentUrl.isNotEmpty && currentAnonKey.isNotEmpty) {
        await Supabase.initialize(
          url: currentUrl,
          anonKey: currentAnonKey,
          debug: kDebugMode,
        );
        isInitialized = true;
      }
    } catch (e) {
      debugPrint('Supabase initialization note: $e (Falling back to in-memory mode)');
      isInitialized = false;
    }
  }

  static Future<bool> updateCredentials(String url, String anonKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, url.trim());
    await prefs.setString(_keyAnonKey, anonKey.trim());
    currentUrl = url.trim();
    currentAnonKey = anonKey.trim();

    if (currentUrl.isNotEmpty && currentAnonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: currentUrl,
          anonKey: currentAnonKey,
        );
        isInitialized = true;
        return true;
      } catch (e) {
        debugPrint('Failed to connect to Supabase: $e');
        isInitialized = false;
        return false;
      }
    }
    return false;
  }

  static SupabaseClient? get client {
    if (isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
