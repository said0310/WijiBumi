import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wijibumi/core/theme/app_theme.dart';
import 'package:wijibumi/core/theme/theme_provider.dart';
import 'package:wijibumi/core/utils/auth_guard.dart';
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
import 'package:wijibumi/screens/auth/register_screen.dart';
import 'package:wijibumi/screens/home/home_screen.dart';
import 'package:wijibumi/screens/profile/account_security_screen.dart';
import 'package:wijibumi/screens/profile/edit_profile_screen.dart';
import 'package:wijibumi/screens/profile/profile_screen.dart';
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
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      if (authProvider != null)
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider)
      else
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => StoreProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
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
    SupabaseService.instance.deleteAccountTestHook = null;
  });

  tearDown(() {
    SupabaseService.instance.currentUser = MockData.defaultUser;
    SupabaseService.instance.deleteAccountTestHook = null;
  });

  test('Strict Indonesian phone validators reject letters and accept valid formats', () {
    expect(validateIndonesianPhoneNumber('0812345abc89'), isNotNull);
    expect(validateIndonesianPhoneNumber('0812-3456-7890'), isNull);
    expect(validateIndonesianPhoneNumber('+6281398765432'), isNull);
    expect(validateIndonesianPhoneNumber('0812'), isNotNull);

    expect(validateLoginIdentifier('0812345abc89'), isNotNull);
    expect(validateLoginIdentifier('081234567890'), isNull);
    expect(validateLoginIdentifier('budi@wijibumi.id'), isNull);
    expect(validateLoginIdentifier('not-an-email'), isNotNull);
  });

  testWidgets('LoginScreen & RegisterScreen reject mixed-letter phone numbers', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithProviders(const RegisterScreen()));
    await tester.pump(const Duration(milliseconds: 200));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Budi Santoso');
    await tester.enterText(fields.at(1), '0812345abc89');
    await tester.enterText(fields.at(2), 'budi@wijibumi.id');
    await tester.enterText(fields.at(3), 'Password123!');
    await tester.enterText(fields.at(4), 'Password123!');

    final submitBtn = find.widgetWithText(ElevatedButton, 'Daftar');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Format nomor HP tidak valid (9-15 digit)'), findsOneWidget);
  });

  testWidgets('Guest user is redirected to LoginScreen on protected Home, Store, and Profile actions', (
    tester,
  ) async {
    final authProv = AuthProvider();
    await tester.runAsync(() async {
      await authProv.loadUser();
      await authProv.logout();
    });
    expect(authProv.isAuthenticated, isFalse);

    // 1. HomeScreen Cart button requires login
    await tester.pumpWidget(
      _wrapWithProviders(const HomeScreen(), authProvider: authProv),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Keranjang'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // 2. StoreDetailScreen Chat Toko requires login
    await tester.pumpWidget(
      _wrapWithProviders(
        StoreDetailScreen(store: MockData.stores.first),
        authProvider: authProv,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Chat Toko'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // 3. ProfileScreen Pengaturan Aplikasi requires login
    await tester.pumpWidget(
      _wrapWithProviders(const ProfileScreen(), authProvider: authProv),
    );
    await tester.pumpAndSettle();

    final settingsRow = find.text('Pengaturan Aplikasi');
    await tester.ensureVisible(settingsRow);
    await tester.tap(settingsRow);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('ProfileScreen shows Pelanggan for pure buyer role instead of Petani Mitra', (
    tester,
  ) async {
    SupabaseService.instance.currentUser =
        MockData.defaultUser.copyWith(role: 'buyer');
    final authProv = AuthProvider();
    await tester.runAsync(() => authProv.loadUser());

    await tester.pumpWidget(
      _wrapWithProviders(const ProfileScreen(), authProvider: authProv),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('Petani Mitra'), findsNothing);
  });

  testWidgets('EditProfileScreen shows inline phone validation error while editing', (
    tester,
  ) async {
    final authProv = AuthProvider();
    await tester.runAsync(() => authProv.loadUser());

    await tester.pumpWidget(
      _wrapWithProviders(const EditProfileScreen(), authProvider: authProv),
    );
    await tester.pumpAndSettle();

    final phoneField = find.descendant(
      of: find.widgetWithText(CustomTextField, 'Nomor WhatsApp / HP'),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '0812abc999');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Masukkan nomor HP Indonesia yang valid'),
      findsOneWidget,
    );
  });

  testWidgets('AccountSecurityScreen supports resending verification and deleting account', (
    tester,
  ) async {
    bool deletedCalled = false;
    SupabaseService.instance.deleteAccountTestHook = () async {
      deletedCalled = true;
      return const AuthResult(success: true, message: 'Akun berhasil dihapus.');
    };

    final authProv = AuthProvider();
    await tester.runAsync(() => authProv.loadUser());

    await tester.pumpWidget(
      _wrapWithProviders(const AccountSecurityScreen(), authProvider: authProv),
    );
    await tester.pumpAndSettle();

    // Resend verification button visible when emailVerified == false
    final resendBtn = find.text('Kirim Ulang Email Verifikasi');
    expect(resendBtn, findsOneWidget);
    await tester.tap(resendBtn);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('memerlukan koneksi server'),
      findsOneWidget,
    );

    // Dismiss snackbar so it doesn't overlay the bottom delete button
    ScaffoldMessenger.of(
      tester.element(find.byType(AccountSecurityScreen)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // Delete account flow (ListView builds bottom card lazily when scrolled)
    final deleteBtn = find.text('Hapus Akun Saya');
    await tester.scrollUntilVisible(
      deleteBtn,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(deleteBtn);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    final confirmBtn = find.text('Hapus Akun').last;
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(deletedCalled, isTrue);
    expect(authProv.isAuthenticated, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

