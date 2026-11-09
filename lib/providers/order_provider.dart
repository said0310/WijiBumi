import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../services/supabase_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  String _selectedStatusFilter = ''; // Empty = all
  bool _isLoading = false;

  List<Order> get orders {
    if (_selectedStatusFilter.isEmpty) return _orders;
    return _orders.where((o) => o.status == _selectedStatusFilter).toList();
  }

  String get selectedStatusFilter => _selectedStatusFilter;
  bool get isLoading => _isLoading;

  OrderProvider() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _orders = await SupabaseService.instance.getOrders();
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
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final createdOrders = await SupabaseService.instance.createCheckoutOrders(
        address: address,
        paymentMethod: paymentMethod,
        courierName: courierName,
        buyerNote: buyerNote,
      );
      await loadOrders();
      return createdOrders;
    } catch (e) {
      debugPrint('Checkout error: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    await SupabaseService.instance.updateOrderStatus(orderId, newStatus);
    await loadOrders();
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
  }
}
