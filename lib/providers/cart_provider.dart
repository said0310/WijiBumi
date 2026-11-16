import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/sqlite_service.dart';
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
      // 1. First, check remote Supabase if connected
      List<CartItem> remoteItems = [];
      try {
        remoteItems = await SupabaseService.instance.getCart();
      } catch (e) {
        debugPrint('Supabase getCart in loadCart note: $e');
      }

      if (remoteItems.isNotEmpty) {
        _items = remoteItems;
        for (final item in remoteItems) {
          await SqliteService.instance.saveCartItem(item.id, item.productId, item.quantity);
        }
      } else {
        // 2. Fall back to local SQLite database
        final localData = await SqliteService.instance.getCartItems();
        if (localData.isNotEmpty) {
          final allProducts = await SupabaseService.instance.getProducts();
          _items = localData.map((row) {
            final pid = row['product_id'] as String;
            final prod = allProducts.where((p) => p.id == pid).firstOrNull ??
                SupabaseService.instance.products.where((p) => p.id == pid).firstOrNull;
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
          // If both remote and SQLite are empty, check in-memory cartItems for test mocks
          if (!SupabaseService.instance.isConnected) {
            final uid = SupabaseService.instance.activeUserId ?? 'user-1';
            _items = SupabaseService.instance.cartItems
                .where((c) => c.userId == uid || uid == 'user-1')
                .toList();
          } else {
            _items = [];
          }
        }
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
    final uid = SupabaseService.instance.activeUserId;
    if (uid == null && SupabaseService.instance.isConnected) {
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

    final newQty = currentQty + quantity;
    final existingIdx = _items.indexWhere((i) => i.productId == product.id);
    final itemId = existingIdx != -1
        ? _items[existingIdx].id
        : 'cart-${DateTime.now().millisecondsSinceEpoch}';

    // 1. Immediately update local in-memory state
    if (existingIdx != -1) {
      _items[existingIdx].quantity = newQty;
    } else {
      _items.add(
        CartItem(
          id: itemId,
          userId: uid ?? 'user-1',
          productId: product.id,
          quantity: newQty,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          product: product,
        ),
      );
    }
    notifyListeners();

    // 2. Persist in SQLite
    await SqliteService.instance.saveCartItem(itemId, product.id, newQty);

    // 3. Sync to Supabase in background
    try {
      await SupabaseService.instance.addToCart(product, quantity);
    } catch (e) {
      debugPrint('Supabase addToCart sync error: $e');
    }

    return true;
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
    notifyListeners();

    await SqliteService.instance.updateCartQuantity(cartItemId, newQty);

    try {
      await SupabaseService.instance.updateCartQuantity(target.id, newQty);
    } catch (e) {
      debugPrint('Supabase updateCartQuantity sync error: $e');
    }
    return true;
  }

  Future<bool> removeItem(String cartItemId) async {
    _lastError = null;
    _items.removeWhere((i) => i.id == cartItemId || i.productId == cartItemId);
    notifyListeners();

    await SqliteService.instance.removeCartItem(cartItemId);

    try {
      await SupabaseService.instance.removeFromCart(cartItemId);
    } catch (e) {
      debugPrint('Supabase removeFromCart sync error: $e');
    }
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
    notifyListeners();

    await SqliteService.instance.clearCart();

    try {
      await SupabaseService.instance.clearCart();
    } catch (e) {
      debugPrint('Supabase clearCart sync error: $e');
    }
    return true;
  }

  void clearSession() {
    _items = [];
    _lastError = null;
    notifyListeners();
  }
}
