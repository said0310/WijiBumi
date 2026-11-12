import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/wishlist_item.dart';

class WishlistService {
  static const String boxName = 'wishlist';
  static Box<WishlistItem> get _box => Hive.box<WishlistItem>(boxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(WishlistItemAdapter());
    await Hive.openBox<WishlistItem>(boxName);
  }

  static ValueListenable<Box<WishlistItem>> get listenable => _box.listenable();
  static int get count => _box.length;
  static WishlistItem? getAt(int index) => _box.getAt(index); // READ

  static int _indexOf(String productId) =>
      _box.values.toList().indexWhere((e) => e.id == productId);

  static bool isSaved(String productId) => _indexOf(productId) != -1;

  // CREATE (add) atau DELETE (deleteAt), mengembalikan pesan untuk SnackBar
  static Future<String> toggle(Product product) async {
    final index = _indexOf(product.id);
    if (index == -1) {
      final item = WishlistItem.fromProduct(product);
      await _box.add(item);
      return '${item.describe()} disimpan ke wishlist';
    }
    final removed = _box.getAt(index)!;
    await _box.deleteAt(index);
    return '${removed.displayTitle} dihapus dari wishlist';
  }

  // UPDATE (putAt)
  static Future<void> updateNote(int index, String note) async {
    final item = _box.getAt(index);
    if (item == null) return;
    item.note = note; // lewat setter
    await _box.putAt(index, item);
  }

  // DELETE
  static Future<void> removeAt(int index) => _box.deleteAt(index);
}