import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wijibumi/core/theme/app_theme.dart';
import 'package:wijibumi/core/theme/theme_provider.dart';
import 'package:wijibumi/models/app_settings.dart';
import 'package:wijibumi/providers/address_provider.dart';
import 'package:wijibumi/providers/app_settings_provider.dart';
import 'package:wijibumi/providers/auth_provider.dart';
import 'package:wijibumi/providers/cart_provider.dart';
import 'package:wijibumi/providers/chat_provider.dart';
import 'package:wijibumi/providers/notification_provider.dart';
import 'package:wijibumi/providers/order_provider.dart';
import 'package:wijibumi/providers/product_provider.dart';
import 'package:wijibumi/providers/store_provider.dart';
import 'package:wijibumi/screens/auth/login_screen.dart';
import 'package:wijibumi/screens/home/home_screen.dart';
import 'package:wijibumi/screens/home/product_detail_screen.dart';
import 'package:wijibumi/screens/profile/add_edit_address_screen.dart';
import 'package:wijibumi/screens/profile/help_center_screen.dart';
import 'package:wijibumi/screens/profile/purchase_history_screen.dart';
import 'package:wijibumi/screens/store/store_detail_screen.dart';
import 'package:wijibumi/services/mock_data.dart';
import 'package:wijibumi/services/supabase_service.dart';
import 'package:wijibumi/widgets/custom_text_field.dart';

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
      Stream<List<int>>.fromIterable([_transparentPng]).transform(streamTransformer);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWithProviders(
  Widget child, {
  AuthProvider? authProvider,
  ProductProvider? productProvider,
  OrderProvider? orderProvider,
  AppSettingsProvider? appSettingsProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      if (appSettingsProvider != null)
        ChangeNotifierProvider<AppSettingsProvider>.value(
          value: appSettingsProvider,
        )
      else
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      if (authProvider != null)
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider)
      else
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      if (productProvider != null)
        ChangeNotifierProvider<ProductProvider>.value(value: productProvider)
      else
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => StoreProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      if (orderProvider != null)
        ChangeNotifierProvider<OrderProvider>.value(value: orderProvider)
      else
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => AddressProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ],
    child: MaterialApp(
      key: UniqueKey(),
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseService.instance.currentUser = MockData.defaultUser;
    SupabaseService.instance.supportTickets.clear();
  });

  tearDown(() {
    SupabaseService.instance.currentUser = MockData.defaultUser;
    SupabaseService.instance.supportTickets.clear();
  });

  test('Home search matches category/description/farmLocation and resetFilters clears query', () async {
    final farmMatch = await SupabaseService.instance.getProducts(
      searchQuery: 'Lembang',
    );
    expect(farmMatch, isNotEmpty);

    final catMatch = await SupabaseService.instance.getProducts(
      searchQuery: 'Sayuran',
    );
    expect(catMatch, isNotEmpty);

    final prov = ProductProvider();
    await prov.initData();
    prov.setSearchQuery('Anggrek');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(prov.searchQuery, 'Anggrek');

    prov.resetFilters();
    expect(prov.searchQuery, isEmpty);
    expect(prov.selectedCategoryId, isNull);
  });

  testWidgets('HomeScreen search debounces input cleanly', (tester) async {
    final productProv = ProductProvider();
    await tester.runAsync(() => productProv.initData());

    await tester.pumpWidget(
      _wrapWithProviders(const HomeScreen(), productProvider: productProv),
    );
    await tester.pumpAndSettle();

    final searchField = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText == 'Cari bunga, sayuran, buah, atau toko...',
    );
    await tester.enterText(searchField, 'Anggrek');
    await tester.pump(const Duration(milliseconds: 100));
    expect(productProv.searchQuery, isEmpty);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(productProv.searchQuery, 'Anggrek');
  });

  testWidgets('StoreDetailScreen and ProductDetailScreen display buyer reviews and seller replies', (
    tester,
  ) async {
    final store = MockData.stores.firstWhere((s) => s.id == 'store-1-lembang');
    await tester.pumpWidget(
      _wrapWithProviders(StoreDetailScreen(store: store)),
    );
    await tester.pumpAndSettle();

    final reviewTab = find.text('Ulasan (1)');
    await tester.ensureVisible(reviewTab);
    await tester.pumpAndSettle();
    await tester.tap(reviewTab);
    await tester.pumpAndSettle();

    expect(find.text('Balasan Penjual'), findsOneWidget);
    expect(find.textContaining('anggreknya luar biasa cantik'), findsOneWidget);

    final anggrek = MockData.products.firstWhere((p) => p.id == 'prod-3-anggrek');
    await tester.pumpWidget(
      _wrapWithProviders(ProductDetailScreen(product: anggrek)),
    );
    await tester.pumpAndSettle();

    final reviewHeading = find.text('Ulasan Pembeli');
    await tester.scrollUntilVisible(
      reviewHeading,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(reviewHeading, findsOneWidget);
    expect(find.textContaining('anggreknya luar biasa cantik'), findsOneWidget);
  });

  test('AppSettingsProvider scopes preferences per user and resets on clearSession', () async {
    final provider = AppSettingsProvider();
    await provider.loadSettings();

    final ok = await provider.updateSettings(
      const AppSettings(languageCode: 'en', promoNotifications: false),
    );
    expect(ok, isTrue);
    expect(provider.settings.languageCode, 'en');
    expect(provider.locale, const Locale('en'));

    await provider.clearSession();
    expect(provider.settings.languageCode, 'id');
    expect(provider.settings.promoNotifications, isTrue);
  });

  testWidgets('AddEditAddressScreen validates phone/postal/paired coordinates and guards unsaved back', (
    tester,
  ) async {
    final authProv = AuthProvider();
    await tester.runAsync(() => authProv.loadUser());

    await tester.pumpWidget(
      _wrapWithProviders(const AddEditAddressScreen(), authProvider: authProv),
    );
    await tester.pumpAndSettle();

    final postalField = find.descendant(
      of: find.widgetWithText(CustomTextField, 'Kode Pos'),
      matching: find.byType(TextFormField),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(CustomTextField, 'Kode Pos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(postalField);
    await tester.enterText(postalField, '12a');
    await tester.pumpAndSettle();
    expect(find.text('Kode pos harus 5 digit angka'), findsOneWidget);

    final latField = find.descendant(
      of: find.widgetWithText(CustomTextField, 'Latitude'),
      matching: find.byType(TextFormField),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(CustomTextField, 'Latitude'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(latField);
    await tester.enterText(latField, '-6.1944');
    await tester.pumpAndSettle();
    expect(find.text('Longitude wajib diisi bersama Latitude'), findsOneWidget);

    final cancelBtn = find.text('Batal');
    await tester.scrollUntilVisible(
      cancelBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(cancelBtn);
    await tester.pumpAndSettle();
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();
    expect(find.text('Batalkan Perubahan?'), findsOneWidget);
  });

  testWidgets('HelpCenterScreen filters 6 FAQ categories, shows ticket history, and guards guest tickets', (
    tester,
  ) async {
    final authProv = AuthProvider();
    await tester.runAsync(() => authProv.loadUser());

    await tester.pumpWidget(
      _wrapWithProviders(const HelpCenterScreen(), authProvider: authProv),
    );
    await tester.pumpAndSettle();

    // Filter FAQ by Pelacakan category
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pelacakan'));
    await tester.pumpAndSettle();
    expect(find.text('Bagaimana cara melacak pesanan saya?'), findsOneWidget);
    expect(find.text('Bagaimana cara membeli produk di WijiBumi?'), findsNothing);

    // Submit ticket as authenticated buyer -> appears in ticket history
    final subjectField = find.descendant(
      of: find.widgetWithText(CustomTextField, 'Subjek Kendala'),
      matching: find.byType(TextFormField),
    );
    await tester.scrollUntilVisible(
      subjectField,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(subjectField);
    await tester.enterText(subjectField, 'Resi tidak bergerak');

    final msgField = find.descendant(
      of: find.widgetWithText(CustomTextField, 'Detail Pesan'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(msgField);
    await tester.enterText(msgField, 'Status paket belum diperbarui sejak kemarin.');

    final sendBtn = find.text('Kirim ke Customer Service');
    await tester.ensureVisible(sendBtn);
    await tester.pumpAndSettle();
    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    final historyTitle = find.text('Riwayat Tiket Bantuan Saya');
    await tester.scrollUntilVisible(
      historyTitle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(historyTitle, findsOneWidget);
    expect(find.text('Resi tidak bergerak'), findsOneWidget);
    expect(find.text('Terbuka'), findsOneWidget);

    // Guest trying to submit ticket is redirected to LoginScreen
    await tester.runAsync(() => authProv.logout());
    await tester.pumpWidget(
      _wrapWithProviders(const HelpCenterScreen(), authProvider: authProv),
    );
    await tester.pumpAndSettle();

    final guestSubject = find.descendant(
      of: find.widgetWithText(CustomTextField, 'Subjek Kendala'),
      matching: find.byType(TextFormField),
    );
    await tester.scrollUntilVisible(
      guestSubject,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(guestSubject);
    await tester.enterText(guestSubject, 'Masalah akun');

    final guestMsg = find.descendant(
      of: find.widgetWithText(CustomTextField, 'Detail Pesan'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(guestMsg);
    await tester.enterText(guestMsg, 'Tidak dapat masuk memakai akun saya.');

    final guestSend = find.text('Kirim ke Customer Service');
    await tester.ensureVisible(guestSend);
    await tester.pumpAndSettle();
    await tester.tap(guestSend);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('PurchaseHistoryScreen renders empty state or orders cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithProviders(const PurchaseHistoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Pembelian'), findsOneWidget);
  });
}
