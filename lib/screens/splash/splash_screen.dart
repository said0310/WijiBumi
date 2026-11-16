import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/address_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/wijibumi_auth_widgets.dart';
import '../main_navigation_screen.dart';
import '../store/register_store_screen.dart';
import '../store/seller_dashboard/seller_main_navigation_screen.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  final Duration splashDuration;
  final Future<Widget?> Function(BuildContext context)? nextScreenOverride;

  const SplashScreen({
    super.key,
    this.splashDuration = const Duration(milliseconds: 2300),
    this.nextScreenOverride,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _dotsController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  bool _navigated = false;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.72, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.78, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.28, 1.0, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _introController.forward();
    _bootstrapSessionAndNavigate();
  }

  Future<void> _bootstrapSessionAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    Widget target = const LoginScreen();

    try {
      if (widget.nextScreenOverride != null) {
        final overridden = await widget.nextScreenOverride!(context);
        if (overridden != null) {
          target = overridden;
        }
      } else {
        target = await _resolveDestinationBySession();
      }
    } catch (_) {
      target = const LoginScreen();
    }

    final remaining = widget.splashDuration - stopwatch.elapsed;
    if (!mounted || _navigated) return;
    if (remaining <= Duration.zero) {
      _navigateTo(target);
    } else {
      _navTimer = Timer(remaining, () => _navigateTo(target));
    }
  }

  void _navigateTo(Widget target) {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: target,
        ),
      ),
    );
  }

  Future<Widget> _resolveDestinationBySession() async {
    final authProvider = context.read<AuthProvider>();
    final hasSession = await authProvider.checkRemoteSession();
    if (!hasSession || !mounted) {
      return const LoginScreen();
    }

    final storeProvider = context.read<StoreProvider>();
    final productProvider = context.read<ProductProvider>();
    final orderProvider = context.read<OrderProvider>();
    final cartProvider = context.read<CartProvider>();
    final addressProvider = context.read<AddressProvider>();
    final appSettingsProvider = context.read<AppSettingsProvider>();
    final notifProvider = context.read<NotificationProvider>();
    final chatProvider = context.read<ChatProvider>();

    await Future.wait([
      productProvider.initData(),
      storeProvider.loadStores(),
      storeProvider.checkMyStore(),
      orderProvider.loadOrders(),
      cartProvider.loadCart(),
      addressProvider.loadAddresses(),
      appSettingsProvider.loadSettings(),
      notifProvider.loadNotifications(),
    ]);
    await chatProvider.loadChats(myStoreId: storeProvider.myStore?.id);
    if (mounted) {
      notifProvider.subscribeRealtime();
    }

    final user = authProvider.user;
    if (user != null && user.role == 'seller') {
      authProvider.restoreSellerSessionIfEligible();
      if (storeProvider.hasStore) {
        return const SellerMainNavigationScreen();
      }
      return const RegisterStoreScreen();
    }

    return const MainNavigationScreen();
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _introController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor =
        isDark ? AppColors.textPrimaryDark : AppColors.forestGreen;
    final taglineColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.forestGreen.withValues(alpha: 0.85);

    return Scaffold(
      body: WijiBumiAmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = WijiBumiResponsiveMetrics(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                  vertical: metrics.isCompactMobile ? 16 : 28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight -
                            (metrics.isCompactMobile ? 32 : 56))
                        .clamp(0.0, double.infinity),
                  ),
                  child: IntrinsicHeight(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          children: [
                            const Spacer(flex: 3),
                            FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: WijiBumiLogoWithGlow(
                                  size: metrics.splashLogoSize,
                                ),
                              ),
                            ),
                            SizedBox(height: metrics.isCompactMobile ? 16 : 22),
                            FadeTransition(
                              opacity: _textFade,
                              child: SlideTransition(
                                position: _textSlide,
                                child: Column(
                                  children: [
                                    Text(
                                      'Wiji Bumi',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: metrics.brandFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: brandColor,
                                        letterSpacing: -0.6,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tumbuh Bersama, Sejahtera Bersama',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: metrics.subtitleFontSize,
                                        fontWeight: FontWeight.w400,
                                        color: taglineColor,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(flex: 4),
                            const SizedBox(height: 16),
                            _ThreeGreenDotsLoader(
                              controller: _dotsController,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThreeGreenDotsLoader extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _ThreeGreenDotsLoader({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isDark ? AppColors.emeraldGreen : AppColors.forestGreen;
    final midColor = AppColors.oliveGreen;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final t = controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = ((t * 3) - index) % 3;
            final distance = phase < 0 ? phase + 3 : phase;
            final intensity = distance < 1.0 ? (1.0 - distance) : 0.25;
            final scale = 0.8 + (0.35 * intensity);
            final color = index == 1 ? midColor : activeColor;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.35 + (0.65 * intensity)),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
