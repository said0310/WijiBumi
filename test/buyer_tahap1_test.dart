import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wijibumi/core/theme/app_theme.dart';
import 'package:wijibumi/core/theme/theme_provider.dart';
import 'package:wijibumi/models/cart_item.dart';
import 'package:wijibumi/models/order.dart';
import 'package:wijibumi/providers/address_provider.dart';
import 'package:wijibumi/providers/app_settings_provider.dart';
import 'package:wijibumi/providers/auth_provider.dart';
import 'package:wijibumi/providers/cart_provider.dart';
import 'package:wijibumi/providers/chat_provider.dart';
import 'package:wijibumi/providers/notification_provider.dart';
import 'package:wijibumi/providers/order_provider.dart';
import 'package:wijibumi/providers/product_provider.dart';
import 'package:wijibumi/providers/store_provider.dart';
import 'package:wijibumi/screens/cart/cart_screen.dart';
import 'package:wijibumi/screens/cart/checkout_screen.dart';
import 'package:wijibumi/screens/home/product_detail_screen.dart';
import 'package:wijibumi/screens/orders/order_detail_screen.dart';
import 'package:wijibumi/screens/orders/orders_screen.dart';
import 'package:wijibumi/screens/orders/shipment_tracking_screen.dart';
import 'package:wijibumi/services/mock_data.dart';
import 'package:wijibumi/services/supabase_service.dart';

