import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_guard.dart';
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
import '../store/seller_auth/seller_login_screen.dart';
import '../store/seller_dashboard/seller_main_navigation_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialIdentifier;
  final String? infoBanner;

  const LoginScreen({
    super.key,
    this.initialIdentifier,
    this.infoBanner,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorBanner;
  String? _infoBanner;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdentifier != null &&
        widget.initialIdentifier!.isNotEmpty) {
      _identifierController.text = widget.initialIdentifier!;
    }
    _infoBanner = widget.infoBanner;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reloadUserSessionData() async {
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
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorBanner = null;
      _infoBanner = null;
    });

    final authProvider = context.read<AuthProvider>();
    final res = await authProvider.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    if (res.success) {
      await _reloadUserSessionData();
      if (!mounted) return;

      final storeProvider = context.read<StoreProvider>();
      final user = authProvider.user;
      Widget destination = const MainNavigationScreen();
      if (user != null && user.role == 'seller') {
        authProvider.restoreSellerSessionIfEligible();
        destination = storeProvider.hasStore
            ? const SellerMainNavigationScreen()
            : const RegisterStoreScreen();
      }

      setState(() => _isLoading = false);
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, animation, _) => FadeTransition(
            opacity: animation,
            child: destination,
          ),
        ),
        (route) => false,
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _errorBanner =
          res.message ?? 'Nomor HP/Email atau kata sandi tidak valid.';
    });
  }

  Future<void> _openRegister() async {
    final result = await Navigator.push<Map<String, String>?>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: const RegisterScreen(),
        ),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      final email = result['email']?.trim();
      if (email != null && email.isNotEmpty) {
        _identifierController.text = email;
      }
      _passwordController.clear();
      _errorBanner = null;
      _infoBanner = result['message'];
    });
  }

  void _openSellerPortal() {
    final authProvider = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final prefill = _identifierController.text.trim();
    final Widget target;
    if (authProvider.isAuthenticated &&
        authProvider.hasSellerAccess &&
        authProvider.isSellerSessionAuthenticated) {
      target = storeProvider.hasStore
          ? const SellerMainNavigationScreen()
          : const RegisterStoreScreen();
    } else {
      target = SellerLoginScreen(
        initialEmail: prefill.contains('@') ? prefill : null,
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor =
        isDark ? AppColors.textPrimaryDark : AppColors.forestGreen;
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.forestGreen.withValues(alpha: 0.82);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: WijiBumiAmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = WijiBumiResponsiveMetrics(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              );

              final iconColor =
                  isDark ? AppColors.primaryLight : AppColors.forestGreen;

              return SingleChildScrollView(
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.horizontalPadding,
                        vertical: 20,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 40)
                              .clamp(0.0, double.infinity),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: metrics.contentMaxWidth,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                          WijiBumiLogoWithGlow(size: metrics.authLogoSize),
                          const SizedBox(height: 6),
                          Text(
                            'Wiji Bumi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: metrics.authBrandFontSize,
                              fontWeight: FontWeight.w700,
                              color: headingColor,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Selamat Datang',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: metrics.authHeadingSize,
                              fontWeight: FontWeight.w600,
                              color: headingColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Masuk ke Akun Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: metrics.subtitleFontSize,
                              fontWeight: FontWeight.w400,
                              color: subtitleColor,
                            ),
                          ),
                          SizedBox(height: metrics.isCompactMobile ? 18 : 24),
                          WijiBumiGlassAuthCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: metrics.isCompactMobile ? 18 : 24,
                              vertical: metrics.isCompactMobile ? 22 : 26,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_infoBanner != null &&
                                      _errorBanner == null) ...[
                                    _StatusNoticeBanner(
                                      message: _infoBanner!,
                                      isError: false,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_errorBanner != null) ...[
                                    _StatusNoticeBanner(
                                      message: _errorBanner!,
                                      isError: true,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  WijiBumiAuthTextField(
                                    controller: _identifierController,
                                    hintText: 'Nomor HP atau Email',
                                    prefixIcon: Icons.smartphone_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email,
                                      AutofillHints.telephoneNumber,
                                    ],
                                    validator: validateLoginIdentifier,
                                  ),
                                  const SizedBox(height: 14),
                                  WijiBumiAuthTextField(
                                    controller: _passwordController,
                                    hintText: 'Kata Sandi',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.password],
                                    onFieldSubmitted: (_) => _handleLogin(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.forestGreen,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Kata sandi wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ForgotPasswordScreen(
                                              initialEmail:
                                                  _identifierController.text
                                                      .trim(),
                                            ),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Lupa Kata Sandi?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: headingColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  WijiBumiPrimaryPillButton(
                                    text: 'Masuk',
                                    isLoading: _isLoading,
                                    onPressed: _handleLogin,
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Belum punya akun? ',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.neutralDark,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _openRegister,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Text(
                                            'Daftar Sekarang',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.primaryLight
                                                  : AppColors.oliveGreen,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 12,
                      child: IconButton(
                        key: const Key('login_storefront_button'),
                        onPressed: _openSellerPortal,
                        tooltip: 'Toko Saya',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: Image.asset(
                          'assets/images/storefront_icon.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          color: iconColor,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.storefront_outlined,
                            size: 26,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusNoticeBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusNoticeBanner({
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.emeraldGreen;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
