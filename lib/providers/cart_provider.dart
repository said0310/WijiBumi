import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/sqlite_service.dart';
import '../services/supabase_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _lastError;
  bool _hasInitialSynced = false;

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
      final remoteItems = await SupabaseService.instance.getCart();
      if (remoteItems.isNotEmpty) {
        _items = remoteItems;
        _hasInitialSynced = true;
        for (final item in remoteItems) {
          await SqliteService.instance.saveCartItem(item.id, item.productId, item.quantity);
        }
      } else if (!_hasInitialSynced) {
        final localData = await SqliteService.instance.getCartItems();
        if (localData.isNotEmpty) {
          final allProducts = await SupabaseService.instance.getProducts();
          _items = localData.map((row) {
            final pid = row['product_id'] as String;
            final prod = allProducts.where((p) => p.id == pid).firstOrNull;
            return CartItem(
              id: row['id'] as String,
              userId: SupabaseService.instance.activeUserId ?? 'user-1',
              productId: pid,
              quantity: row['quantity'] as int,
              createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.now(),
              product: prod,
            );
          }).where((ci) => ci.product != null).toList();
        } else {
          _items = [];
        }
        _hasInitialSynced = true;
      } else {
        _items = [];
      }
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
      final existingIdx = _items.indexWhere((i) => i.productId == product.id);
      final newQty = (existingIdx != -1 ? _items[existingIdx].quantity : 0) + quantity;
      final itemId = existingIdx != -1 ? _items[existingIdx].id : 'cart-${DateTime.now().millisecondsSinceEpoch}';
      await SqliteService.instance.saveCartItem(itemId, product.id, newQty);
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
    final target = _items.where((i) => i.id == cartItemId || i.productId == cartItemId).firstOrNull;
    if (target == null || target.product == null || !target.product!.isAvailable) {
      _lastError = 'Produk ini sudah tidak tersedia di keranjang.';
      return false;
    }
    if (newQty > target.product!.stock) {
      _lastError =
          'Maksimal stok ${target.product!.name} (${target.product!.stock} ${target.product!.unit}).';
      return false;
    }

    target.quantity = newQty;
    await SqliteService.instance.updateCartQuantity(cartItemId, newQty);
    notifyListeners();

    await SupabaseService.instance.updateCartQuantity(target.id, newQty);
    return true;
  }

  Future<bool> removeItem(String cartItemId) async {
    _lastError = null;
    _items.removeWhere((i) => i.id == cartItemId || i.productId == cartItemId);
    await SqliteService.instance.removeCartItem(cartItemId);
    notifyListeners();

    await SupabaseService.instance.removeFromCart(cartItemId);
    return true;
  }

  Future<bool> removeUnavailableItems() async {
    _lastError = null;
    final toRemove = List<CartItem>.from(unavailableItems);
    if (toRemove.isEmpty) return true;
    for (final item in toRemove) {
      await removeItem(item.id);
    }
    return true;
  }

  Future<bool> clear() async {
    _lastError = null;
    _items.clear();
    await SqliteService.instance.clearCart();
    notifyListeners();
    final ok = await SupabaseService.instance.clearCart();
    if (!ok) {
      _lastError = 'Gagal mengosongkan keranjang di server.';
    }
    return ok;
  }

  void clearSession() {
    _items = [];
    _lastError = null;
    notifyListeners();
  }
}
