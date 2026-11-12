abstract class BaseEntity {
  final String id;
  final DateTime createdAt;

  BaseEntity({required this.id, required this.createdAt});

  // Abstract: wajib di-override oleh setiap turunan
  String get displayTitle;
  String get displaySubtitle;

  // Method biasa yang diwarisi; hasilnya berbeda tergantung turunannya (polymorphism)
  String describe() => '$displayTitle ($displaySubtitle)';
}