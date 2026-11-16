import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _lastError;

  List<CartItem> get items => _items;
  List<CartItem> get validItems =>
      _items.where((i) => i.product != null && i.product!.isAvailable).toList();
  List<CartItem> get unavailableItems =>
      _items.where((i) => i.product == null || !i.product!.isAvailable).toList();
  List<CartItem> get overStockItems => _items
      .where(
        (i) =>
            i.product != null &&
            i.product!.isAvailable &&
            i.quantity > i.product!.stock,
      )
      .toList();

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasUnavailableItems => unavailableItems.isNotEmpty;
  bool get hasOverStockItems => overStockItems.isNotEmpty;
  bool get canCheckout =>
      validItems.isNotEmpty && !hasUnavailableItems && !hasOverStockItems;

  int get itemCount =>
      validItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount =>
      validItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Group available items by store name for legacy callers
  Map<String, List<CartItem>> get itemsByStore {
    final Map<String, List<CartItem>> map = {};
    for (final item in validItems) {
      final storeName = item.product?.storeName ?? 'Toko Lainnya';
      map.putIfAbsent(storeName, () => []).add(item);
    }
    return map;
  }

  // Group available items safely by unique storeId
  Map<String, List<CartItem>> get itemsByStoreId {
    final Map<String, List<CartItem>> map = {};
    for (final item in validItems) {
      final storeId = item.product?.storeId ?? 'unknown';
      map.putIfAbsent(storeId, () => []).add(item);
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

  int quantityInCart(String productId) {
    for (final item in _items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    _lastError = null;
    if (SupabaseService.instance.activeUserId == null) {
      _lastError = 'Silakan masuk ke akun WijiBumi terlebih dahulu.';
      return false;
    }
    if (!product.isAvailable) {
      _lastError = 'Produk "${product.name}" saat ini tidak tersedia.';
      return false;
    }
    if (quantity <= 0) {
      _lastError = 'Jumlah pembelian minimal 1.';
      return false;
    }
    final currentQty = quantityInCart(product.id);
    if (currentQty + quantity > product.stock) {
      _lastError =
          'Jumlah melebihi stok tersedia (${product.stock} ${product.unit}).';
      return false;
    }
    final ok = await SupabaseService.instance.addToCart(product, quantity);
    if (ok) {
      await loadCart();
    } else {
      _lastError = 'Gagal menambahkan produk ke keranjang. Periksa koneksi Anda.';
    }
    return ok;
  }

  Future<bool> updateQuantity(String cartItemId, int newQty) async {
    _lastError = null;
    if (newQty <= 0) {
      return await removeItem(cartItemId);
    }
    final target = _items.where((i) => i.id == cartItemId).firstOrNull;
    if (target == null || target.product == null || !target.product!.isAvailable) {
      _lastError = 'Produk ini sudah tidak tersedia di keranjang.';
      return false;
    }
    if (newQty > target.product!.stock) {
      _lastError =
          'Maksimal stok ${target.product!.name} (${target.product!.stock} ${target.product!.unit}).';
      return false;
    }
    final ok = await SupabaseService.instance.updateCartQuantity(cartItemId, newQty);
    if (ok) {
      await loadCart();
    } else {
      _lastError = 'Gagal mengubah jumlah produk. Periksa stok atau koneksi.';
    }
    return ok;
  }

  Future<bool> removeItem(String cartItemId) async {
    _lastError = null;
    final ok = await SupabaseService.instance.removeFromCart(cartItemId);
    if (ok) {
      await loadCart();
    } else {
      _lastError = 'Gagal menghapus produk dari keranjang.';
    }
    return ok;
  }

  Future<bool> removeUnavailableItems() async {
    _lastError = null;
    final toRemove = unavailableItems;
    if (toRemove.isEmpty) return true;
    bool allOk = true;
    for (final item in toRemove) {
      final ok = await SupabaseService.instance.removeFromCart(item.id);
      if (!ok) allOk = false;
    }
    await loadCart();
    if (!allOk) {
      _lastError = 'Sebagian item tidak tersedia gagal dihapus.';
    }
    return allOk;
  }

  Future<bool> clear() async {
    _lastError = null;
    final ok = await SupabaseService.instance.clearCart();
    if (ok) {
      _items.clear();
      notifyListeners();
    } else {
      _lastError = 'Gagal mengosongkan keranjang. Periksa koneksi Anda.';
    }
    return ok;
  }

  void clearSession() {
    _items = [];
    _lastError = null;
    notifyListeners();
  }
}
