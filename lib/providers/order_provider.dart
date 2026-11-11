import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  String _selectedStatusFilter = ''; // Empty = all
  bool _isLoading = false;
  String? _lastError;
  Map<String, Set<String>> _reviewedProductsByOrder = {};

  List<Order> get orders {
    if (_selectedStatusFilter.isEmpty) return _orders;
    return _orders.where((o) => o.status == _selectedStatusFilter).toList();
  }

  List<Order> get allOrders => _orders;
  String get selectedStatusFilter => _selectedStatusFilter;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  OrderProvider() {
    loadOrders();
  }

  Set<String> reviewedProductKeysForOrder(String orderId) {
    return _reviewedProductsByOrder[orderId] ?? const {};
  }

  bool isProductReviewedInOrder(String orderId, String? productId) {
    final reviewed = _reviewedProductsByOrder[orderId];
    if (reviewed == null || reviewed.isEmpty) return false;
    return reviewed.contains(productId ?? '__order__');
  }

  bool isOrderFullyReviewed(Order order) {
    final reviewed = _reviewedProductsByOrder[order.id];
    if (reviewed == null || reviewed.isEmpty) return false;
    if (order.items.isEmpty) {
      return reviewed.contains('__order__');
    }
    return order.items.every(
      (item) => reviewed.contains(item.productId ?? '__order__'),
    );
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        SupabaseService.instance.getOrders(),
        SupabaseService.instance.getBuyerReviewedProductMap().catchError(
              (_) => <String, Set<String>>{},
            ),
      ]);
      _orders = results[0] as List<Order>;
      _reviewedProductsByOrder = results[1] as Map<String, Set<String>>;
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  Future<List<Order>> checkout({
    required Address address,
    required String paymentMethod,
    required String courierName,
    String? buyerNote,
  }) {
    return _executeCheckout(
      () => SupabaseService.instance.createCheckoutOrders(
        address: address,
        paymentMethod: paymentMethod,
        courierName: courierName,
        buyerNote: buyerNote,
      ),
    );
  }

  Future<List<Order>> directCheckout({
    required Address address,
    required Product product,
    required int quantity,
    required String paymentMethod,
    required String courierName,
    String? buyerNote,
  }) {
    return _executeCheckout(
      () => SupabaseService.instance.createDirectOrder(
        address: address,
        product: product,
        quantity: quantity,
        paymentMethod: paymentMethod,
        courierName: courierName,
        buyerNote: buyerNote,
      ),
    );
  }

  Future<List<Order>> _executeCheckout(
    Future<List<Order>> Function() action,
  ) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final createdOrders = await action();
      await loadOrders();
      return createdOrders;
    } on PostgrestException catch (e) {
      debugPrint('Checkout PostgrestException: ${e.message}');
      _lastError = e.message.isNotEmpty
          ? e.message
          : 'Gagal membuat pesanan. Periksa stok produk dan koneksi.';
      return [];
    } catch (e) {
      debugPrint('Checkout error: $e');
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      _lastError = raw.isNotEmpty
          ? raw
          : 'Gagal membuat pesanan. Periksa stok produk dan koneksi.';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String orderId, String newStatus) async {
    _lastError = null;
    final ok = await SupabaseService.instance.updateOrderStatus(orderId, newStatus);
    if (ok) {
      await loadOrders();
    } else {
      _lastError = 'Gagal memperbarui status pesanan.';
    }
    return ok;
  }

  Future<void> addReview({
    required String orderId,
    required String storeId,
    String? productId,
    required int rating,
    required String reviewText,
  }) async {
    await SupabaseService.instance.addReview(
      orderId: orderId,
      storeId: storeId,
      productId: productId,
      rating: rating,
      reviewText: reviewText,
    );
    _reviewedProductsByOrder
        .putIfAbsent(orderId, () => <String>{})
        .add(productId ?? '__order__');
    notifyListeners();
  }

  void clearSession() {
    _orders = [];
    _selectedStatusFilter = '';
    _lastError = null;
    _reviewedProductsByOrder = {};
    notifyListeners();
  }
}
