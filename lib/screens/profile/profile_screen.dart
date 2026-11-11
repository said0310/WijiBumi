import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/smart_image.dart';
import '../auth/login_screen.dart';
import '../store/register_store_screen.dart';
import '../store/seller_auth/seller_login_screen.dart';
import '../store/seller_dashboard/seller_main_navigation_screen.dart';
import 'about_screen.dart';
import 'account_security_screen.dart';
import 'address_list_screen.dart';
import 'edit_profile_screen.dart';
import 'help_center_screen.dart';
import 'notifications_screen.dart';
import 'purchase_history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String _appVersion = 'v0.1.0+1';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notifProvider = context.watch<NotificationProvider>();

    final user = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;
    final unreadNotifs = notifProvider.unreadCount;

    final pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFECF4EE);
    final cardBg = isDark ? AppColors.cardDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderDark : const Color(0xFFE0EBE3);
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;
    final mutedTextColor =
        isDark ? AppColors.textMutedDark : const Color(0xFF6B7280);
    final accentGreen =
        isDark ? AppColors.primaryLight : AppColors.forestGreen;
    final iconBoxBg = isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : const Color(0xFFEAF5ED);

    void navigateProtected(Widget page) {
      if (!isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan masuk ke akun WijiBumi terlebih dahulu.'),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    Future<void> handleLogout() async {
      final confirmed = await showGlassConfirmDialog(
        context,
        title: 'Konfirmasi Keluar',
        message: 'Apakah Anda yakin ingin keluar dari akun WijiBumi?',
        cancelText: 'Batal',
        confirmText: 'Keluar',
        confirmColor: AppColors.error,
        icon: Icons.logout,
      );
      if (!confirmed || !context.mounted) return;

      final storeProv = context.read<StoreProvider>();
      final orderProv = context.read<OrderProvider>();
      final cartProv = context.read<CartProvider>();
      final chatProv = context.read<ChatProvider>();
      final addressProv = context.read<AddressProvider>();
      final notifProv = context.read<NotificationProvider>();
      final productProv = context.read<ProductProvider>();
      final appSettingsProv = context.read<AppSettingsProvider>();
      final navigator = Navigator.of(context);

      await authProvider.logout();
      if (!context.mounted) return;
      storeProv.clearSession();
      orderProv.clearSession();
      cartProv.clearSession();
      chatProv.clearSession();
      addressProv.clearSession();
      notifProv.clearSession();
      productProv.resetFilters();
      await appSettingsProv.clearSession();
      if (!context.mounted) return;

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 54,
        titleSpacing: 16,
        title: Text(
          'Akun & Pengaturan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: accentGreen,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_outlined,
                  color: accentGreen,
                  size: 24,
                ),
                tooltip: 'Notifikasi',
                onPressed: () =>
                    navigateProtected(const NotificationsScreen()),
              ),
              if (unreadNotifs > 0)
                Positioned(
                  right: 7,
                  top: 7,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: pageBg, width: 1.2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadNotifs > 99 ? '99+' : '$unreadNotifs',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: borderColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. User Profile Card
                _ProfileCardSurface(
                  backgroundColor: cardBg,
                  borderColor: borderColor,
                  isDark: isDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      _ProfileAvatar(
                        avatarPath: user?.avatarPath,
                        isAuthenticated: isAuthenticated,
                        cardBg: cardBg,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  user?.fullName ?? 'Tamu WijiBumi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                                if (isAuthenticated)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: iconBoxBg,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: accentGreen.withValues(
                                          alpha: 0.14,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      (user?.hasSellerAccess ?? false)
                                          ? 'Petani Mitra'
                                          : 'Pelanggan',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: accentGreen,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'Masuk untuk mengakses fitur akun',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: mutedTextColor,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              (user?.phone != null &&
                                      user!.phone!.trim().isNotEmpty)
                                  ? user.phone!
                                  : '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: mutedTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: iconBoxBg,
                        shape: const CircleBorder(),
                        child: IconButton(
                          constraints: const BoxConstraints.tightFor(
                            width: 38,
                            height: 38,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isAuthenticated ? Icons.edit_outlined : Icons.login,
                            size: 18,
                            color: accentGreen,
                          ),
                          tooltip:
                              isAuthenticated ? 'Edit Profile' : 'Masuk Akun',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => isAuthenticated
                                    ? const EditProfileScreen()
                                    : const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Toko Saya Card (Emerald / Forest Green)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0E4A2D),
                        Color(0xFF17663D),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestGreen.withValues(
                          alpha: isDark ? 0.30 : 0.18,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (authProvider.isSellerSessionAuthenticated) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => storeProvider.hasStore
                                  ? const SellerMainNavigationScreen()
                                  : const RegisterStoreScreen(),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SellerLoginScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        'Toko Saya',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFA7E3B5),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'Pasar Tani',
                                          style: TextStyle(
                                            color: AppColors.forestGreen,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    storeProvider.hasStore
                                        ? (authProvider
                                                .isSellerSessionAuthenticated
                                            ? 'Buka dashboard toko "${storeProvider.myStore?.storeName ?? ''}"'
                                            : 'Masuk portal penjual untuk kelola "${storeProvider.myStore?.storeName ?? ''}"')
                                        : 'Kelola produk, stok & pesanan toko di Pasar Tani',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.86),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Section: Aktivitas & Transaksi
                _SectionHeader(
                  title: 'AKTIVITAS & TRANSAKSI',
                  color: mutedTextColor,
                ),
                const SizedBox(height: 8),
                _ProfileCardSurface(
                  backgroundColor: cardBg,
                  borderColor: borderColor,
                  isDark: isDark,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProfileMenuRow(
                        icon: Icons.receipt_long_outlined,
                        iconBoxBg: iconBoxBg,
                        iconColor: accentGreen,
                        title: 'Riwayat Pembelian',
                        subtitle: 'Semua pesanan yang pernah Anda beli',
                        titleColor: titleColor,
                        subtitleColor: mutedTextColor,
                        onTap: () =>
                            navigateProtected(const PurchaseHistoryScreen()),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 14,
                        endIndent: 14,
                        color: borderColor,
                      ),
                      _ProfileMenuRow(
                        icon: Icons.location_on_outlined,
                        iconBoxBg: iconBoxBg,
                        iconColor: accentGreen,
                        title: 'Alamat Pengiriman',
                        subtitle: 'Kelola daftar alamat & tentukan alamat utama',
                        titleColor: titleColor,
                        subtitleColor: mutedTextColor,
                        onTap: () =>
                            navigateProtected(const AddressListScreen()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Section: Pengaturan & Keamanan
                _SectionHeader(
                  title: 'PENGATURAN & KEAMANAN',
                  color: mutedTextColor,
                ),
                const SizedBox(height: 8),
                _ProfileCardSurface(
                  backgroundColor: cardBg,
                  borderColor: borderColor,
                  isDark: isDark,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProfileMenuRow(
                        icon: Icons.notifications_none_outlined,
                        iconBoxBg: iconBoxBg,
                        iconColor: accentGreen,
                        title: 'Notifikasi',
                        subtitle: 'Transaksi, pesanan, pengiriman, dan chat',
                        titleColor: titleColor,
                        subtitleColor: mutedTextColor,
                        badgeCount: unreadNotifs,
                        onTap: () =>
                            navigateProtected(const NotificationsScreen()),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 14,
                        endIndent: 14,
                        color: borderColor,
                      ),
                      _ProfileMenuRow(
                        icon: Icons.lock_reset_outlined,
                        iconBoxBg: iconBoxBg,
                        iconColor: accentGreen,
                        title: 'Keamanan Akun',
                        subtitle: 'Ubah kata sandi & informasi autentikasi',
                        titleColor: titleColor,
                        subtitleColor: mutedTextColor,
                        onTap: () =>
                            navigateProtected(const AccountSecurityScreen()),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 14,
                        endIndent: 14,
                        color: borderColor,
                      ),
                      _ProfileMenuRow(
                        icon: Icons.tune_outlined,
                        iconBoxBg: iconBoxBg,
                        iconColor: accentGreen,
                        title: 'Pengaturan Aplikasi',
                        subtitle: 'Bahasa, privasi, dan preferensi',
                        titleColor: titleColor,
                        subtitleColor: mutedTextColor,
                        onTap: () =>
                            navigateProtected(const SettingsScreen()),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 14,
                        endIndent: 14,
                        color: borderColor,
                      ),
                      _ThemeToggleRow(
                        isDark: isDark,
                        iconBoxBg: iconBoxBg,
                        iconColor: accentGreen,
                        titleColor: titleColor,
                        subtitleColor: mutedTextColor,
                        onChanged: (val) => themeProvider.toggleTheme(val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Section: Informasi & Bantuan
                _SectionHeader(
                  title: 'INFORMASI & BANTUAN',
                  color: mutedTextColor,
                ),
                const SizedBox(height: 8),
                _ProfileCardSurface(
                  backgroundColor: cardBg,
                  borderColor: borderColor,
                  isDark: isDark,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ProfileMenuRow(
                        icon: Icons.help_outline,
                        iconBoxBg: iconBoxBg,
                        iconColor: accentGreen,
                        title: 'Pusat Bantuan',
                        subtitle: 'FAQ, panduan belanja, dan Customer Service',
                        titleColor: titleColor,
                        subtitleColor: mutedTextColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HelpCenterScreen(),
                            ),
                          );
                        },
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 14,
                        endIndent: 14,
                        color: borderColor,
                      ),
                      _ProfileMenuRow(
                        icon: Icons.info_outline,
                        iconBoxBg: iconBoxBg,
                        iconColor: accentGreen,
                        title: 'Tentang WijiBumi',
                        subtitle:
                            'Versi $_appVersion, kebijakan privasi & ketentuan',
                        titleColor: titleColor,
                        subtitleColor: mutedTextColor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 6. Auth / Logout Button
                if (isAuthenticated)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.error.withValues(alpha: 0.14)
                          : const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: handleLogout,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: AppColors.error,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Keluar dari Akun',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Masuk atau Daftar Akun'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 12),

                // 7. Footer
                Text(
                  'WijiBumi $_appVersion • Pasar Tani Digital',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCardSurface extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final bool isDark;
  final EdgeInsetsGeometry? padding;

  const _ProfileCardSurface({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    required this.isDark,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.045),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          type: MaterialType.transparency,
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarPath;
  final bool isAuthenticated;
  final Color cardBg;
  final bool isDark;

  const _ProfileAvatar({
    required this.avatarPath,
    required this.isAuthenticated,
    required this.cardBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarPath != null && avatarPath!.trim().isNotEmpty;
    final badgeColor =
        isDark ? AppColors.primaryLight : AppColors.forestGreen;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.backgroundDark : const Color(0xFFE9F3EC),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark
                  : const Color(0xFFD2E4D7),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: hasImage
                ? SmartImage(
                    source: avatarPath,
                    fit: BoxFit.cover,
                    fallback: _DefaultAvatarIcon(isDark: isDark),
                  )
                : _DefaultAvatarIcon(isDark: isDark),
          ),
        ),
        if (isAuthenticated)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: cardBg, width: 2),
              ),
              child: Icon(
                Icons.check,
                size: 12,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _DefaultAvatarIcon extends StatelessWidget {
  final bool isDark;

  const _DefaultAvatarIcon({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.backgroundDark : const Color(0xFFE9F3EC),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        size: 30,
        color: isDark ? AppColors.primaryLight : AppColors.forestGreen,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: color,
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconBoxBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;
  final int badgeCount;

  const _ProfileMenuRow({
    required this.icon,
    required this.iconBoxBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBoxBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                      ),
                      if (badgeCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: subtitleColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleRow extends StatelessWidget {
  final bool isDark;
  final Color iconBoxBg;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final ValueChanged<bool> onChanged;

  const _ThemeToggleRow({
    required this.isDark,
    required this.iconBoxBg,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isDark),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBoxBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                isDark ? Icons.dark_mode_outlined : Icons.wb_sunny_outlined,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema Tampilan Gelap',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDark ? 'Mode gelap aktif' : 'Mode terang aktif',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isDark,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD5DED7),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}
