import 'package:flutter/foundation.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/promotion.dart';
import '../models/payout.dart';
import '../services/supabase_service.dart';

class DailySalesPoint {
  final String label;
  final DateTime date;
  final double amount;
  final int orderCount;

  const DailySalesPoint({
    required this.label,
    required this.date,
    required this.amount,
    required this.orderCount,
  });
}

class StoreProvider with ChangeNotifier {
  List<Store> _stores = [];
  Store? _myStore;
  List<Product> _myStoreProducts = [];
  List<Order> _myStoreOrders = [];
  List<Review> _myStoreReviews = [];
  List<Promotion> _myStorePromotions = [];
  List<PayoutAccount> _myPayoutAccounts = [];
  List<PayoutRequest> _myPayoutRequests = [];
  bool _isLoading = false;

  List<Store> get stores => _stores;
  Store? get myStore => _myStore;
  bool get hasStore => _myStore != null;
  List<Product> get myStoreProducts => _myStoreProducts;
  List<Order> get myStoreOrders => _myStoreOrders;
  List<Review> get myStoreReviews => _myStoreReviews;
  List<Promotion> get myStorePromotions => _myStorePromotions;
  List<PayoutAccount> get myPayoutAccounts => _myPayoutAccounts;
  List<PayoutRequest> get myPayoutRequests => _myPayoutRequests;
  bool get isLoading => _isLoading;

  // Seller Dashboard Metrics
  int get totalProductsCount => _myStoreProducts.length;
  int get activeProductsCount =>
      _myStoreProducts.where((p) => p.status == 'active').length;
  List<Product> get activeProducts =>
      _myStoreProducts.where((p) => p.status == 'active').toList();
  List<Order> get recentOrders => _myStoreOrders.take(5).toList();
  int get incomingOrdersCount => _myStoreOrders
      .where((o) => o.status == 'awaiting_confirmation')
      .length;
  int get processingOrdersCount => _myStoreOrders
      .where((o) => o.status == 'processing' || o.status == 'ready_to_ship')
      .length;
  int get shippedOrdersCount =>
      _myStoreOrders.where((o) => o.status == 'shipped').length;
  int get completedOrdersCount => _myStoreOrders.where((o) => o.status == 'completed').length;

  Iterable<Order> get _paidOrCompletedOrders => _myStoreOrders
      .where((o) => (o.paymentStatus == 'paid' || o.status == 'completed') && o.status != 'cancelled');

  double get totalRevenue => _paidOrCompletedOrders.fold(0.0, (sum, o) => sum + o.subtotal);

  double get todayRevenue {
    final now = DateTime.now();
    return _paidOrCompletedOrders
        .where((o) =>
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day)
        .fold(0.0, (sum, o) => sum + o.subtotal);
  }

  double get weeklyRevenue {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _paidOrCompletedOrders
        .where((o) => o.createdAt.isAfter(cutoff))
        .fold(0.0, (sum, o) => sum + o.subtotal);
  }

  double get previousWeekRevenue {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    return _paidOrCompletedOrders
        .where((o) => o.createdAt.isAfter(twoWeeksAgo) && o.createdAt.isBefore(weekAgo))
        .fold(0.0, (sum, o) => sum + o.subtotal);
  }

  double get monthlyRevenue {
    final now = DateTime.now();
    return _paidOrCompletedOrders
        .where((o) => o.createdAt.year == now.year && o.createdAt.month == now.month)
        .fold(0.0, (sum, o) => sum + o.subtotal);
  }