final List<int> _transparentPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void close({bool force = false}) {}
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _TestHttpRequest();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _TestHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _TestHttpResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentPng.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      Stream.value(_transparentPng).transform(streamTransformer);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapApp(Widget home) {
  return MultiProvider(
    key: UniqueKey(),
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => StoreProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider()),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => AddressProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        home: home,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseService.instance.currentUser = MockData.defaultUser;
    SupabaseService.instance.stores = List.from(MockData.stores);
    SupabaseService.instance.products = List.from(MockData.products);
    SupabaseService.instance.addresses = List.from(MockData.addresses);
    SupabaseService.instance.orders = List.from(MockData.initialOrders);
    SupabaseService.instance.reviews = List.from(MockData.initialReviews);
    SupabaseService.instance.notifications = List.from(
      MockData.initialNotifications,
    );
    SupabaseService.instance.cartItems = List.from(MockData.initialCart);
  });

  testWidgets(
      'CartScreen surfaces unavailable items, allows deleting them, and blocks checkout until cleared',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    SupabaseService.instance.cartItems = [
      CartItem(
        id: 'cart-ghost-1',
        userId: MockData.defaultUser.id,
        productId: 'prod-deleted',
        quantity: 2,
        createdAt: now,
        updatedAt: now,
        product: null,
      ),
      MockData.initialCart.first,
    ];

    await tester.pumpWidget(_wrapApp(const CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Produk Tidak Tersedia'), findsOneWidget);
    expect(find.text('Produk sudah tidak tersedia (2 item)'), findsOneWidget);
    expect(
      find.text('Hapus produk yang tidak tersedia sebelum checkout.'),
      findsOneWidget,
    );

    ElevatedButton checkoutBtn() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Checkout (2)'),
        );
    expect(checkoutBtn().onPressed, isNull);

    await tester.tap(find.text('Hapus Semua'));
    await tester.pumpAndSettle();

    expect(find.text('Produk Tidak Tersedia'), findsNothing);
    expect(checkoutBtn().onPressed, isNotNull);
  });

  testWidgets(
      'ProductDetailScreen Beli Sekarang runs direct checkout without clearing existing cart & supports courier tariff',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Cart starts with 2 items (3 units total)
    expect(SupabaseService.instance.cartItems.length, 2);
    final initialOrderCount = SupabaseService.instance.orders.length;

    final targetProduct = MockData.products[2]; // Anggrek Rp 115.000
    await tester.pumpWidget(
      _wrapApp(ProductDetailScreen(product: targetProduct)),
    );
    await tester.pumpAndSettle();

    // Rating & totalSales are visible to buyer
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('Terjual 29'), findsOneWidget);

    await tester.tap(find.text('Beli Sekarang'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(find.text('1x ${targetProduct.name}'), findsOneWidget);
    // Existing cart items are NOT included
    expect(find.textContaining('Brokoli Hijau'), findsNothing);

    // Selecting SiCepat Cargo Fresh (Rp 18.000) updates total: 115.000 + 18.000 = 133.000
    await tester.ensureVisible(find.text('SiCepat Cargo Fresh'));
    await tester.tap(find.text('SiCepat Cargo Fresh'));
    await tester.pumpAndSettle();

    final submitBtn = find.widgetWithText(
      ElevatedButton,
      'Buat Pesanan (Rp 133.000)',
    );
    expect(submitBtn, findsOneWidget);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Pesanan Dibuat!'), findsOneWidget);
    // Existing cart stays intact!
    expect(SupabaseService.instance.cartItems.length, 2);
    expect(SupabaseService.instance.orders.length, initialOrderCount + 1);
  });

  testWidgets(
      'OrdersScreen supports Pesanan Diterima on shipped orders & duplicate review prevention, and OrderDetailScreen handles note/cancel/tracking cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_wrapApp(const OrdersScreen()));
    await tester.pumpAndSettle();

    // Shipped order card has Pesanan Diterima CTA
    await tester.ensureVisible(find.text('Pesanan Diterima'));
    await tester.tap(find.text('Pesanan Diterima'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Pesanan Diterima'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Pesanan Diterima'));
    await tester.pumpAndSettle();

    final shippedUpdated = SupabaseService.instance.orders
        .firstWhere((o) => o.id == 'ord-101');
    expect(shippedUpdated.status, 'completed');

    // Already-reviewed ord-102 displays Sudah Diulas instead of Beri Ulasan
    expect(find.text('Sudah Diulas'), findsOneWidget);

    // OrderDetailScreen on pending_payment order shows buyerNote, hides tracking, and supports cancel
    final pendingOrder = SupabaseService.instance.orders
        .firstWhere((o) => o.id == 'ord-103')
        .copyWith(status: 'processing');
    SupabaseService.instance.orders = [pendingOrder];

    await tester.pumpWidget(_wrapApp(OrderDetailScreen(order: pendingOrder)));
    await tester.pumpAndSettle();

    expect(
      find.text('Catatan Pembeli: Segera diproses jika sudah ditransfer'),
      findsOneWidget,
    );
    expect(find.text('Hubungi Penjual'), findsOneWidget);
    expect(find.text('Batalkan Pesanan'), findsOneWidget);

    await tester.ensureVisible(find.text('Batalkan Pesanan'));
    await tester.tap(find.text('Batalkan Pesanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Batalkan Pesanan'));
    await tester.pumpAndSettle();

    expect(
      SupabaseService.instance.orders
          .firstWhere((o) => o.id == 'ord-103')
          .status,
      'cancelled',
    );
  });

  testWidgets(
      'ShipmentTrackingScreen renders honest fallback without fabricated courier when shipment is null',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final orderNoShipment = Order(
      id: 'ord-no-ship',
      orderCode: 'WIJI-TEST-001',
      buyerId: MockData.defaultUser.id,
      storeId: 'store-1-lembang',
      shippingAddressSnapshot: const {},
      status: 'processing',
      paymentStatus: 'paid',
      subtotal: 50000,
      shippingFee: 15000,
      totalAmount: 65000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      shipment: null,
    );

    await tester.pumpWidget(
      _wrapApp(ShipmentTrackingScreen(order: orderNoShipment)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kurir belum ditentukan'), findsOneWidget);
    expect(find.text('Kurir Segar Express'), findsNothing);
    expect(find.text('Layanan Berpendingin'), findsNothing);
  });
}

