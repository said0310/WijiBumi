import 'package:flutter/foundation.dart' hide Category;
import '../core/config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/store.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/shipment.dart';
import '../models/chat.dart';
import '../models/review.dart';
import '../models/promotion.dart';
import '../models/payout.dart';
import 'mock_data.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  // In-memory data store for fallback/demo mode
  UserProfile currentUser = MockData.defaultUser;
  List<Category> categories = List.from(MockData.categories);
  List<Store> stores = List.from(MockData.stores);
  List<Product> products = List.from(MockData.products);
  List<Address> addresses = List.from(MockData.addresses);
  List<CartItem> cartItems = List.from(MockData.initialCart);
  List<Order> orders = List.from(MockData.initialOrders);
  List<Chat> chats = List.from(MockData.initialChats);
  List<ChatMessage> chatMessages = List.from(MockData.initialChatMessages);
  List<Review> reviews = List.from(MockData.initialReviews);
  List<Promotion> promotions = List.from(MockData.initialPromotions);
  List<PayoutAccount> payoutAccounts = List.from(MockData.initialPayoutAccounts);
  List<PayoutRequest> payoutRequests = List.from(MockData.initialPayoutRequests);

  bool get isConnected => SupabaseConfig.isInitialized && SupabaseConfig.client != null;

  // ------------------ AUTH & PROFILE ------------------

  Future<UserProfile?> getCurrentProfile() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final res = await client.from('profiles').select().eq('id', user.id).maybeSingle();
          if (res != null) {
            currentUser = UserProfile.fromJson(res);
            return currentUser;
          }
        }
      } catch (e) {
        debugPrint('Supabase getProfile error: $e');
      }
    }
    return currentUser;
  }

  Future<bool> updateProfile(UserProfile profile) async {
    currentUser = profile;
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('profiles').update(profile.toJson()).eq('id', profile.id);
        return true;
      } catch (e) {
        debugPrint('Supabase updateProfile error: $e');
      }
    }
    return true;
  }

  // ------------------ STORES ------------------

  Future<List<Store>> getStores() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client
            .from('stores')
            .select()
            .eq('verification_status', 'approved')
            .eq('is_active', true);
        return (res as List).map((e) => Store.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getStores error: $e');
      }
    }
    return stores.where((s) => s.isApproved).toList();
  }

  Future<Store?> getStoreById(String storeId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('stores').select().eq('id', storeId).maybeSingle();
        if (res != null) return Store.fromJson(res);
      } catch (e) {
        debugPrint('Supabase getStoreById error: $e');
      }
    }
    try {
      return stores.firstWhere((s) => s.id == storeId);
    } catch (_) {
      return null;
    }
  }

  Future<Store?> getMyStore() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final res = await client.from('stores').select().eq('owner_id', user.id).maybeSingle();
          if (res != null) return Store.fromJson(res);
        }
      } catch (e) {
        debugPrint('Supabase getMyStore error: $e');
      }
    }
    try {
      return stores.firstWhere((s) => s.ownerId == currentUser.id);
    } catch (_) {
      return null;
    }
  }

  Future<Store> registerStore({
    required String storeName,
    required String description,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String province,
    String? logoPath,
  }) async {
    final slug = storeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    final newStore = Store(
      id: 'store-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: currentUser.id,
      storeName: storeName,
      slug: slug,
      description: description,
      email: email,
      phone: phone,
      address: address,
      city: city,
      province: province,
      logoPath: logoPath ?? 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
      verificationStatus: 'approved', // Auto-approved in prototype/demo for ease of testing seller dashboard
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    stores.add(newStore);

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('stores').insert(newStore.toJson()).select().single();
        return Store.fromJson(res);
      } catch (e) {
        debugPrint('Supabase registerStore error: $e');
      }
    }
    return newStore;
  }

  Future<bool> updateStore(Store store) async {
    final idx = stores.indexWhere((s) => s.id == store.id);
    if (idx != -1) stores[idx] = store;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('stores').update(store.toJson()).eq('id', store.id);
        return true;
      } catch (e) {
        debugPrint('Supabase updateStore error: $e');
      }
    }
    return true;
  }

  // ------------------ PRODUCTS ------------------

  Future<List<Category>> getCategories() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('categories').select();
        return (res as List).map((e) => Category.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getCategories error: $e');
      }
    }
    return categories;
  }

  Future<List<Product>> getProducts({String? categoryId, String? searchQuery, String? storeId}) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        var query = client.from('products').select('''
          *,
          stores (store_name, city, logo_path),
          categories (name),
          product_images (storage_path)
        ''').eq('status', 'active');

        if (categoryId != null && categoryId.isNotEmpty) {
          query = query.eq('category_id', categoryId);
        }
        if (storeId != null && storeId.isNotEmpty) {
          query = query.eq('store_id', storeId);
        }

        final res = await query;
        var list = (res as List).map((e) => Product.fromJson(e)).toList();
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          list = list.where((p) => p.name.toLowerCase().contains(q) || (p.storeName?.toLowerCase().contains(q) ?? false)).toList();
        }
        return list;
      } catch (e) {
        debugPrint('Supabase getProducts error: $e');
      }
    }

    var list = products.where((p) => p.status == 'active').toList();
    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (storeId != null && storeId.isNotEmpty) {
      list = list.where((p) => p.storeId == storeId).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || (p.storeName?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  Future<List<Product>> getStoreProducts(String storeId) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('products').select('''
          *,
          stores (store_name, city, logo_path),
          categories (name),
          product_images (storage_path)
        ''').eq('store_id', storeId);
        return (res as List).map((e) => Product.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getStoreProducts error: $e');
      }
    }
    return products.where((p) => p.storeId == storeId).toList();
  }

  Future<Product> addProduct(Product product) async {
    products.add(product);
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('products').insert(product.toJson()).select().single();
        final created = Product.fromJson(res);
        if (product.images.isNotEmpty) {
          for (int i = 0; i < product.images.length; i++) {
            await client.from('product_images').insert({
              'product_id': created.id,
              'storage_path': product.images[i],
              'sort_order': i,
              'is_primary': i == 0,
            });
          }
        }
        return created;
      } catch (e) {
        debugPrint('Supabase addProduct error: $e');
      }
    }
    return product;
  }

  Future<bool> updateProduct(Product product) async {
    final idx = products.indexWhere((p) => p.id == product.id);
    if (idx != -1) products[idx] = product;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('products').update(product.toJson()).eq('id', product.id);
        return true;
      } catch (e) {
        debugPrint('Supabase updateProduct error: $e');
      }
    }
    return true;
  }

  Future<bool> deleteProduct(String productId) async {
    products.removeWhere((p) => p.id == productId);
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('products').delete().eq('id', productId);
        return true;
      } catch (e) {
        debugPrint('Supabase deleteProduct error: $e');
      }
    }
    return true;
  }

  // ------------------ CART ------------------

  Future<List<CartItem>> getCart() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final res = await client.from('cart_items').select('''
            *,
            products (
              *,
              stores (store_name, city, logo_path),
              categories (name),
              product_images (storage_path)
            )
          ''').eq('user_id', user.id);
          return (res as List).map((e) => CartItem.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint('Supabase getCart error: $e');
      }
    }
    return cartItems;
  }

  Future<void> addToCart(Product product, int quantity) async {
    final existingIdx = cartItems.indexWhere((c) => c.productId == product.id);
    if (existingIdx != -1) {
      cartItems[existingIdx].quantity += quantity;
    } else {
      cartItems.add(
        CartItem(
          id: 'cart-${DateTime.now().millisecondsSinceEpoch}',
          userId: currentUser.id,
          productId: product.id,
          quantity: quantity,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          product: product,
        ),
      );
    }

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          await client.from('cart_items').upsert({
            'user_id': user.id,
            'product_id': product.id,
            'quantity': quantity,
          }, onConflict: 'user_id,product_id');
        }
      } catch (e) {
        debugPrint('Supabase addToCart error: $e');
      }
    }
  }

  Future<void> updateCartQuantity(String cartItemId, int newQty) async {
    if (newQty <= 0) {
      await removeFromCart(cartItemId);
      return;
    }
    final item = cartItems.firstWhere((c) => c.id == cartItemId);
    item.quantity = newQty;

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('cart_items').update({'quantity': newQty}).eq('id', cartItemId);
      } catch (e) {
        debugPrint('Supabase updateCartQuantity error: $e');
      }
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    cartItems.removeWhere((c) => c.id == cartItemId);
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('cart_items').delete().eq('id', cartItemId);
      } catch (e) {
        debugPrint('Supabase removeFromCart error: $e');
      }
    }
  }

  Future<void> clearCart() async {
    cartItems.clear();
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          await client.from('cart_items').delete().eq('user_id', user.id);
        }
      } catch (e) {
        debugPrint('Supabase clearCart error: $e');
      }
    }
  }

  // ------------------ ADDRESSES ------------------

  Future<List<Address>> getAddresses() async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        if (user != null) {
          final res = await client.from('addresses').select().eq('user_id', user.id);
          return (res as List).map((e) => Address.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint('Supabase getAddresses error: $e');
      }
    }
    return addresses;
  }

  Future<Address> addAddress(Address address) async {
    addresses.add(address);
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final res = await client.from('addresses').insert(address.toJson()).select().single();
        return Address.fromJson(res);
      } catch (e) {
        debugPrint('Supabase addAddress error: $e');
      }
    }
    return address;
  }

  // ------------------ ORDERS & CHECKOUT ------------------

  Future<List<Order>> getOrders({String? status, String? storeId}) async {
    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        final user = client.auth.currentUser;
        var query = client.from('orders').select('''
          *,
          stores (store_name),
          order_items (*),
          shipments (
            *,
            shipment_tracking (*)
          ),
          payments (*)
        ''');

        if (storeId != null && storeId.isNotEmpty) {
          query = query.eq('store_id', storeId);
        } else if (user != null) {
          query = query.eq('buyer_id', user.id);
        }

        if (status != null && status.isNotEmpty) {
          query = query.eq('status', status);
        }

        final res = await query.order('created_at', ascending: false);
        return (res as List).map((e) => Order.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Supabase getOrders error: $e');
      }
    }

    var list = List<Order>.from(orders);
    if (storeId != null && storeId.isNotEmpty) {
      list = list.where((o) => o.storeId == storeId).toList();
    } else {
      list = list.where((o) => o.buyerId == currentUser.id).toList();
    }
    if (status != null && status.isNotEmpty) {
      list = list.where((o) => o.status == status).toList();
    }
    return list;
  }

  Future<List<Order>> createCheckoutOrders({
    required Address address,
    required String paymentMethod,
    required String courierName,
    required String? buyerNote,
  }) async {
    // Group cart items by store_id
    final Map<String, List<CartItem>> itemsByStore = {};
    for (var item in cartItems) {
      if (item.product != null) {
        final sId = item.product!.storeId;
        itemsByStore.putIfAbsent(sId, () => []).add(item);
      }
    }

    final List<Order> createdOrders = [];

    for (var entry in itemsByStore.entries) {
      final storeId = entry.key;
      final storeCartItems = entry.value;
      final store = stores.firstWhere((s) => s.id == storeId, orElse: () => stores.first);

      double subtotal = 0;
      final List<OrderItem> orderItemsList = [];
      final orderId = 'ord-${DateTime.now().millisecondsSinceEpoch}-${createdOrders.length}';
      final orderCode = 'TANI-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${100 + createdOrders.length}';

      for (var ci in storeCartItems) {
        final p = ci.product!;
        final lineTot = p.price * ci.quantity;
        subtotal += lineTot;

        orderItemsList.add(
          OrderItem(
            id: 'item-$orderId-${orderItemsList.length}',
            orderId: orderId,
            productId: p.id,
            productNameSnapshot: p.name,
            unitSnapshot: p.unit,
            unitPrice: p.price,
            quantity: ci.quantity,
            lineTotal: lineTot,
            qualityGradeSnapshot: p.qualityGrade,
            imageSnapshot: p.primaryImage,
          ),
        );

        // Deduct stock
        final pIdx = products.indexWhere((prod) => prod.id == p.id);
        if (pIdx != -1) {
          final newStock = (products[pIdx].stock - ci.quantity).clamp(0, 999999);
          products[pIdx] = products[pIdx].copyWith(stock: newStock);
        }
      }

      const shippingFee = 15000.0;
      final totalAmount = subtotal + shippingFee;

      final initialStatus = paymentMethod == 'COD (Bayar di Tempat)' ? 'processing' : 'pending_payment';
      final paymentStatus = paymentMethod == 'COD (Bayar di Tempat)' ? 'pending' : 'unpaid';

      final newOrder = Order(
        id: orderId,
        orderCode: orderCode,
        buyerId: currentUser.id,
        storeId: storeId,
        addressId: address.id,
        shippingAddressSnapshot: {
          'recipient_name': address.recipientName,
          'phone': address.phone,
          'address': address.fullAddressText,
        },
        status: initialStatus,
        paymentStatus: paymentStatus,
        subtotal: subtotal,
        shippingFee: shippingFee,
        discountTotal: 0.0,
        totalAmount: totalAmount,
        buyerNote: buyerNote,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        storeName: store.storeName,
        buyerName: currentUser.fullName,
        items: orderItemsList,
        payment: Payment(
          id: 'pay-$orderId',
          orderId: orderId,
          paymentMethod: paymentMethod,
          amount: totalAmount,
          status: paymentStatus,
        ),
        shipment: Shipment(
          id: 'ship-$orderId',
          orderId: orderId,
          courierName: courierName,
          serviceName: 'Reguler Fresh Cargo',
          trackingNumber: 'TN${DateTime.now().millisecondsSinceEpoch}',
          status: 'waiting',
          estimatedArrival: DateTime.now().add(const Duration(days: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          trackingHistory: [
            ShipmentTracking(
              id: 'trk-$orderId-1',
              shipmentId: 'ship-$orderId',
              status: 'waiting',
              description: 'Pesanan berhasil dibuat, menunggu konfirmasi penjual',
              location: store.city ?? 'Kebun Petani',
              eventAt: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          ],
        ),
      );

      orders.insert(0, newOrder);
      createdOrders.add(newOrder);

      if (isConnected) {
        try {
          final client = SupabaseConfig.client!;
          await client.from('orders').insert(newOrder.toJson());
          for (var item in orderItemsList) {
            await client.from('order_items').insert(item.toJson());
          }
          if (newOrder.shipment != null) {
            await client.from('shipments').insert(newOrder.shipment!.toJson());
          }
        } catch (e) {
          debugPrint('Supabase createOrder error: $e');
        }
      }
    }

    // Clear cart after checkout
    await clearCart();
    return createdOrders;
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final current = orders[idx];
      var newPaymentStatus = current.paymentStatus;
      if (newStatus == 'completed') {
        newPaymentStatus = 'paid';
      }

      Shipment? updatedShipment = current.shipment;
      if (updatedShipment != null) {
        final trackingHist = List<ShipmentTracking>.from(updatedShipment.trackingHistory);
        String desc = 'Status diperbarui menjadi: $newStatus';
        String shipStatus = updatedShipment.status;

        if (newStatus == 'processing') {
          desc = 'Penjual sedang menyiapkan dan mengemas produk hasil panen';
        } else if (newStatus == 'ready_to_ship') {
          desc = 'Paket siap dijemput oleh kurir pengiriman';
        } else if (newStatus == 'shipped') {
          desc = 'Paket telah dibawa kurir dan sedang dalam perjalanan';
          shipStatus = 'in_transit';
        } else if (newStatus == 'completed') {
          desc = 'Pesanan telah diterima oleh pembeli. Transaksi selesai!';
          shipStatus = 'delivered';
        }

        trackingHist.insert(
          0,
          ShipmentTracking(
            id: 'trk-${DateTime.now().millisecondsSinceEpoch}',
            shipmentId: updatedShipment.id,
            status: shipStatus,
            description: desc,
            location: 'Lokasi Kurir',
            eventAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );

        updatedShipment = updatedShipment.copyWith(
          status: shipStatus,
          trackingHistory: trackingHist,
          deliveredAt: newStatus == 'completed' ? DateTime.now() : null,
        );
      }

      orders[idx] = current.copyWith(
        status: newStatus,
        paymentStatus: newPaymentStatus,
        shipment: updatedShipment,
      );
    }

    if (isConnected) {
      try {
        final client = SupabaseConfig.client!;
        await client.from('orders').update({'status': newStatus}).eq('id', orderId);
        return true;
      } catch (e) {
        debugPrint('Supabase updateOrderStatus error: $e');
      }
    }
    return true;
  }

  // ------------------ CHAT ------------------

  Future<List<Chat>> getChats() async {
    return chats;
  }

  Future<List<ChatMessage>> getChatMessages(String chatId) async {
    return chatMessages.where((m) => m.chatId == chatId).toList();
  }

  Future<Chat> startOrGetChat({required String storeId, String? productId}) async {
    final existing = chats.where((c) => c.buyerId == currentUser.id && c.storeId == storeId);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final store = stores.firstWhere((s) => s.id == storeId, orElse: () => stores.first);
    Product? p;
    if (productId != null) {
      try {
        p = products.firstWhere((prod) => prod.id == productId);
      } catch (_) {}
    }

    final newChat = Chat(
      id: 'chat-${DateTime.now().millisecondsSinceEpoch}',
      buyerId: currentUser.id,
      storeId: storeId,
      productId: productId,
      createdAt: DateTime.now(),
      storeName: store.storeName,
      storeLogo: store.logoPath,
      buyerName: currentUser.fullName,
      productName: p?.name,
      productImage: p?.primaryImage,
    );

    chats.insert(0, newChat);
    return newChat;
  }

  Future<ChatMessage> sendChatMessage({
    required String chatId,
    required String body,
    String? mediaPath,
  }) async {
    final newMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: currentUser.id,
      messageType: mediaPath != null ? 'image' : 'text',
      body: body,
      mediaPath: mediaPath,
      createdAt: DateTime.now(),
    );

    chatMessages.add(newMsg);

    // Update chat last message
    final cIdx = chats.indexWhere((c) => c.id == chatId);
    if (cIdx != -1) {
      final old = chats[cIdx];
      chats[cIdx] = Chat(
        id: old.id,
        buyerId: old.buyerId,
        storeId: old.storeId,
        productId: old.productId,
        lastMessageAt: DateTime.now(),
        createdAt: old.createdAt,
        storeName: old.storeName,
        storeLogo: old.storeLogo,
        buyerName: old.buyerName,
        lastMessageBody: body,
        productName: old.productName,
        productImage: old.productImage,
      );
    }

    return newMsg;
  }

  // ------------------ REVIEWS ------------------

  Future<List<Review>> getStoreReviews(String storeId) async {
    return reviews.where((r) => r.storeId == storeId).toList();
  }

  Future<Review> addReview({
    required String orderId,
    required String storeId,
    String? productId,
    required int rating,
    required String reviewText,
  }) async {
    final newReview = Review(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      reviewerId: currentUser.id,
      storeId: storeId,
      productId: productId,
      rating: rating,
      reviewText: reviewText,
      createdAt: DateTime.now(),
      reviewerName: currentUser.fullName,
      reviewerAvatar: currentUser.avatarPath,
    );
    reviews.insert(0, newReview);
    return newReview;
  }

  Future<bool> replyReview(String reviewId, String replyText) async {
    final idx = reviews.indexWhere((r) => r.id == reviewId);
    if (idx != -1) {
      reviews[idx] = reviews[idx].copyWith(
        replyText: replyText,
        repliedAt: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  // ------------------ PROMOTIONS ------------------

  Future<List<Promotion>> getStorePromotions(String storeId) async {
    return promotions.where((p) => p.storeId == storeId).toList();
  }

  Future<Promotion> addPromotion(Promotion promo) async {
    promotions.insert(0, promo);
    return promo;
  }

  // ------------------ PAYOUTS ------------------

  Future<List<PayoutAccount>> getPayoutAccounts(String storeId) async {
    return payoutAccounts.where((p) => p.storeId == storeId).toList();
  }

  Future<List<PayoutRequest>> getPayoutRequests(String storeId) async {
    return payoutRequests.where((p) => p.storeId == storeId).toList();
  }

  Future<PayoutRequest> requestPayout({
    required String storeId,
    required String payoutAccountId,
    required double amount,
    String? note,
  }) async {
    final acc = payoutAccounts.firstWhere((a) => a.id == payoutAccountId);
    final req = PayoutRequest(
      id: 'preq-${DateTime.now().millisecondsSinceEpoch}',
      storeId: storeId,
      payoutAccountId: payoutAccountId,
      amount: amount,
      status: 'requested',
      referenceNumber: 'PO-${DateTime.now().millisecondsSinceEpoch}',
      note: note,
      requestedAt: DateTime.now(),
      account: acc,
    );
    payoutRequests.insert(0, req);
    return req;
  }
}
