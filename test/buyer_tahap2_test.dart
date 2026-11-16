import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wijibumi/core/theme/app_theme.dart';
import 'package:wijibumi/core/theme/theme_provider.dart';
import 'package:wijibumi/models/chat.dart';
import 'package:wijibumi/providers/address_provider.dart';
import 'package:wijibumi/providers/app_settings_provider.dart';
import 'package:wijibumi/providers/auth_provider.dart';
import 'package:wijibumi/providers/cart_provider.dart';
import 'package:wijibumi/providers/chat_provider.dart';
import 'package:wijibumi/providers/notification_provider.dart';
import 'package:wijibumi/providers/order_provider.dart';
import 'package:wijibumi/providers/product_provider.dart';
import 'package:wijibumi/providers/store_provider.dart';
import 'package:wijibumi/screens/chat/chat_list_screen.dart';
import 'package:wijibumi/screens/chat/chat_room_screen.dart';
import 'package:wijibumi/screens/orders/order_detail_screen.dart';
import 'package:wijibumi/screens/orders/shipment_tracking_screen.dart';
import 'package:wijibumi/screens/profile/notifications_screen.dart';
import 'package:wijibumi/services/mock_data.dart';
import 'package:wijibumi/services/supabase_service.dart';
import 'package:wijibumi/widgets/smart_image.dart';

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
    SupabaseService.instance.chats = List.from(MockData.initialChats);
    SupabaseService.instance.chatMessages = List.from(
      MockData.initialChatMessages,
    );
    SupabaseService.instance.notifications = List.from(
      MockData.initialNotifications,
    );
  });

  testWidgets(
      'ChatListScreen separates buyer chats, displays unread badges, and leaves room cleanly on back',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Give chat-2 3 unread messages
    SupabaseService.instance.chats = MockData.initialChats
        .map((c) => c.id == 'chat-2' ? c.copyWith(unreadCount: 3) : c)
        .toList();

    await tester.pumpWidget(_wrapApp(const ChatListScreen()));
    await tester.pumpAndSettle();

    // Buyer chats visible, seller-only incoming customer chat excluded
    expect(find.text('Tani Makmur Batu Malang'), findsOneWidget);
    expect(find.text('Hidroponik Surya Hijau'), findsOneWidget);
    expect(find.text('Rina Wijaya'), findsNothing);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('Hidroponik Surya Hijau'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatRoomScreen), findsOneWidget);

    final ctx = tester.element(find.byType(ChatRoomScreen));
    final chatProv = Provider.of<ChatProvider>(ctx, listen: false);
    expect(chatProv.activeChatId, 'chat-2');

    // Back from ChatRoomScreen triggers leaveChatRoom() and clears activeChatId
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(chatProv.activeChatId, isNull);
  });

  testWidgets(
      'ChatRoomScreen renders image-only messages and preserves input if send fails',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SupabaseService.instance.chatMessages = [
      ...MockData.initialChatMessages,
      ChatMessage(
        id: 'msg-img-1',
        chatId: 'chat-1',
        senderId: 'usr-petani-malang',
        messageType: 'image',
        body: null,
        mediaPath: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      _wrapApp(
        const ChatRoomScreen(
          chatId: 'chat-1',
          storeId: 'store-2-malang',
          title: 'Tani Makmur Batu Malang',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Image attachment renders via SmartImage and attach button is visible
    expect(find.byType(SmartImage), findsWidgets);
    expect(find.byTooltip('Lampirkan Gambar'), findsOneWidget);

    // Simulate failed send by clearing active user before tapping Send -> typed text stays preserved
    await tester.enterText(find.byType(TextField), 'Pesan penting saya');
    await SupabaseService.instance.logout();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Pesan penting saya'), findsOneWidget);
  });

  testWidgets(
      'NotificationsScreen marks read and deep-links to ShipmentTrackingScreen, OrderDetailScreen, and ChatRoomScreen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_wrapApp(const NotificationsScreen()));
    await tester.pumpAndSettle();

    // 1. Shipment notification -> ShipmentTrackingScreen
    await tester.tap(
      find.text('Pesanan WIJI-20261108-001 Sedang Dikirim'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShipmentTrackingScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 2. Transaction notification -> OrderDetailScreen
    await tester.tap(
      find.text('Pembayaran Menunggu untuk WIJI-20261109-003'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrderDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Chat notification -> ChatRoomScreen
    await tester.tap(find.text('Pesan baru dari Tani Makmur Batu Malang'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatRoomScreen), findsOneWidget);
  });
}
