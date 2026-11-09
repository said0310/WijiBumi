import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import 'manage_products_screen.dart';
import 'manage_orders_screen.dart';
import 'store_finance_screen.dart';
import 'store_settings_screen.dart';
import 'store_reviews_screen.dart';
import 'store_promotions_screen.dart';
import 'store_stats_screen.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final store = storeProvider.myStore;

    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toko Saya')),
        body: const Center(child: Text('Toko belum terdaftar')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(store.storeName),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: store.isApproved
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  store.isApproved ? Icons.verified : Icons.hourglass_top,
                  size: 14,
                  color: store.isApproved ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  store.isApproved ? 'Aktif & Terverifikasi' : 'Menunggu Verifikasi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: store.isApproved ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => storeProvider.loadMyStoreData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E824C), Color(0xFF145A32)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          store.logoPath ??
                              'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${store.city ?? 'Indonesia'} • Rating ${store.rating.toStringAsFixed(1)} ★',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saldo Tersedia: ${CurrencyFormatter.format(storeProvider.availableBalance)}',
                            style: const TextStyle(
                              color: AppColors.secondaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1. Ringkasan Dashboard (Metrics Cards)
              const Text(
                'Ringkasan Penjualan & Operasional',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Produk',
                      value: '${storeProvider.totalProductsCount}',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.blue,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Pesanan Masuk',
                      value: '${storeProvider.incomingOrdersCount}',
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.warning,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Sedang Diproses',
                      value: '${storeProvider.processingOrdersCount}',
                      icon: Icons.sync,
                      color: Colors.purple,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Pesanan Selesai',
                      value: '${storeProvider.completedOrdersCount}',
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pendapatan Toko',
                          style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(storeProvider.totalRevenue),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 30),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu Fitur Penjual
              const Text(
                'Menu Manajemen Toko',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _buildNavCard(
                    title: 'Manajemen Produk',
                    subtitle: 'Tambah & perbarui stok',
                    icon: Icons.add_box_outlined,
                    color: Colors.teal,
                    isDark: isDark,
                    theme: theme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
                      );
                    },
                  ),
                  _buildNavCard(
                    title: 'Manajemen Pesanan',
                    subtitle: 'Proses & kirim paket',
                    icon: Icons.local_shipping_outlined,
                    color: Colors.indigo,
                    isDark: isDark,
                    theme: theme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageOrdersScreen()),
                      );
                    },
                  ),
                  _buildNavCard(
                    title: 'Keuangan & Saldo',
                    subtitle: 'Pencairan rekening',
                    icon: Icons.payments_outlined,
                    color: Colors.green,
                    isDark: isDark,
                    theme: theme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoreFinanceScreen()),
                      );
                    },
                  ),
                  _buildNavCard(
                    title: 'Statistik Penjualan',
                    subtitle: 'Grafik & tren produk',
                    icon: Icons.bar_chart,
                    color: Colors.deepOrange,
                    isDark: isDark,
                    theme: theme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoreStatsScreen()),
                      );
                    },
                  ),
                  _buildNavCard(
                    title: 'Ulasan & Rating',
                    subtitle: 'Balas feedback pembeli',
                    icon: Icons.star_rate_outlined,
                    color: Colors.amber[800]!,
                    isDark: isDark,
                    theme: theme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoreReviewsScreen()),
                      );
                    },
                  ),
                  _buildNavCard(
                    title: 'Promosi & Voucher',
                    subtitle: 'Buat kupon diskon',
                    icon: Icons.discount_outlined,
                    color: Colors.pink,
                    isDark: isDark,
                    theme: theme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StorePromotionsScreen()),
                      );
                    },
                  ),
                  _buildNavCard(
                    title: 'Pengaturan Toko',
                    subtitle: 'Edit profil & alamat',
                    icon: Icons.store_outlined,
                    color: Colors.blueGrey,
                    isDark: isDark,
                    theme: theme,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoreSettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMutedLight),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
