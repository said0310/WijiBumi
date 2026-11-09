import 'package:flutter/foundation.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/promotion.dart';
import '../models/payout.dart';
import '../services/supabase_service.dart';

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
  int get incomingOrdersCount => _myStoreOrders.where((o) => o.status == 'pending_payment' || o.status == 'awaiting_confirmation').length;
  int get processingOrdersCount => _myStoreOrders.where((o) => o.status == 'processing' || o.status == 'ready_to_ship').length;
  int get completedOrdersCount => _myStoreOrders.where((o) => o.status == 'completed').length;
  double get totalRevenue => _myStoreOrders
      .where((o) => o.paymentStatus == 'paid' || o.status == 'completed')
      .fold(0.0, (sum, o) => sum + o.subtotal);
  double get availableBalance => totalRevenue - _myPayoutRequests
      .where((r) => r.status == 'paid')
      .fold(0.0, (sum, r) => sum + r.amount);

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
      }
    } catch (e) {
      debugPrint('Error checking my store: $e');
    }
    notifyListeners();
  }

  Future<void> loadMyStoreData() async {
    if (_myStore == null) return;
    _myStoreProducts = await SupabaseService.instance.getStoreProducts(_myStore!.id);
    _myStoreOrders = await SupabaseService.instance.getOrders(storeId: _myStore!.id);
    _myStoreReviews = await SupabaseService.instance.getStoreReviews(_myStore!.id);
    _myStorePromotions = await SupabaseService.instance.getStorePromotions(_myStore!.id);
    _myPayoutAccounts = await SupabaseService.instance.getPayoutAccounts(_myStore!.id);
    _myPayoutRequests = await SupabaseService.instance.getPayoutRequests(_myStore!.id);
    notifyListeners();
  }

  Future<bool> registerStore({
    required String storeName,
    required String description,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String province,
    String? logoPath,
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
        city: city,
        province: province,
        logoPath: logoPath,
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

  Future<void> updateStore(Store store) async {
    await SupabaseService.instance.updateStore(store);
    _myStore = store;
    final idx = _stores.indexWhere((s) => s.id == store.id);
    if (idx != -1) _stores[idx] = store;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final created = await SupabaseService.instance.addProduct(product);
    _myStoreProducts.insert(0, created);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await SupabaseService.instance.updateProduct(product);
    final idx = _myStoreProducts.indexWhere((p) => p.id == product.id);
    if (idx != -1) _myStoreProducts[idx] = product;
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await SupabaseService.instance.deleteProduct(productId);
    _myStoreProducts.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await SupabaseService.instance.updateOrderStatus(orderId, newStatus);
    await loadMyStoreData();
  }

  Future<void> replyReview(String reviewId, String replyText) async {
    await SupabaseService.instance.replyReview(reviewId, replyText);
    await loadMyStoreData();
  }

  Future<void> addPromotion(Promotion promo) async {
    await SupabaseService.instance.addPromotion(promo);
    _myStorePromotions.insert(0, promo);
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
}
