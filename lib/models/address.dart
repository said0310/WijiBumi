class Address {
  final String id;
  final String userId;
  final String label;
  final String recipientName;
  final String phone;
  final String address;
  final String? province;
  final String? city;
  final String? district;
  final String? kelurahan;
  final String? postalCode;
  final String? note;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Address({
    required this.id,
    required this.userId,
    this.label = 'Rumah',
    required this.recipientName,
    required this.phone,
    required this.address,
    this.province,
    this.city,
    this.district,
    this.kelurahan,
    this.postalCode,
    this.note,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddressText {
    final parts = [address];
    if (kelurahan != null && kelurahan!.isNotEmpty) parts.add('Kel. $kelurahan');
    if (district != null && district!.isNotEmpty) parts.add('Kec. $district');
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      label: json['label'] as String? ?? 'Rumah',
      recipientName: json['recipient_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      province: json['province'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      kelurahan: json['kelurahan'] as String?,
      postalCode: json['postal_code'] as String?,
      note: json['note'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'user_id': userId,
      'label': label,
      'recipient_name': recipientName,
      'phone': phone,
      'address': address,
      'province': province,
      'city': city,
      'district': district,
      'kelurahan': kelurahan,
      'postal_code': postalCode,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  Address copyWith({
    String? label,
    String? recipientName,
    String? phone,
    String? address,
    String? province,
    String? city,
    String? district,
    String? kelurahan,
    String? postalCode,
    String? note,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      userId: userId,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      kelurahan: kelurahan ?? this.kelurahan,
      postalCode: postalCode ?? this.postalCode,
      note: note ?? this.note,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
