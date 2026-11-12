import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../services/supabase_service.dart';

class AppSettingsProvider with ChangeNotifier {
  static const _kOrderNotif = 'settings_order_notif';
  static const _kPromoNotif = 'settings_promo_notif';
  static const _kChatNotif = 'settings_chat_notif';

  AppSettings _settings = const AppSettings();
  bool _isSaving = false;
  String? _lastError;

  AppSettings get settings => _settings;
  bool get isSaving => _isSaving;
  String? get lastError => _lastError;

  AppSettingsProvider() {
    loadSettings();
  }

  String _scopedKey(String base, String? uid) =>
      uid != null && uid.isNotEmpty ? '${uid}_$base' : base;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = SupabaseService.instance.activeUserId;
    _settings = AppSettings(
      orderNotifications:
          prefs.getBool(_scopedKey(_kOrderNotif, uid)) ?? true,
      promoNotifications:
          prefs.getBool(_scopedKey(_kPromoNotif, uid)) ?? true,
      chatNotifications: prefs.getBool(_scopedKey(_kChatNotif, uid)) ?? true,
    );
    notifyListeners();

    final remote = await SupabaseService.instance.fetchRemoteUserSettings();
    if (remote != null) {
      _settings = remote;
      await _persistLocal(uid);
      notifyListeners();
    }
  }

  Future<bool> updateSettings(AppSettings updated) async {
    final previous = _settings;
    _settings = updated;
    _lastError = null;
    _isSaving = true;
    notifyListeners();

    final uid = SupabaseService.instance.activeUserId;
    await _persistLocal(uid);
    final remoteOk = await SupabaseService.instance.saveRemoteUserSettings(updated);
    if (!remoteOk && SupabaseService.instance.isConnected) {
      _settings = previous;
      await _persistLocal(uid);
      _lastError = 'Gagal menyinkronkan pengaturan ke server. Coba lagi.';
    }
    _isSaving = false;
    notifyListeners();
    return remoteOk || !SupabaseService.instance.isConnected;
  }

  Future<void> clearSession() async {
    _settings = const AppSettings();
    _lastError = null;
    _isSaving = false;
    notifyListeners();
  }

  Future<void> _persistLocal(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scopedKey(_kOrderNotif, uid), _settings.orderNotifications);
    await prefs.setBool(_scopedKey(_kPromoNotif, uid), _settings.promoNotifications);
    await prefs.setBool(_scopedKey(_kChatNotif, uid), _settings.chatNotifications);
  }
}

