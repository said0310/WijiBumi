import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/wijibumi_auth_widgets.dart';
import '../../main_navigation_screen.dart';
import '../register_store_screen.dart';
import '../seller_dashboard/seller_main_navigation_screen.dart';
import 'seller_register_screen.dart';

class SellerLoginScreen extends StatefulWidget {
  final String? initialEmail;
  final String? infoBanner;

  const SellerLoginScreen({
    super.key,
    this.initialEmail,
    this.infoBanner,
  });

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  static const String _prefRememberKey = 'seller_remember_me';
  static const String _prefEmailKey = 'seller_saved_email';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorBanner;
  String? _infoBanner;
  bool _showRegisterCta = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    _infoBanner = widget.infoBanner;
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_prefRememberKey) ?? true;
      final savedEmail = prefs.getString(_prefEmailKey) ?? '';
      if (!mounted) return;
      final buyerEmail = context.read<AuthProvider>().user?.email ?? '';
      setState(() {
        _rememberMe = remember;
        if (_emailController.text.isEmpty && remember && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        } else if (buyerEmail.isNotEmpty && _emailController.text.isEmpty) {
          _emailController.text = buyerEmail;
        }
      });
    } catch (_) {
      // Abaikan kegagalan storage lokal saat testing/offline
    }
  }

  Future<void> _persistRememberMe(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefRememberKey, _rememberMe);
      if (_rememberMe) {
        await prefs.setString(_prefEmailKey, email);
      } else {
        await prefs.remove(_prefEmailKey);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openSellerRegister() async {
    final res = await Navigator.push<Map<String, String>?>(
      context,
      MaterialPageRoute(
        builder: (_) => SellerRegisterScreen(
          initialEmail: _emailController.text.trim(),
        ),
      ),
    );
    if (!mounted || res == null) return;
    setState(() {
      final registeredEmail = res['email']?.trim();
      if (registeredEmail != null && registeredEmail.isNotEmpty) {
        _emailController.text = registeredEmail;
      }
      _passwordController.clear();
      _errorBanner = null;
      _showRegisterCta = false;
      _infoBanner = res['message'] ??
          'Akun penjual berhasil didaftarkan! Silakan login menggunakan email dan password Anda.';
    });
  }

  void _backToBuyerProfile() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorBanner = null;
      _infoBanner = null;
      _showRegisterCta = false;
    });

    final authProvider = context.read<AuthProvider>();
    final storeProvider = context.read<StoreProvider>();
    final chatProvider = context.read<ChatProvider>();
    final orderProvider = context.read<OrderProvider>();
    final addressProvider = context.read<AddressProvider>();
    final notifProvider = context.read<NotificationProvider>();

    final result = await authProvider.loginSeller(email, password);
    if (!mounted) return;

    if (result.status == SellerAuthStatus.success) {
      await _persistRememberMe(email);
      await storeProvider.checkMyStore();
      await storeProvider.loadMyStoreData();
      await orderProvider.loadOrders();
      await addressProvider.loadAddresses();
      await notifProvider.loadNotifications();
      notifProvider.subscribeRealtime();
      if (!mounted) return;

      if (storeProvider.hasStore) {
        await chatProvider.loadChats(myStoreId: storeProvider.myStore!.id);
        if (!mounted) return;
        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SellerMainNavigationScreen()),
          (route) => false,
        );
      } else {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterStoreScreen()),
        );
      }
      return;
    }

    if (result.status == SellerAuthStatus.needsStoreRegistration) {
      await _persistRememberMe(email);
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterStoreScreen()),
      );
      return;
    }

    setState(() {
      _isLoading = false;
      _errorBanner = result.message ?? 'Login penjual gagal.';
      _showRegisterCta = result.status == SellerAuthStatus.notSeller;
    });
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            title: const Text('Lupa Password Penjual'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan email akun penjual Anda. Kami akan mengirimkan tautan reset password melalui Supabase Auth.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Penjual',
                        hintText: 'penjual@wijibumi.id',
                      ),
                      validator: (v) {
                        final val = (v ?? '').trim();
                        if (val.isEmpty ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(val)) {
                          return 'Masukkan email yang valid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => sending = true);
                        final res = await context
                            .read<AuthProvider>()
                            .sendPasswordReset(resetEmailController.text.trim());
                        if (!mounted) return;
                        if (ctx.mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              res.message ??
                                  (res.success
                                      ? 'Link reset password telah dikirim.'
                                      : 'Gagal mengirim link reset password.'),
                            ),
                            backgroundColor:
                                res.success ? AppColors.success : AppColors.error,
                          ),
                        );
                      },
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Link'),
              ),
            ],
          ),
        ),
      );
    } finally {
      resetEmailController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali ke Profile',
          onPressed: _backToBuyerProfile,
        ),
        title: const Text('Portal Penjual'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [AppColors.lightGreen, AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Branding WijiBumi Seller
                    const Center(
                      child: WijiBumiLogoWithGlow(size: 76),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'WijiBumi Seller',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Login Penjual',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk untuk mengelola toko dan pesanan Anda.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 22),

                    if (_infoBanner != null && _errorBanner == null) ...[
                      GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(14),
                        tintColor: AppColors.success.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.45),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _infoBanner!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_errorBanner != null) ...[
                      GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(14),
                        tintColor: AppColors.error.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.45),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorBanner!,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_showRegisterCta) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _openSellerRegister,
                                icon: const Icon(Icons.person_add_alt_1, size: 16),
                                label: const Text('Daftar Akun Penjual Sekarang'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              label: 'Email Penjual',
                              hint: 'contoh@kebun.id',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email wajib diisi';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              label: 'Password',
                              hint: 'Masukkan password Anda',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password wajib diisi';
                                }
                                if (v.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) => setState(
                                      () => _rememberMe = val ?? false),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _rememberMe = !_rememberMe),
                                    child: const Text(
                                      'Ingat saya',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: const Text('Lupa Password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            CustomButton(
                              text: 'Login',
                              icon: Icons.login,
                              isLoading: _isLoading,
                              width: double.infinity,
                              onPressed: _submitLogin,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Belum punya akun penjual?',
                                  style: TextStyle(fontSize: 13),
                                ),
                                TextButton(
                                  onPressed: _openSellerRegister,
                                  child: const Text(
                                    'Daftar Akun Penjual',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: _backToBuyerProfile,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                      label: const Text('Kembali ke Halaman Profile Pembeli'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
