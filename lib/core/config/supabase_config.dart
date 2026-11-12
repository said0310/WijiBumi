import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _keyUrl = 'supabase_url';
  static const String _keyAnonKey = 'supabase_anon_key';

  // Environment variables or defaults (can be overridden via --dart-define / env.json)
  static const String envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://skwdxgtwdhxualtgxfsj.supabase.co',
  );
  static const String envAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_01hTrn-yZsEF8-eFGo_Tyg_5p6vPK8Q',
  );

  static String currentUrl = envUrl;
  static String currentAnonKey = envAnonKey;
  static bool isInitialized = false;

  static Future<void> init() async {
    try {
      String? savedUrl;
      String? savedAnonKey;
      try {
        final prefs = await SharedPreferences.getInstance();
        savedUrl = prefs.getString(_keyUrl);
        savedAnonKey = prefs.getString(_keyAnonKey);
      } catch (_) {}

      currentUrl = envUrl.isNotEmpty ? envUrl : (savedUrl ?? '');
      currentAnonKey = envAnonKey.isNotEmpty ? envAnonKey : (savedAnonKey ?? '');

      if (currentUrl.isNotEmpty && currentAnonKey.isNotEmpty) {
        await Supabase.initialize(
          url: currentUrl,
          publishableKey: currentAnonKey,
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
    var cleanUrl = url.trim();
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    final cleanAnonKey = anonKey.trim();

    final parsed = Uri.tryParse(cleanUrl);
    if (parsed == null ||
        !(parsed.scheme == 'http' || parsed.scheme == 'https') ||
        parsed.host.isEmpty ||
        cleanAnonKey.isEmpty) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, cleanUrl);
    await prefs.setString(_keyAnonKey, cleanAnonKey);
    currentUrl = cleanUrl;
    currentAnonKey = cleanAnonKey;

    try {
      if (isInitialized) {
        try {
          await Supabase.instance.dispose();
        } catch (_) {}
        isInitialized = false;
      }
      await Supabase.initialize(
        url: currentUrl,
        publishableKey: currentAnonKey,
        debug: kDebugMode,
      );
      isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to connect to Supabase: $e');
      isInitialized = false;
      return false;
    }
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
