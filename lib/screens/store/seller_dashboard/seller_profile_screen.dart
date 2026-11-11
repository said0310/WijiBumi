import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/smart_image.dart';
import '../../main_navigation_screen.dart';
import '../../profile/account_security_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../profile/settings_screen.dart';
import '../seller_auth/seller_login_screen.dart';
import 'seller_ui_components.dart';
import 'store_finance_screen.dart';
import 'store_promotions_screen.dart';
import 'store_reviews_screen.dart';
import 'store_settings_screen.dart';
import 'store_stats_screen.dart';
import 'store_verification_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showGlassConfirmDialog(
      context,
      title: 'Keluar dari Akun Penjual?',
      message: 'Anda akan diarahkan kembali ke halaman Login Penjual.',
      confirmText: 'Logout',
      confirmColor: AppColors.error,
    );
    if (!ok || !context.mounted) return;

    await context.read<AuthProvider>().logoutSeller();
    if (!context.mounted) return;
    context.read<StoreProvider>().clearSession();
    context.read<OrderProvider>().clearSession();
    context.read<CartProvider>().clearSession();
    context.read<ChatProvider>().clearSession();
    context.read<AddressProvider>().clearSession();
    context.read<NotificationProvider>().clearSession();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SellerLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);
    final authProvider = context.watch<AuthProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final user = authProvider.user;
    final store = storeProvider.myStore;

    final avatarSource =
        (user?.avatarPath != null && user!.avatarPath!.isNotEmpty)
            ? user.avatarPath
            : store?.logoPath;
    final rawName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : (store?.storeName.trim().isNotEmpty == true
            ? store!.storeName.trim()
            : 'Mitra Penjual');
    final displayName = rawName;
    final initialChar =
        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'P';

    return Scaffold(
      backgroundColor: tokens.pageBg,
      appBar: AppBar(
        backgroundColor: tokens.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          'Profile Penjual',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: tokens.accentGreen,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: tokens.borderColor),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              // Seller Profile Card
              SellerCardSurface(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.softMintBg,
                            border: Border.all(
                              color: tokens.borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: avatarSource != null && avatarSource.isNotEmpty
                              ? ClipOval(
                                  child: SmartImage(
                                    source: avatarSource,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initialChar,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: tokens.accentGreen,
                                    ),
                                  ),
                                ),
                        ),
                        if (store?.isApproved == true)
                          Positioned(
                            right: -1,
                            bottom: -1,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: tokens.accentGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: tokens.cardBg,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.check,
                                size: 12,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: tokens.titleColor,
                            ),
                          ),
                          if (store != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 14,
                                  color: tokens.accentGreen,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    store.storeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.accentGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? store?.email ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.mutedTextColor,
                            ),
                          ),
                          Text(
                            user?.phone ?? store?.phone ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: tokens.softMintBg,
                      shape: const CircleBorder(),
                      child: IconButton(
                        constraints: const BoxConstraints.tightFor(
                          width: 38,
                          height: 38,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Edit Profile Penjual',
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: tokens.accentGreen,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _SellerSectionLabel(title: 'Akun & Toko'),
              const SizedBox(height: 8),
              SellerCardSurface(
                borderRadius: 20,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.person_outline,
                      title: 'Edit Profile Penjual',
                      subtitle:
                          'Perbarui foto, nama lengkap, dan nomor HP penjual',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: tokens.borderColor,
                    ),
                    _MenuTile(
                      icon: Icons.storefront_outlined,
                      title: 'Pengaturan Toko',
                      subtitle:
                          'Nama toko, deskripsi, lokasi kebun & jam operasional',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreSettingsScreen(),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: tokens.borderColor,
                    ),
                    _MenuTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Verifikasi Toko',
                      subtitle: store?.verificationStatusLabel ??
                          'Periksa status verifikasi',
                      trailingBadge: store == null
                          ? null
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (store.isApproved
                                        ? AppColors.success
                                        : AppColors.warning)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                store.isApproved ? 'Terverifikasi' : 'Tinjau',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: store.isApproved
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreVerificationScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _SellerSectionLabel(title: 'Operasional & Performa Toko'),
              const SizedBox(height: 8),
              SellerCardSurface(
                borderRadius: 20,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Keuangan & Penarikan Saldo',
                      subtitle: 'Pantau pendapatan dan ajukan pencairan dana',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreFinanceScreen(),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: tokens.borderColor,
                    ),
                    _MenuTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Statistik Penjualan',
                      subtitle: 'Grafik omzet 7 hari terakhir dan produk terlaris',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreStatsScreen(),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: tokens.borderColor,
                    ),
                    _MenuTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Promosi & Voucher Toko',
                      subtitle: 'Buat kode promo untuk meningkatkan penjualan',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StorePromotionsScreen(),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: tokens.borderColor,
                    ),
                    _MenuTile(
                      icon: Icons.star_outline_rounded,
                      title: 'Ulasan Pembeli',
                      subtitle:
                          'Lihat dan balas ulasan dari customer toko Anda',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreReviewsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _SellerSectionLabel(title: 'Keamanan & Preferensi'),
              const SizedBox(height: 8),
              SellerCardSurface(
                borderRadius: 20,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.tune_outlined,
                      title: 'Pengaturan Aplikasi',
                      subtitle: 'Tema tampilan, notifikasi, bahasa & privasi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: tokens.borderColor,
                    ),
                    _MenuTile(
                      icon: Icons.security_outlined,
                      title: 'Keamanan Akun',
                      subtitle:
                          'Ubah password dan keamanan akun Supabase Auth',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountSecurityScreen(),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: tokens.borderColor,
                    ),
                    _MenuTile(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Beralih ke Mode Pembeli',
                      subtitle: 'Kembali ke Beranda marketplace sebagai pembeli',
                      onTap: () async {
                        final sp = context.read<StoreProvider>();
                        final pp = context.read<ProductProvider>();
                        await Future.wait([
                          sp.loadStores(),
                          pp.fetchProducts(),
                        ]);
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.error.withValues(alpha: 0.14)
                      : const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.28),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: () => _confirmLogout(context),
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      'Logout Penjual',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Keluar dari dashboard penjual ke halaman Login Penjual',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerSectionLabel extends StatelessWidget {
  final String title;

  const _SellerSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    final tokens =
        SellerThemeTokens(Theme.of(context).brightness == Brightness.dark);

    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: tokens.accentGreen,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: tokens.titleColor,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailingBadge;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    final tokens =
        SellerThemeTokens(Theme.of(context).brightness == Brightness.dark);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: SellerIconBox(icon: icon, color: tokens.accentGreen),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: tokens.titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.5, color: tokens.mutedTextColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null) ...[
            trailingBadge!,
            const SizedBox(width: 6),
          ],
          Icon(
            Icons.chevron_right,
            size: 20,
            color: tokens.mutedTextColor,
          ),
        ],
      ),
    );
  }
}
