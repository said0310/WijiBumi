import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Group items by store for multi-store cart display
  Map<String, List<CartItem>> get itemsByStore {
    final Map<String, List<CartItem>> map = {};
    for (var item in _items) {
      final storeName = item.product?.storeName ?? 'Toko Lainnya';
      map.putIfAbsent(storeName, () => []).add(item);
    }
    return map;
  }

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await SupabaseService.instance.getCart();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    await SupabaseService.instance.addToCart(product, quantity);
    await loadCart();
  }

  Future<void> updateQuantity(String cartItemId, int newQty) async {
    await SupabaseService.instance.updateCartQuantity(cartItemId, newQty);
    await loadCart();
  }

  Future<void> removeItem(String cartItemId) async {
    await SupabaseService.instance.removeFromCart(cartItemId);
    await loadCart();
  }

  Future<void> clear() async {
    await SupabaseService.instance.clearCart();
    _items.clear();
    notifyListeners();
  }
}
