class Store {
  final String id;
  final String ownerId;
  final String storeName;
  final String slug;
  final String? description;
  final String? logoPath;
  final String? coverPath;
  final String? email;
  final String? phone;
  final String? address;
  final String? province;
  final String? city;
  final String? district;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? operatingHours;
  final String verificationStatus; // pending, approved, rejected, suspended
  final String? verificationNote;
  final bool isActive;
  final double rating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  Store({
    required this.id,
    required this.ownerId,
    required this.storeName,
    required this.slug,
    this.description,
    this.logoPath,
    this.coverPath,
    this.email,
    this.phone,
    this.address,
    this.province,
    this.city,
    this.district,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.operatingHours,
    this.verificationStatus = 'pending',
    this.verificationNote,
    this.isActive = false,
    this.rating = 5.0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => verificationStatus == 'approved' && isActive;

  String get verificationStatusLabel {
    switch (verificationStatus) {
      case 'approved':
        return isActive ? 'Aktif & Terverifikasi' : 'Nonaktif';
      case 'rejected':
        return 'Ditolak';
      case 'suspended':
        return 'Ditangguhkan';
      case 'pending':
      default:
        return 'Menunggu Verifikasi';
    }
  }

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      storeName: json['store_name'] as String,
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      logoPath: json['logo_path'] as String?,
      coverPath: json['cover_path'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      province: json['province'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      operatingHours: json['operating_hours'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      verificationNote: json['verification_note'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true, bool includeVerification = true}) {
    final map = <String, dynamic>{
      'owner_id': ownerId,
      'store_name': storeName,
      'slug': slug,
      'description': description,
      'logo_path': logoPath,
      'cover_path': coverPath,
      'email': email,
      'phone': phone,
      'address': address,
      'province': province,
      'city': city,
      'district': district,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'operating_hours': operatingHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includeId) map['id'] = id;
    if (includeVerification) {
      map['verification_status'] = verificationStatus;
      map['verification_note'] = verificationNote;
      map['is_active'] = isActive;
    }
    return map;
  }

  Store copyWith({
    String? storeName,
    String? description,
    String? logoPath,
    String? coverPath,
    String? email,
    String? phone,
    String? address,
    String? province,
    String? city,
    String? district,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? operatingHours,
    String? verificationStatus,
    String? verificationNote,
    bool? isActive,
    double? rating,
    int? totalReviews,
  }) {
    return Store(
      id: id,
      ownerId: ownerId,
      storeName: storeName ?? this.storeName,
      slug: slug,
      description: description ?? this.description,
      logoPath: logoPath ?? this.logoPath,
      coverPath: coverPath ?? this.coverPath,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      operatingHours: operatingHours ?? this.operatingHours,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationNote: verificationNote ?? this.verificationNote,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
