import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/app_notification.dart';
import '../services/supabase_service.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _lastError;
  RealtimeChannel? _channel;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    loadNotifications();
    subscribeRealtime();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await SupabaseService.instance.getNotifications();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeRealtime() {
    if (!SupabaseService.instance.isConnected) return;
    final client = SupabaseConfig.client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return;

    unsubscribeRealtime();
    _channel = client
        .channel('public:notifications:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (payload) {
            try {
              if (payload.eventType == PostgresChangeEvent.insert) {
                final notif = AppNotification.fromJson(payload.newRecord);
                if (!_notifications.any((n) => n.id == notif.id)) {
                  _notifications.insert(0, notif);
                  notifyListeners();
                }
              } else if (payload.eventType == PostgresChangeEvent.update) {
                final updated = AppNotification.fromJson(payload.newRecord);
                final idx = _notifications.indexWhere((n) => n.id == updated.id);
                if (idx != -1) {
                  _notifications[idx] = updated;
                  notifyListeners();
                }
              } else if (payload.eventType == PostgresChangeEvent.delete) {
                final deletedId = payload.oldRecord['id']?.toString();
                if (deletedId != null) {
                  final beforeLen = _notifications.length;
                  _notifications.removeWhere((n) => n.id == deletedId);
                  if (_notifications.length != beforeLen) {
                    notifyListeners();
                  }
                }
              }
            } catch (e) {
              debugPrint('Realtime notification parse error: $e');
            }
          },
        )
        .subscribe();
  }

  void unsubscribeRealtime() {
    if (_channel != null && SupabaseConfig.client != null) {
      SupabaseConfig.client!.removeChannel(_channel!);
      _channel = null;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    _lastError = null;
    final ok =
        await SupabaseService.instance.markNotificationAsRead(notificationId);
    if (!ok) {
      _lastError = 'Gagal menandai notifikasi sebagai dibaca.';
      return false;
    }
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
    return true;
  }

  Future<bool> markAllAsRead() async {
    _lastError = null;
    final ok = await SupabaseService.instance.markAllNotificationsAsRead();
    if (!ok) {
      _lastError = 'Gagal menandai semua notifikasi sebagai dibaca.';
      return false;
    }
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    return true;
  }

  Future<bool> deleteNotification(String notificationId) async {
    _lastError = null;
    final ok =
        await SupabaseService.instance.deleteNotification(notificationId);
    if (!ok) {
      _lastError = 'Gagal menghapus notifikasi. Periksa koneksi Anda.';
      return false;
    }
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
    return true;
  }

  void clearSession() {
    unsubscribeRealtime();
    _notifications = [];
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unsubscribeRealtime();
    super.dispose();
  }
}
