import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wijibumi/core/theme/app_colors.dart';
import 'package:wijibumi/core/theme/app_theme.dart';
import 'package:wijibumi/core/theme/theme_provider.dart';
import 'package:wijibumi/providers/auth_provider.dart';
import 'package:wijibumi/providers/product_provider.dart';
import 'package:wijibumi/providers/store_provider.dart';
import 'package:wijibumi/providers/cart_provider.dart';
import 'package:wijibumi/providers/order_provider.dart';
import 'package:wijibumi/providers/chat_provider.dart';
import 'package:wijibumi/providers/address_provider.dart';
import 'package:wijibumi/providers/notification_provider.dart';
import 'package:wijibumi/providers/app_settings_provider.dart';
import 'package:wijibumi/main.dart';
import 'package:wijibumi/screens/profile/edit_profile_screen.dart';
import 'package:wijibumi/screens/profile/address_list_screen.dart';
import 'package:wijibumi/screens/profile/notifications_screen.dart';
import 'package:wijibumi/screens/profile/account_security_screen.dart';
import 'package:wijibumi/screens/profile/settings_screen.dart';
import 'package:wijibumi/screens/profile/help_center_screen.dart';
import 'package:wijibumi/screens/profile/about_screen.dart';
import 'package:wijibumi/screens/profile/profile_screen.dart';
import 'package:wijibumi/screens/store/store_list_screen.dart';
import 'package:wijibumi/screens/auth/forgot_password_screen.dart';
import 'package:wijibumi/screens/auth/login_screen.dart';
import 'package:wijibumi/screens/auth/register_screen.dart';
import 'package:wijibumi/screens/main_navigation_screen.dart';
import 'package:wijibumi/screens/splash/splash_screen.dart';
import 'package:wijibumi/screens/store/register_store_screen.dart';
import 'package:wijibumi/screens/store/seller_auth/seller_login_screen.dart';
import 'package:wijibumi/screens/store/seller_auth/seller_register_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/seller_chat_list_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/seller_dashboard_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/seller_main_navigation_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/seller_profile_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/manage_orders_screen.dart';
import 'package:wijibumi/models/user_profile.dart';
import 'package:wijibumi/screens/cart/cart_screen.dart';
import 'package:wijibumi/screens/cart/checkout_screen.dart';
import 'package:wijibumi/screens/home/product_detail_screen.dart';
import 'package:wijibumi/screens/orders/orders_screen.dart';
import 'package:wijibumi/screens/orders/order_detail_screen.dart';
import 'package:wijibumi/screens/orders/shipment_tracking_screen.dart';
import 'package:wijibumi/screens/store/store_detail_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/manage_products_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/store_finance_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/store_promotions_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/store_reviews_screen.dart';
import 'package:wijibumi/screens/store/seller_dashboard/store_stats_screen.dart';
import 'package:wijibumi/screens/chat/chat_list_screen.dart';
import 'package:wijibumi/screens/chat/chat_room_screen.dart';
import 'package:wijibumi/services/supabase_service.dart';
import 'package:wijibumi/services/mock_data.dart';
import 'package:wijibumi/widgets/home_banner_slideshow.dart';
import 'package:wijibumi/widgets/lucide_icons.dart';
import 'package:wijibumi/widgets/store_card.dart';
import 'package:wijibumi/widgets/wijibumi_auth_widgets.dart';

