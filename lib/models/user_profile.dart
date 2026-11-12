import '../core/utils/date_formatter.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarPath;
  final DateTime? birthDate;
  final String? gender;
  final String role; // 'buyer', 'seller', 'both'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarPath,
    this.birthDate,
    this.gender,
    this.role = 'buyer',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasSellerAccess => role == 'seller' || role == 'both';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawBirth = json['birth_date']?.toString();
    final parsedBirth =
        rawBirth != null && rawBirth.isNotEmpty ? DateTime.tryParse(rawBirth) : null;
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarPath: json['avatar_path'] as String?,
      birthDate: parsedBirth != null
          ? DateTime(parsedBirth.year, parsedBirth.month, parsedBirth.day)
          : null,
      gender: json['gender'] as String?,
      role: json['role'] as String? ?? 'buyer',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_path': avatarPath,
      'birth_date': birthDate != null ? DateFormatter.formatSqlDate(birthDate!) : null,
      'gender': gender,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarPath,
    bool clearAvatarPath = false,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? gender,
    bool clearGender = false,
    String? role,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      gender: clearGender ? null : (gender ?? this.gender),
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
