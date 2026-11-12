import '../core/utils/currency_formatter.dart';
import 'base_entity.dart';

class Product extends BaseEntity {
  final String storeId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String unit;
  final int stock;
  final String? qualityGrade; // 'A', 'B', 'C'
  final DateTime? harvestDate;
  final int? shelfLifeDays;
  final String? farmLocation;
  final String status; // 'draft', 'active', 'inactive'
  final DateTime updatedAt;

  // Joined/Display helpers
  final List<String> images;
  final String? categoryName;
  final String? storeName;
  final String? storeCity;
  final String? storeLogo;
  final double rating;
  final int totalSales;

  Product({
    required super.id,
    required this.storeId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.unit,
    required this.stock,
    this.qualityGrade,
    this.harvestDate,
    this.shelfLifeDays,
    this.farmLocation,
    this.status = 'active',
    required super.createdAt,
    required this.updatedAt,
    this.images = const [],
    this.categoryName,
    this.storeName,
    this.storeCity,
    this.storeLogo,
    this.rating = 5.0,
    this.totalSales = 0,
  });

  String get primaryImage => images.isNotEmpty
      ? images.first
      : 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=400&q=80';

  bool get isAvailable => stock > 0 && status == 'active';

    @override
  String get displayTitle => name;

  @override
  String get displaySubtitle =>
      "${CurrencyFormatter.format(price)} / $unit • ${storeCity ?? farmLocation ?? '-'}";

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> imgList = [];
    if (json['product_images'] != null && json['product_images'] is List) {
      imgList = (json['product_images'] as List)
          .map((item) => item['storage_path']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (json['images'] != null && json['images'] is List) {
      imgList = (json['images'] as List).map((e) => e.toString()).toList();
    }

    String? sName;
    String? sCity;
    String? sLogo;
    if (json['stores'] != null && json['stores'] is Map) {
      sName = json['stores']['store_name'] as String?;
      sCity = json['stores']['city'] as String?;
      sLogo = json['stores']['logo_path'] as String?;
    } else {
      sName = json['store_name'] as String?;
      sCity = json['store_city'] as String?;
      sLogo = json['store_logo'] as String?;
    }

    String? catName;
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['name'] as String?;
    } else {
      catName = json['category_name'] as String?;
    }

    return Product(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'kg',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      qualityGrade: json['quality_grade'] as String?,
      harvestDate: json['harvest_date'] != null
          ? DateTime.tryParse(json['harvest_date'] as String)
          : null,
      shelfLifeDays: (json['shelf_life_days'] as num?)?.toInt(),
      farmLocation: json['farm_location'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      images: imgList,
      categoryName: catName,
      storeName: sName,
      storeCity: sCity,
      storeLogo: sLogo,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      totalSales: (json['total_sales'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      'store_id': storeId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'stock': stock,
      'quality_grade': qualityGrade,
      'harvest_date': harvestDate?.toIso8601String().split('T').first,
      'shelf_life_days': shelfLifeDays,
      'farm_location': farmLocation,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? unit,
    int? stock,
    String? qualityGrade,
    DateTime? harvestDate,
    int? shelfLifeDays,
    String? farmLocation,
    String? status,
    List<String>? images,
    String? categoryId,
    String? categoryName,
    String? storeName,
    String? storeCity,
    String? storeLogo,
    double? rating,
    int? totalSales,
  }) {
    return Product(
      id: id,
      storeId: storeId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      harvestDate: harvestDate ?? this.harvestDate,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      farmLocation: farmLocation ?? this.farmLocation,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      images: images ?? this.images,
      categoryName: categoryName ?? this.categoryName,
      storeName: storeName ?? this.storeName,
      storeCity: storeCity ?? this.storeCity,
      storeLogo: storeLogo ?? this.storeLogo,
      rating: rating ?? this.rating,
      totalSales: totalSales ?? this.totalSales,
    );
  }
}
