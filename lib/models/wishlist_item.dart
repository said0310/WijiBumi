// ignore_for_file: prefer_initializing_formals
import 'package:hive/hive.dart';
import '../core/utils/currency_formatter.dart';
import 'base_entity.dart';
import 'product.dart';

class WishlistItem extends BaseEntity {
  final String name;
  final double price;
  final String storeName;
  final String imageUrl;
  String _note; // private (encapsulation)

  // Constructor dengan super(...) eksplisit + initializer list
  WishlistItem({
    required String productId,
    required this.name,
    required this.price,
    required this.storeName,
    required this.imageUrl,
    String note = '',
    required DateTime savedAt,
  })  : _note = note,
        super(id: productId, createdAt: savedAt);

  // Factory constructor: Product -> WishlistItem
  factory WishlistItem.fromProduct(Product p) => WishlistItem(
        productId: p.id,
        name: p.name,
        price: p.price,
        storeName: p.storeName ?? 'Toko WijiBumi',
        imageUrl: p.images.isNotEmpty ? p.images.first : '',
        savedAt: DateTime.now(),
      );

  // Getter & setter
  String get note => _note;
  set note(String value) => _note = value.trim();

  @override
  String get displayTitle => name;

  @override
  String get displaySubtitle =>
      '${CurrencyFormatter.format(price)} • $storeName';
}

// TypeAdapter manual (setara hasil generator @HiveType)
class WishlistItemAdapter extends TypeAdapter<WishlistItem> {
  @override
  final int typeId = 1;

  @override
  WishlistItem read(BinaryReader reader) {
    return WishlistItem(
      productId: reader.readString(),
      name: reader.readString(),
      price: reader.readDouble(),
      storeName: reader.readString(),
      imageUrl: reader.readString(),
      note: reader.readString(),
      savedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, WishlistItem obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeDouble(obj.price)
      ..writeString(obj.storeName)
      ..writeString(obj.imageUrl)
      ..writeString(obj.note)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}