import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_widgets.dart';
import 'register_store_screen.dart';
import 'seller_auth/seller_login_screen.dart';
import 'seller_dashboard/seller_main_navigation_screen.dart';

class MyStoreEntryScreen extends StatelessWidget {
  const MyStoreEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final storeProvider = context.watch<StoreProvider>();

    if (!authProvider.isSellerSessionAuthenticated) {
      return const SellerLoginScreen();
    }

    if (storeProvider.hasStore) {
      return const SellerMainNavigationScreen();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Saya'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassContainer(
            borderRadius: 24,
            enableGlow: true,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Store Illustration
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.16),
                        AppColors.secondaryEmerald.withValues(alpha: 0.24),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                      Positioned(
                        right: 20,
                        bottom: 22,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryEmerald,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Kamu Belum Memiliki Toko',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Daftarkan toko untuk mulai menjual produk pertanian di WijiBumi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Daftarkan Toko',
                  icon: Icons.add_business_outlined,
                  width: double.infinity,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterStoreScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

