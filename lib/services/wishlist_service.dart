import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/wishlist_item.dart';

class WishlistService {
  static const String boxName = 'wishlist';
  static final ValueNotifier<int> _fallbackNotifier = ValueNotifier<int>(0);

  static Box<WishlistItem> get _box => Hive.box<WishlistItem>(boxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(WishlistItemAdapter());
    await Hive.openBox<WishlistItem>(boxName);
  }

  static ValueListenable<dynamic> get listenable =>
      Hive.isBoxOpen(boxName) ? _box.listenable() : _fallbackNotifier;

  static int get count => Hive.isBoxOpen(boxName) ? _box.length : 0;
  static WishlistItem? getAt(int index) =>
      Hive.isBoxOpen(boxName) ? _box.getAt(index) : null;

  static int _indexOf(String productId) {
    if (!Hive.isBoxOpen(boxName)) return -1;
    return _box.values.toList().indexWhere((e) => e.id == productId);
  }

  static bool isSaved(String productId) => _indexOf(productId) != -1;

  static Future<String> toggle(Product product) async {
    if (!Hive.isBoxOpen(boxName)) return 'Wishlist belum dibuka';
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

  static Future<void> updateNote(int index, String note) async {
    if (!Hive.isBoxOpen(boxName)) return;
    final item = _box.getAt(index);
    if (item == null) return;
    item.note = note;
    await _box.putAt(index, item);
  }

  static Future<void> removeAt(int index) async {
    if (!Hive.isBoxOpen(boxName)) return;
    await _box.deleteAt(index);
  }
}