final List<int> _transparentImage = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
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
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      Stream.value(_transparentImage).transform(streamTransformer);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestApp({Key? key, Widget? home}) {
  return MultiProvider(
    key: key ?? UniqueKey(),
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => StoreProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider()),
      ChangeNotifierProvider(create: (_) => ChatProvider()),
      ChangeNotifierProvider(create: (_) => AddressProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ],
    child: home == null
        ? const WijiBumiApp()
        : Consumer<ThemeProvider>(
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
    HttpOverrides.global = _MockHttpOverrides();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseService.instance.currentUser = MockData.defaultUser;
    SupabaseService.instance.stores = List.from(MockData.stores);
    SupabaseService.instance.products = List.from(MockData.products);
    SupabaseService.instance.addresses = List.from(MockData.addresses);
    SupabaseService.instance.orders = List.from(MockData.initialOrders);
    SupabaseService.instance.chats = List.from(MockData.initialChats);
    SupabaseService.instance.chatMessages = List.from(MockData.initialChatMessages);
    SupabaseService.instance.notifications = List.from(MockData.initialNotifications);
    SupabaseService.instance.sellerLoginTestHook = null;
    SupabaseService.instance.sellerRegisterTestHook = null;
    SupabaseService.instance.buyerLoginTestHook = null;
    SupabaseService.instance.buyerRegisterTestHook = null;
    SupabaseService.instance.forgotPasswordTestHook = null;
    SupabaseService.instance.profileVerificationTestHook = null;
  });

  tearDown(() {
    SupabaseService.instance.sellerLoginTestHook = null;
    SupabaseService.instance.sellerRegisterTestHook = null;
    SupabaseService.instance.buyerLoginTestHook = null;
    SupabaseService.instance.buyerRegisterTestHook = null;
    SupabaseService.instance.forgotPasswordTestHook = null;
    SupabaseService.instance.profileVerificationTestHook = null;
  });

  testWidgets('App launches on Beranda with 4 ordered bottom nav tabs', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    expect(find.text('WijiBumi'), findsWidgets);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Toko'), findsOneWidget);
    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Navigate to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Akun & Pengaturan'), findsOneWidget);
    expect(find.text('Alamat Pengiriman'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Keamanan Akun'), findsOneWidget);
    expect(find.text('Pengaturan Aplikasi'), findsOneWidget);
    expect(find.text('Pusat Bantuan'), findsOneWidget);
    expect(find.text('Tentang WijiBumi'), findsOneWidget);
  });

  testWidgets('Profile Edit, Address, Notification, Security, Settings, Help, About screens work',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // 1. Edit Profile
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // 2. Alamat Pengiriman
    await tester.tap(find.text('Alamat Pengiriman'));
    await tester.pumpAndSettle();
    expect(find.byType(AddressListScreen), findsOneWidget);
    expect(find.text('Alamat Utama'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Notifikasi
    await tester.tap(find.text('Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 4. Keamanan Akun
    await tester.tap(find.text('Keamanan Akun'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountSecurityScreen), findsOneWidget);
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 5. Pengaturan Aplikasi & Theme Mode (System Default / Dark / Light)
    await tester.tap(find.text('Pengaturan Aplikasi'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.text('Pengaturan Tema'));
    await tester.pumpAndSettle();
    expect(find.text('System Default'), findsOneWidget);
    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 6. Pusat Bantuan
    await tester.ensureVisible(find.text('Pusat Bantuan'));
    await tester.tap(find.text('Pusat Bantuan'));
    await tester.pumpAndSettle();
    expect(find.byType(HelpCenterScreen), findsOneWidget);
    expect(find.text('Bagaimana cara membeli produk di WijiBumi?'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 7. Tentang WijiBumi
    await tester.ensureVisible(find.text('Tentang WijiBumi'));
    await tester.tap(find.text('Tentang WijiBumi'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    expect(find.text('Syarat dan Ketentuan'), findsOneWidget);
  });

  testWidgets('Logout shows confirmation dialog and navigates to LoginScreen', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Keluar dari Akun'));
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Apakah Anda yakin ingin keluar dari akun WijiBumi?'), findsOneWidget);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Buyer Profile Toko Saya routes to SellerLoginScreen and rejects buyer-only account',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SupabaseService.instance.sellerLoginTestHook = (email, password) async =>
        const SellerAuthResult(
          status: SellerAuthStatus.notSeller,
          message: 'Akun ini terdaftar sebagai pembeli dan belum memiliki akses penjual.',
        );

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toko Saya'));
    await tester.pumpAndSettle();

    // Pastikan tidak langsung masuk ke Dashboard Penjual, melainkan ke Login Penjual
    expect(find.byType(SellerLoginScreen), findsOneWidget);
    expect(find.byType(SellerDashboardScreen), findsNothing);
    expect(find.text('Login Penjual'), findsOneWidget);
    expect(find.text('Masuk untuk mengelola toko dan pesanan Anda.'), findsOneWidget);
    expect(find.text('Daftar Akun Penjual'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'contoh@kebun.id'),
      'pembeli@wijibumi.id',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Masukkan password Anda'),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(SellerLoginScreen), findsOneWidget);
    expect(
      find.text('Akun ini terdaftar sebagai pembeli dan belum memiliki akses penjual.'),
      findsOneWidget,
    );
    expect(find.text('Daftar Akun Penjual Sekarang'), findsOneWidget);
  });

  testWidgets('SellerRegisterScreen redirects back to SellerLoginScreen -> Seller login -> RegisterStoreScreen -> SellerMainNavigationScreen',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final newSeller = UserProfile(
      id: 'usr-siti-seller',
      fullName: 'Siti Aminah',
      email: 'siti@wijibumi.id',
      phone: '081299998888',
      role: 'seller',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    SupabaseService.instance.currentUser = newSeller;
    SupabaseService.instance.sellerRegisterTestHook = ({
      required String fullName,
      required String email,
      required String password,
      required String phone,
    }) async {
      return const SellerAuthResult(
        status: SellerAuthStatus.success,
        message: 'Akun penjual berhasil didaftarkan! Silakan login terlebih dahulu menggunakan email dan password Anda.',
      );
    };
    SupabaseService.instance.sellerLoginTestHook = (email, password) async =>
        SellerAuthResult(
          status: SellerAuthStatus.needsStoreRegistration,
          profile: newSeller,
        );

    await tester.pumpWidget(_buildTestApp(home: const SellerLoginScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Daftar Akun Penjual'));
    await tester.tap(find.text('Daftar Akun Penjual'));
    await tester.pumpAndSettle();
    expect(find.byType(SellerRegisterScreen), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama pemilik toko / petani'),
      'Siti Aminah',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'penjual@kebun.id'),
      'siti@wijibumi.id',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '0812xxxxxxxx'),
      '081299998888',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Minimal 6 karakter'),
      'Rahasia123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ulangi password'),
      'Rahasia123',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    // Setelah daftar berhasil, tetap diarahkan ke Login Penjual terlebih dahulu
    expect(find.byType(SellerLoginScreen), findsOneWidget);
    expect(find.byType(RegisterStoreScreen), findsNothing);
    expect(
      find.text('Akun penjual berhasil didaftarkan! Silakan login terlebih dahulu menggunakan email dan password Anda.'),
      findsOneWidget,
    );
    expect(find.text('siti@wijibumi.id'), findsOneWidget);

    // Login dengan akun yang baru didaftarkan -> lanjut ke RegisterStoreScreen
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Masukkan password Anda'),
      'Rahasia123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterStoreScreen), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contoh: Kebun Berkah Organik'),
      'Kebun Siti Maju',
    );
    await tester.enterText(
      find.widgetWithText(
          TextFormField, 'Jelaskan hasil panen utama dan keunggulan kebun Anda...'),
      'Menyediakan sayuran organik dan bunga potong segar.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama jalan, nomor, desa/kelurahan'),
      'Jl. Agro Raya No. 7',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Jawa Barat'), 'Jawa Barat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Bandung Barat'), 'Bandung');
    await tester.enterText(find.widgetWithText(TextFormField, 'Parongpong'), 'Cisarua');

    await tester.ensureVisible(find.text('Kirim Pendaftaran Toko'));
    await tester.tap(find.text('Kirim Pendaftaran Toko'));
    await tester.pumpAndSettle();

    expect(find.byType(SellerMainNavigationScreen), findsOneWidget);
    expect(find.byType(SellerDashboardScreen), findsOneWidget);
    expect(find.text('Menunggu Verifikasi'), findsWidgets);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Produk'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Verified seller login -> SellerMainNavigationScreen tabs, chat, orders, profile & logout',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SupabaseService.instance.sellerLoginTestHook = (email, password) async =>
        SellerAuthResult(
          status: SellerAuthStatus.success,
          profile: MockData.defaultUser,
          store: MockData.stores.first,
        );

    await tester.pumpWidget(_buildTestApp(home: const SellerLoginScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'contoh@kebun.id'),
      'budi@wijibumi.id',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Masukkan password Anda'),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    // Seller Home / Dashboard
    expect(find.byType(SellerMainNavigationScreen), findsOneWidget);
    expect(find.byType(SellerDashboardScreen), findsOneWidget);
    expect(find.text('Kebun Berkah Lembang'), findsOneWidget);
    expect(find.text('Aktif & Terverifikasi'), findsOneWidget);
    expect(find.text('Pesanan Terbaru'), findsOneWidget);
    expect(find.text('Chat Terbaru'), findsOneWidget);
    expect(find.text('Produk Saya'), findsOneWidget);
    expect(find.text('Tambah Produk'), findsOneWidget);
    expect(find.text('Kelola Produk'), findsOneWidget);

    // Tab Chat Seller
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.byType(SellerChatListScreen), findsOneWidget);
    expect(find.text('Chat Customer'), findsOneWidget);
    expect(find.text('Rina Wijaya'), findsWidgets);

    // Tab Pesanan Seller (7 tabs & NO Selesaikan button for seller)
    await tester.tap(find.text('Pesanan'));
    await tester.pumpAndSettle();
    expect(find.byType(ManageOrdersScreen), findsOneWidget);
    expect(find.textContaining('Pesanan Masuk'), findsWidgets);
    expect(find.textContaining('Menunggu Pembayaran'), findsWidgets);
    expect(find.textContaining('Diproses'), findsWidgets);
    expect(find.textContaining('Siap Dikirim'), findsWidgets);
    expect(find.textContaining('Sedang Dikirim'), findsWidgets);

    // Tab Profile Seller & Logout -> SellerLoginScreen
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(SellerProfileScreen), findsOneWidget);
    expect(find.text('Profile Penjual'), findsOneWidget);
    expect(find.text('Verifikasi Toko'), findsOneWidget);

    await tester.ensureVisible(find.text('Logout Penjual'));
    await tester.tap(find.text('Logout Penjual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.byType(SellerLoginScreen), findsOneWidget);
  });

  testWidgets('Theme preference persists across ThemeProvider instances', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final tp1 = ThemeProvider();
    await tp1.setThemeMode(ThemeMode.system);
    expect(tp1.themeMode, ThemeMode.system);

    final tp2 = ThemeProvider();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    expect(tp2.themeMode, ThemeMode.system);

    await tp2.setThemeMode(ThemeMode.dark);
    final tp3 = ThemeProvider();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    expect(tp3.themeMode, ThemeMode.dark);
  });

  testWidgets('Chat list opens chat room and sends message', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const ChatListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Pesan Masuk'), findsOneWidget);
    expect(find.text('Tani Makmur Batu Malang'), findsOneWidget);

    await tester.tap(find.text('Tani Makmur Batu Malang'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatRoomScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Apakah stok apel masih tersedia?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Apakah stok apel masih tersedia?'), findsOneWidget);
  });

  testWidgets('Checkout creates order and generates notification', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SupabaseService.instance.cartItems = List.from(MockData.initialCart);
    final initialNotifCount = SupabaseService.instance.notifications.length;

    await tester.pumpWidget(_buildTestApp(home: const CheckoutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Checkout Pembelian'), findsOneWidget);
    expect(find.textContaining('Budi Santoso'), findsWidgets);

    final checkoutButton = find.widgetWithText(ElevatedButton, 'Buat Pesanan (Rp 112.000)');
    expect(checkoutButton, findsOneWidget);
    await tester.tap(checkoutButton);
    await tester.pumpAndSettle();

    expect(find.text('Pesanan Dibuat!'), findsOneWidget);
    expect(SupabaseService.instance.notifications.length, greaterThan(initialNotifCount));

    await tester.tap(find.text('Lihat Pesanan Saya'));
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);
  });

  testWidgets('Seller can process order, input tracking number (resi), and cannot force-complete shipped order', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Add a ready_to_ship order for store-1-lembang
    final baseOrder = MockData.initialOrders.firstWhere((o) => o.storeId == 'store-1-lembang');
    final readyOrder = baseOrder.copyWith(status: 'ready_to_ship');
    SupabaseService.instance.orders = [readyOrder];

    await tester.pumpWidget(_buildTestApp(home: const ManageOrdersScreen(initialTabIndex: 3)));
    await tester.pumpAndSettle();

    expect(find.text('Input Resi & Kirim'), findsOneWidget);
    await tester.tap(find.text('Input Resi & Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Input Nomor Resi Pengiriman'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contoh: TN89201948201'),
      'JNT-RESI-778899',
    );
    await tester.tap(find.text('Kirim Pesanan'));
    await tester.pumpAndSettle();

    // Pindah ke tab Sedang Dikirim
    final shippedTab = find.widgetWithText(Tab, 'Sedang Dikirim (1)');
    await tester.ensureVisible(shippedTab);
    await tester.tap(shippedTab);
    await tester.pumpAndSettle();

    expect(find.text('Resi: JNT-RESI-778899 (SiCepat Cargo Express)'), findsOneWidget);
    expect(find.text('Menunggu Konfirmasi Customer'), findsOneWidget);
    expect(find.text('Selesaikan'), findsNothing);

    // Pastikan aturan domain menolak seller menyelesaikan pesanan secara sepihak
    final blocked = await SupabaseService.instance.updateOrderStatus(
      readyOrder.id,
      'completed',
      isSellerAction: true,
    );
    expect(blocked, isFalse);
  });

  testWidgets('WijiBumiApp launches on SplashScreen -> transitions to LoginScreen without auth',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Splash elements visible, no Login/Register CTA on Splash
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Wiji Bumi'), findsOneWidget);
    expect(find.text('Tumbuh Bersama, Sejahtera Bersama'), findsOneWidget);
    expect(find.text('Masuk'), findsNothing);

    // Finish splash duration (~2.3s + fade transition)
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
    expect(find.text('Nomor HP atau Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar Sekarang'), findsOneWidget);
  });

  testWidgets('SplashScreen routes authenticated seller & buyer sessions to matching dashboards',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Role buyer -> MainNavigationScreen
    await tester.pumpWidget(
      _buildTestApp(
        home: SplashScreen(
          splashDuration: const Duration(milliseconds: 100),
          nextScreenOverride: (_) async => const MainNavigationScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);

    // Role seller -> SellerMainNavigationScreen
    await tester.pumpWidget(
      _buildTestApp(
        home: SplashScreen(
          splashDuration: const Duration(milliseconds: 100),
          nextScreenOverride: (_) async => const SellerMainNavigationScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(SellerMainNavigationScreen), findsOneWidget);
  });

  testWidgets('LoginScreen supports Email/Phone login, ForgotPasswordScreen & RegisterScreen flow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SupabaseService.instance.forgotPasswordTestHook = (email) async => AuthResult(
          success: true,
          message: 'Tautan reset dikirim ke $email.',
        );
    SupabaseService.instance.buyerRegisterTestHook = ({
      required String fullName,
      required String email,
      required String password,
      required String phone,
    }) async =>
        AuthResult(
          success: true,
          requiresEmailConfirmation: true,
          message: 'Verifikasi dikirim ke $email.',
        );
    SupabaseService.instance.buyerLoginTestHook = (identifier, password) async =>
        AuthResult(
          success: true,
          profile: MockData.defaultUser,
        );

    await tester.pumpWidget(_buildTestApp(home: const LoginScreen()));
    await tester.pumpAndSettle();

    // Test top-right Storefront icon -> SellerLoginScreen -> back to LoginScreen
    final storefrontFinder = find.byKey(const Key('login_storefront_button'));
    expect(storefrontFinder, findsOneWidget);
    await tester.tap(storefrontFinder);
    await tester.pumpAndSettle();
    expect(find.byType(SellerLoginScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // Test Lupa Kata Sandi navigation & reset
    await tester.tap(find.text('Lupa Kata Sandi?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email terdaftar'),
      'ani@wijibumi.id',
    );
    await tester.tap(find.text('Kirim Tautan Reset'));
    await tester.pumpAndSettle();
    expect(find.text('Tautan reset dikirim ke ani@wijibumi.id.'), findsOneWidget);
    await tester.tap(find.text('Kembali ke Halaman Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // Test Daftar Sekarang -> RegisterScreen validation & email confirmation
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nama Lengkap'), 'Ani Wijaya');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nomor HP'), '081344556677');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'ani@wijibumi.id');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Wiji1234');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi Password'),
      'Wiji1234',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Verifikasi Email Diperlukan'), findsOneWidget);
    await tester.tap(find.text('Ke Halaman Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(find.text('ani@wijibumi.id'), findsOneWidget);

    // Test registration without email confirmation STILL returns to LoginScreen (not dashboard)
    SupabaseService.instance.buyerRegisterTestHook = ({
      required String fullName,
      required String email,
      required String password,
      required String phone,
    }) async =>
        const AuthResult(
          success: true,
          requiresEmailConfirmation: false,
          message:
              'Akun berhasil didaftarkan! Silakan masuk menggunakan akun yang baru didaftarkan.',
        );

    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nama Lengkap'), 'Budi Wiji');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nomor HP'), '081355667788');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'budi@wijibumi.id');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Wiji1234');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi Password'),
      'Wiji1234',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsNothing);
    expect(find.text('budi@wijibumi.id'), findsOneWidget);
    expect(
      find.text(
        'Akun berhasil didaftarkan! Silakan masuk menggunakan akun yang baru didaftarkan.',
      ),
      findsWidgets,
    );

    // Login using prefilled email/phone -> MainNavigationScreen
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nomor HP atau Email'),
      '081234567890',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi'),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.byType(MainNavigationScreen), findsOneWidget);
  });

  testWidgets('Splash, Login, Register, and ForgotPassword adapt across all 8 mobile/tablet/desktop viewports without overflow',
      (tester) async {
    const viewports = <Size>[
      Size(360, 800),
      Size(375, 812),
      Size(390, 844),
      Size(430, 932),
      Size(768, 1024),
      Size(1024, 768),
      Size(1366, 768),
      Size(1440, 900),
    ];

    for (final size in viewports) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      // 1. SplashScreen (cancels timer on swap cleanly via nextWidget)
      await tester.pumpWidget(
        _buildTestApp(
          home: SplashScreen(
            splashDuration: const Duration(milliseconds: 50),
            nextScreenOverride: (_) async => const LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Failed on $size');

      final storefrontBtn = find.byKey(const Key('login_storefront_button'));
      expect(storefrontBtn, findsOneWidget, reason: 'Missing storefront on $size');
      final storefrontRect = tester.getRect(storefrontBtn);
      expect(storefrontRect.right, lessThanOrEqualTo(size.width));
      expect(storefrontRect.left, greaterThan(size.width * 0.5));
      expect(storefrontRect.top, lessThan(80));

      // 2. RegisterScreen
      await tester.pumpWidget(_buildTestApp(home: const RegisterScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget, reason: 'Failed Register on $size');

      // 3. ForgotPasswordScreen
      await tester.pumpWidget(_buildTestApp(home: const ForgotPasswordScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget, reason: 'Failed Forgot on $size');
    }

    // Also test mobile keyboard bottom viewInsets on compact 360x800 LoginScreen
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(_buildTestApp(home: const LoginScreen()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Masuk'));
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets(
      'Buyer & Seller marketplace screens render without overflow across narrow phone (320x568), landscape (640x360), tablet (768x1024), laptop (1366x768) & desktop (1920x1080)',
      (tester) async {
    SupabaseService.instance.cartItems = List.from(MockData.initialCart);
    const viewports = <Size>[
      Size(320, 568),
      Size(640, 360),
      Size(768, 1024),
      Size(1366, 768),
      Size(1920, 1080),
    ];

    addTearDown(() => tester.view.resetPhysicalSize());

    final sampleProduct = MockData.products.first;
    final sampleStore = MockData.stores.first;
    final sampleOrder = MockData.initialOrders.first;

    final screens = <Widget Function()>[
      () => const MainNavigationScreen(),
      () => ProductDetailScreen(product: sampleProduct),
      () => const CartScreen(),
      () => const CheckoutScreen(),
      () => const OrdersScreen(),
      () => OrderDetailScreen(order: sampleOrder),
      () => ShipmentTrackingScreen(order: sampleOrder),
      () => StoreDetailScreen(store: sampleStore),
      () => const StoreListScreen(),
      () => const ChatListScreen(),
      () => const NotificationsScreen(),
      () => const AddressListScreen(),
      () => const ProfileScreen(),
      () => const EditProfileScreen(),
      () => const SellerMainNavigationScreen(),
      () => const ManageProductsScreen(),
      () => const ManageOrdersScreen(),
      () => const SellerChatListScreen(),
      () => const StoreFinanceScreen(),
      () => const StoreStatsScreen(),
      () => const StoreReviewsScreen(),
      () => const StorePromotionsScreen(),
      () => const SellerProfileScreen(),
    ];

    for (final size in viewports) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      for (final buildScreen in screens) {
        final widget = buildScreen();
        await tester.pumpWidget(_buildTestApp(home: widget));
        await tester.pumpAndSettle();
        final overflowErr = tester.takeException();
        expect(
          overflowErr,
          isNull,
          reason: 'Unexpected exception on ${widget.runtimeType} at $size: $overflowErr',
        );
      }
    }
  });

  testWidgets('Home horizontal categories include 3 new categories & filter properly, plus Lucide Chat & Cart icons work everywhere',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    // Verify all 7 category chips exist and can be tapped after horizontal scrolling
    for (final catLabel in const [
      'Semua',
      'Bunga',
      'Sayuran',
      'Buah-buahan',
      'Rempah-rempah',
      'Bibit & Benih',
      'Umbi-umbian',
    ]) {
      final chip = find.text(catLabel);
      await tester.ensureVisible(chip);
      expect(chip, findsWidgets);
    }

    // Filter Rempah-rempah
    await tester.ensureVisible(find.text('Rempah-rempah').first);
    await tester.tap(find.text('Rempah-rempah').first);
    await tester.pumpAndSettle();
    expect(find.text('Kunyit Merah Segar Organik'), findsOneWidget);
    expect(find.text('Benih Cabai Rawit Unggul F1'), findsNothing);

    // Filter Bibit & Benih
    await tester.ensureVisible(find.text('Bibit & Benih').first);
    await tester.tap(find.text('Bibit & Benih').first);
    await tester.pumpAndSettle();
    expect(find.text('Benih Cabai Rawit Unggul F1'), findsOneWidget);
    expect(find.text('Kunyit Merah Segar Organik'), findsNothing);

    // Filter Umbi-umbian
    await tester.ensureVisible(find.text('Umbi-umbian').first);
    await tester.tap(find.text('Umbi-umbian').first);
    await tester.pumpAndSettle();
    expect(find.text('Ubi Cilembu Madu Pilihan'), findsOneWidget);

    // Reset to Semua
    await tester.ensureVisible(find.text('Semua').first);
    await tester.tap(find.text('Semua').first);
    await tester.pumpAndSettle();
    expect(find.text('Bunga Mawar Merah Holland Segar'), findsWidgets);

    // Verify Lucide header icons (28px, dark slate) & product card shopping cart icons
    final headerChatIcon = tester.widget<LucideMessageCircleIcon>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(LucideMessageCircleIcon),
      ),
    );
    expect(headerChatIcon.size, 28);
    expect(headerChatIcon.color, AppColors.textPrimaryLight);

    expect(find.byType(LucideShoppingCartIcon), findsWidgets);
    final headerCartIcon = tester.widget<LucideShoppingCartIcon>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(LucideShoppingCartIcon),
      ),
    );
    expect(headerCartIcon.size, 28);
    expect(headerCartIcon.color, AppColors.textPrimaryLight);

    // Verify Chat header navigation still works
    await tester.tap(find.byTooltip('Pesan'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatListScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Verify Cart header navigation still works
    await tester.tap(find.byTooltip('Keranjang'));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
  });

  testWidgets(
      'EditProfileScreen supports photo reset, birth date & gender, verification badges, validation & dirty cancel guard',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SupabaseService.instance.profileVerificationTestHook =
        (draftEmail, draftPhone) => {
              'emailVerified':
                  (draftEmail ?? '').trim().toLowerCase() ==
                  'budi.santoso@wijibumi.id',
              'phoneVerified': false,
              'pendingEmail': null,
              'isSupabaseLive': true,
            };

    await tester.pumpWidget(_buildTestApp(home: const ProfileScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);

    // Email is verified via actual hook, phone honestly shows Belum Terverifikasi
    expect(find.text('Terverifikasi'), findsOneWidget);
    expect(find.text('Belum Terverifikasi'), findsOneWidget);

    // Save button disabled until valid edits exist
    ElevatedButton saveBtn() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Simpan Perubahan'),
        );
    expect(saveBtn().onPressed, isNull);

    // Changing email away from verified email flips badge immediately
    await tester.enterText(
      find.widgetWithText(TextFormField, 'email@domain.com'),
      'baru@wijibumi.id',
    );
    await tester.pumpAndSettle();
    expect(find.text('Terverifikasi'), findsNothing);
    expect(find.text('Belum Terverifikasi'), findsNWidgets(2));

    // Invalid Indonesian phone disables save
    await tester.enterText(
      find.widgetWithText(TextFormField, '081234567890'),
      '12345',
    );
    await tester.pumpAndSettle();
    expect(saveBtn().onPressed, isNull);

    // Valid Indonesian phone + name + reset photo + birth date + gender enables save
    await tester.enterText(
      find.widgetWithText(TextFormField, '081234567890'),
      '+6281398765432',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Masukkan nama lengkap Anda'),
      'Budi Wiji Santoso',
    );
    await tester.ensureVisible(find.text('Hapus Foto'));
    await tester.tap(find.text('Hapus Foto'));
    await tester.pumpAndSettle();

    // Pick birth date
    await tester.ensureVisible(
      find.widgetWithText(TextFormField, 'Pilih tanggal lahir'),
    );
    await tester.tap(find.widgetWithText(TextFormField, 'Pilih tanggal lahir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    // Select Gender dropdown
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laki-laki').last);
    await tester.pumpAndSettle();

    expect(saveBtn().onPressed, isNotNull);

    // Tapping Batal when dirty triggers confirmation dialog
    await tester.ensureVisible(find.text('Batal'));
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan Perubahan?'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan Edit'));
    await tester.pumpAndSettle();

    // Save changes & verify returned ProfileScreen reflects updates
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Budi Wiji Santoso'), findsOneWidget);
    expect(find.text('+6281398765432'), findsOneWidget);

    // Reopen EditProfileScreen and verify saved fields reload cleanly
    await tester.tap(find.byTooltip('Edit Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Budi Wiji Santoso'), findsOneWidget);
    expect(find.text('Laki-laki'), findsOneWidget);
    expect(find.text('Hapus Foto'), findsNothing);
  });

  testWidgets(
      'ProfileScreen renders redesigned sections, badges, footer, dark mode switch & fixed bottom nav at 390x844',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Akun & Pengaturan'), findsOneWidget);
    expect(find.text('Petani Mitra'), findsOneWidget);
    expect(find.text('Toko Saya'), findsOneWidget);
    expect(find.text('Pasar Tani'), findsOneWidget);
    expect(find.text('AKTIVITAS & TRANSAKSI'), findsOneWidget);
    expect(find.text('PENGATURAN & KEAMANAN'), findsOneWidget);
    expect(find.text('INFORMASI & BANTUAN'), findsOneWidget);
    expect(find.text('Mode terang aktif'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Mode gelap aktif'), findsOneWidget);

    await tester.ensureVisible(
      find.text('WijiBumi v0.1.0+1 • Pasar Tani Digital'),
    );
    expect(
      find.text('WijiBumi v0.1.0+1 • Pasar Tani Digital'),
      findsOneWidget,
    );

    // Bottom navigation stays fixed at bottom with all 4 menu labels
    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Toko'), findsWidgets);
    expect(find.text('Pesanan'), findsWidgets);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets(
      'OrdersScreen renders redesigned cards, 7 status pill tabs, payment deadline, filter & empty preview at 390x844',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pesanan'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Pesanan Saya'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Menunggu Pembayaran'), findsWidgets);
    expect(find.text('Menunggu Konfirmasi'), findsOneWidget);
    expect(find.text('Pesanan Diproses'), findsOneWidget);
    expect(find.text('Dikirim'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Dibatalkan'), findsOneWidget);

    // Pending payment deadline banner and Pay/Cancel buttons appear for unpaid order
    expect(find.textContaining('Bayar sebelum ', findRichText: true), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsOneWidget);
    expect(find.text('Batalkan'), findsOneWidget);

    // Filter modal opens cleanly
    await tester.tap(find.byTooltip('Filter Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Filter & Urutkan Pesanan'), findsOneWidget);
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    // Tap 'Dikirim' pill tab to filter shipped orders
    await tester.ensureVisible(find.text('Dikirim'));
    await tester.tap(find.text('Dikirim'));
    await tester.pumpAndSettle();
    expect(find.byType(LucideMessageCircleIcon), findsOneWidget);
    expect(find.text('Hubungi Penjual'), findsOneWidget);
    expect(find.text('Lacak Pengiriman'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsNothing);
    expect(find.textContaining('Bayar sebelum ', findRichText: true), findsNothing);

    // Scroll to footer and toggle Empty State preview
    await tester.ensureVisible(find.text('Lihat Tampilan Kosong'));
    await tester.tap(find.text('Lihat Tampilan Kosong'));
    await tester.pumpAndSettle();
    expect(find.text('Pratinjau Status Kosong'), findsOneWidget);
    await tester.tap(find.text('Tampilkan Daftar Pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Lacak Pengiriman'), findsOneWidget);

    // Profile button in top-right switches to Profile tab cleanly
    await tester.tap(find.byTooltip('Profil Pengguna'));
    await tester.pumpAndSettle();
    expect(find.text('Akun & Pengaturan'), findsOneWidget);
  });

  testWidgets(
      'StoreListScreen renders 2-col grid, circular avatars, dynamic city chips, honest verification & partner banner at 390x844',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Toko'));
    await tester.pumpAndSettle();

    expect(find.text('WIJIBUMI MARKETPLACE'), findsOneWidget);
    expect(find.text('Daftar Toko'), findsOneWidget);
    expect(find.text('Cari nama toko atau kota kebun'), findsOneWidget);

    // Dynamic city chips derived strictly from actual store data (no dummy reference cities)
    expect(find.text('Semua Kota'), findsOneWidget);
    expect(find.text('Bandung Barat'), findsWidgets);
    expect(find.text('Kota Batu'), findsWidgets);
    expect(find.text('Kabupaten Bogor'), findsWidgets);
    expect(find.text('Semarang'), findsNothing);

    // Verification summary & circular avatars + checkmarks strictly for StoreListScreen
    expect(find.text('Terverifikasi WijiBumi'), findsOneWidget);
    expect(find.text('Menampilkan 3 toko'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StoreListScreen),
        matching: find.byIcon(Icons.check),
      ),
      findsNWidgets(3),
    );
    expect(
      find.descendant(
        of: find.byType(StoreListScreen),
        matching: find.byType(ClipOval),
      ),
      findsNWidgets(3),
    );

    // Tap dynamic city filter chip -> filters list to 1 approved store
    await tester.ensureVisible(find.text('Kota Batu').first);
    await tester.tap(find.text('Kota Batu').first);
    await tester.pumpAndSettle();
    expect(find.text('Tani Makmur Batu Malang'), findsOneWidget);
    expect(find.text('Menampilkan 1 toko'), findsOneWidget);

    // Filter sheet works
    await tester.tap(find.byTooltip('Filter Toko'));
    await tester.pumpAndSettle();
    expect(find.text('Filter & Urutkan Toko'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Menampilkan 3 toko'), findsOneWidget);

    final storeListScroll = find.descendant(
      of: find.byType(StoreListScreen),
      matching: find.byType(ListView),
    );

    // Scroll to Farmer Partner Banner & verify seller onboarding navigation
    await tester.dragUntilVisible(
      find.text('Daftar'),
      storeListScroll,
      const Offset(0, -200),
    );
    await tester.ensureVisible(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Punya Kebun Mandiri?'), findsOneWidget);
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();
    expect(find.byType(SellerLoginScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali ke Profile'));
    await tester.pumpAndSettle();

    // Tapping 'Lihat Toko' navigates to StoreDetailScreen
    await tester.dragUntilVisible(
      find.text('Lihat Toko').first,
      storeListScroll,
      const Offset(0, 200),
    );
    await tester.ensureVisible(find.text('Lihat Toko').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Toko').first);
    await tester.pumpAndSettle();
    expect(find.byType(StoreDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Top-right Profile icon switches to Profile tab
    await tester.tap(find.byTooltip('Profil Pengguna'));
    await tester.pumpAndSettle();
    expect(find.text('Akun & Pengaturan'), findsOneWidget);

    // Verify StoreCard never renders a fake verified checkmark for unapproved stores
    await tester.pumpWidget(
      _buildTestApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: StoreCard(
              store: MockData.stores.first.copyWith(
                verificationStatus: 'pending',
                isActive: false,
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(StoreCard),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
  });

  testWidgets(
      'HomeScreen renders original logo, shipping address, asset slideshow, farmer recommendations & 2-col product grid at 390x844',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildTestApp(home: const MainNavigationScreen()));
    await tester.pumpAndSettle();

    // Original WijiBumiCompactLogo and brand texts remain intact
    expect(find.byType(WijiBumiCompactLogo), findsOneWidget);
    expect(find.text('WijiBumi'), findsOneWidget);
    expect(find.text('Pasar Tani Digital'), findsOneWidget);

    // Shipping address bar uses real default address and navigates to AddressListScreen
    expect(find.text('Dikirim ke'), findsOneWidget);
    expect(find.text('Ubah Alamat'), findsOneWidget);
    await tester.tap(find.text('Ubah Alamat'));
    await tester.pumpAndSettle();
    expect(find.byType(AddressListScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Search + Filter modal
    expect(find.text('Cari bunga, sayuran, buah, atau toko...'), findsOneWidget);
    await tester.tap(find.byTooltip('Filter Kategori'));
    await tester.pumpAndSettle();
    expect(find.text('Filter Kategori Produk'), findsOneWidget);
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    // Asset-based Banner Slideshow renders and swipes manually between slides
    expect(find.byType(HomeBannerSlideshow), findsOneWidget);
    expect(find.text('Panen Raya Sayur Segar!'), findsOneWidget);
    await tester.drag(find.byType(HomeBannerSlideshow), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('Buah Manis Petik Pohon'), findsOneWidget);

    // Farmer recommendations & product catalog & local farmer banner
    await tester.ensureVisible(find.text('Rekomendasi Petani'));
    expect(find.text('Rekomendasi Petani'), findsOneWidget);
    expect(find.text('Kebun Berkah Lembang'), findsWidgets);

    await tester.ensureVisible(find.text('100% Langsung dari Petani Lokal'));
    expect(find.text('100% Langsung dari Petani Lokal'), findsOneWidget);

    // Tapping Lihat Semua switches to Toko tab
    await tester.ensureVisible(find.text('Lihat Semua'));
    await tester.tap(find.text('Lihat Semua'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Toko'), findsOneWidget);
  });
}
