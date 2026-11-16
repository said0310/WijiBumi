class Promotion {
  final String id;
  final String storeId;
  final String title;
  final String? code;
  final String promotionType; // 'percentage', 'fixed_amount', 'flash_sale'
  final double value;
  final double minimumPurchase;
  final double? maximumDiscount;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? quota;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.storeId,
    required this.title,
    this.code,
    required this.promotionType,
    required this.value,
    this.minimumPurchase = 0.0,
    this.maximumDiscount,
    required this.startsAt,
    required this.endsAt,
    this.quota,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      title: json['title'] as String,
      code: json['code'] as String?,
      promotionType: json['promotion_type'] as String? ?? 'percentage',
      value: (json['value'] as num).toDouble(),
      minimumPurchase: (json['minimum_purchase'] as num?)?.toDouble() ?? 0.0,
      maximumDiscount: (json['maximum_discount'] as num?)?.toDouble(),
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at'] as String) : DateTime.now(),
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at'] as String) : DateTime.now().add(const Duration(days: 30)),
      quota: (json['quota'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'store_id': storeId,
      'title': title,
      'code': code,
      'promotion_type': promotionType,
      'value': value,
      'minimum_purchase': minimumPurchase,
      'maximum_discount': maximumDiscount,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'quota': quota,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }
}