  int get totalUnitsSold {
    return _myStoreOrders
        .where((o) => o.status != 'cancelled')
        .expand((o) => o.items)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  List<DailySalesPoint> get last7DaysSales {
    const dayLabels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final today = DateTime.now();
    final List<DailySalesPoint> points = [];

    for (int offset = 6; offset >= 0; offset--) {
      final date = DateTime(today.year, today.month, today.day).subtract(Duration(days: offset));
      final matchingOrders = _paidOrCompletedOrders.where((o) =>
          o.createdAt.year == date.year &&
          o.createdAt.month == date.month &&
          o.createdAt.day == date.day);
      final dayTotal = matchingOrders.fold(0.0, (sum, o) => sum + o.subtotal);
      final weekdayIdx = date.weekday % 7; // Sunday=7 -> 0, Monday=1 -> 1
      points.add(
        DailySalesPoint(
          label: dayLabels[weekdayIdx],
          date: date,
          amount: dayTotal,
          orderCount: matchingOrders.length,
        ),
      );
    }
    return points;
  }

  double get availableBalance {
    final withdrawn = _myPayoutRequests
        .where((r) => r.status == 'paid' || r.status == 'processing' || r.status == 'requested')
        .fold(0.0, (sum, r) => sum + r.amount);
    return (totalRevenue - withdrawn).clamp(0.0, double.infinity);
  }

  StoreProvider() {
    loadStores();
    checkMyStore();
  }

  Future<void> loadStores() async {
    _isLoading = true;
    notifyListeners();
    try {
      _stores = await SupabaseService.instance.getStores();
    } catch (e) {
      debugPrint('Error loading stores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkMyStore() async {
    try {
      _myStore = await SupabaseService.instance.getMyStore();
      if (_myStore != null) {
        await loadMyStoreData();
      } else {
        _myStoreProducts = [];
        _myStoreOrders = [];
        _myStoreReviews = [];
        _myStorePromotions = [];
        _myPayoutAccounts = [];
        _myPayoutRequests = [];
      }
    } catch (e) {
      debugPrint('Error checking my store: $e');
    }
    notifyListeners();
  }

  Future<void> loadMyStoreData() async {
    if (_myStore == null) return;
    try {
      _myStoreProducts = await SupabaseService.instance.getStoreProducts(_myStore!.id);
      _myStoreOrders = await SupabaseService.instance.getOrders(storeId: _myStore!.id);
      _myStoreReviews = await SupabaseService.instance.getStoreReviews(_myStore!.id);
      _myStorePromotions = await SupabaseService.instance.getStorePromotions(_myStore!.id);
      _myPayoutAccounts = await SupabaseService.instance.getPayoutAccounts(_myStore!.id);
      _myPayoutRequests = await SupabaseService.instance.getPayoutRequests(_myStore!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading store data: $e');
    }
  }

  Future<bool> registerStore({
    required String storeName,
    required String description,
    required String email,
    required String phone,
    required String address,
    required String province,
    required String city,
    required String district,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? logoPath,
    String? operatingHours,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _myStore = await SupabaseService.instance.registerStore(
        storeName: storeName,
        description: description,
        email: email,
        phone: phone,
        address: address,
        province: province,
        city: city,
        district: district,
        postalCode: postalCode,
        latitude: latitude,
        longitude: longitude,
        logoPath: logoPath,
        operatingHours: operatingHours,
      );
      await loadStores();
      await loadMyStoreData();
      return true;
    } catch (e) {
      debugPrint('Error registering store: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStore(Store store) async {
    final ok = await SupabaseService.instance.updateStore(store);
    if (ok) {
      _myStore = store;
      final idx = _stores.indexWhere((s) => s.id == store.id);
      if (idx != -1) _stores[idx] = store;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> addProduct(Product product) async {
    try {
      final created = await SupabaseService.instance.addProduct(product);
      _myStoreProducts.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final ok = await SupabaseService.instance.updateProduct(product);
      if (ok) {
        final idx = _myStoreProducts.indexWhere((p) => p.id == product.id);
        if (idx != -1) _myStoreProducts[idx] = product;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final ok = await SupabaseService.instance.deleteProduct(productId);
      if (ok) {
        _myStoreProducts.removeWhere((p) => p.id == productId);
        notifyListeners();
      }
      return ok;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  Future<bool> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? trackingNumber,
    String? courierName,
    String? note,
  }) async {
    final ok = await SupabaseService.instance.updateOrderStatus(
      orderId,
      newStatus,
      trackingNumber: trackingNumber,
      courierName: courierName,
      note: note,
      isSellerAction: true,
    );
    if (ok) {
      await loadMyStoreData();
    }
    return ok;
  }

  Future<bool> replyReview(String reviewId, String replyText) async {
    try {
      final ok = await SupabaseService.instance.replyReview(reviewId, replyText);
      if (ok) await loadMyStoreData();
      return ok;
    } catch (e) {
      debugPrint('Error replying review: $e');
      return false;
    }
  }

  Future<void> addPromotion(Promotion promo) async {
    final created = await SupabaseService.instance.addPromotion(promo);
    _myStorePromotions.insert(0, created);
    notifyListeners();
  }

  Future<void> addPayoutAccount({
    required String method,
    required String providerName,
    required String accountHolder,
    required String accountNumber,
  }) async {
    if (_myStore == null) return;
    final acc = await SupabaseService.instance.addPayoutAccount(
      storeId: _myStore!.id,
      method: method,
      providerName: providerName,
      accountHolder: accountHolder,
      accountNumber: accountNumber,
    );
    _myPayoutAccounts.add(acc);
    notifyListeners();
  }

  Future<void> requestPayout(double amount, String payoutAccountId, String? note) async {
    if (_myStore == null) return;
    final req = await SupabaseService.instance.requestPayout(
      storeId: _myStore!.id,
      payoutAccountId: payoutAccountId,
      amount: amount,
      note: note,
    );
    _myPayoutRequests.insert(0, req);
    notifyListeners();
  }

  void clearSession() {
    _myStore = null;
    _myStoreProducts = [];
    _myStoreOrders = [];
    _myStoreReviews = [];
    _myStorePromotions = [];
    _myPayoutAccounts = [];
    _myPayoutRequests = [];
    notifyListeners();
  }
}
