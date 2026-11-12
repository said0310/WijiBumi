class AppSettings {
  final bool orderNotifications;
  final bool promoNotifications;
  final bool chatNotifications;

  const AppSettings({
    this.orderNotifications = true,
    this.promoNotifications = true,
    this.chatNotifications = true,
  });

  AppSettings copyWith({
    bool? orderNotifications,
    bool? promoNotifications,
    bool? chatNotifications,
  }) {
    return AppSettings(
      orderNotifications: orderNotifications ?? this.orderNotifications,
      promoNotifications: promoNotifications ?? this.promoNotifications,
      chatNotifications: chatNotifications ?? this.chatNotifications,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      orderNotifications: json['order_notifications'] as bool? ?? true,
      promoNotifications: json['promo_notifications'] as bool? ?? true,
      chatNotifications: json['chat_notifications'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'order_notifications': orderNotifications,
      'promo_notifications': promoNotifications,
      'chat_notifications': chatNotifications,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

