class AppSettings {
  final bool orderNotifications;
  final bool promoNotifications;
  final bool chatNotifications;
  final bool emailUpdates;
  final String languageCode; // 'id' | 'en'
  final bool showOnlineStatus;
  final bool allowAnalytics;

  const AppSettings({
    this.orderNotifications = true,
    this.promoNotifications = true,
    this.chatNotifications = true,
    this.emailUpdates = true,
    this.languageCode = 'id',
    this.showOnlineStatus = true,
    this.allowAnalytics = true,
  });

  AppSettings copyWith({
    bool? orderNotifications,
    bool? promoNotifications,
    bool? chatNotifications,
    bool? emailUpdates,
    String? languageCode,
    bool? showOnlineStatus,
    bool? allowAnalytics,
  }) {
    return AppSettings(
      orderNotifications: orderNotifications ?? this.orderNotifications,
      promoNotifications: promoNotifications ?? this.promoNotifications,
      chatNotifications: chatNotifications ?? this.chatNotifications,
      emailUpdates: emailUpdates ?? this.emailUpdates,
      languageCode: languageCode ?? this.languageCode,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      orderNotifications: json['order_notifications'] as bool? ?? true,
      promoNotifications: json['promo_notifications'] as bool? ?? true,
      chatNotifications: json['chat_notifications'] as bool? ?? true,
      emailUpdates: json['email_updates'] as bool? ?? true,
      languageCode: json['language_code'] as String? ?? 'id',
      showOnlineStatus: json['show_online_status'] as bool? ?? true,
      allowAnalytics: json['allow_analytics'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'order_notifications': orderNotifications,
      'promo_notifications': promoNotifications,
      'chat_notifications': chatNotifications,
      'email_updates': emailUpdates,
      'language_code': languageCode,
      'show_online_status': showOnlineStatus,
      'allow_analytics': allowAnalytics,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

