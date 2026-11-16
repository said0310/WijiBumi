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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final store = storeProvider.myStore;

    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toko Saya')),
        body: const Center(child: Text('Toko belum terdaftar')),
      );
    }

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    final metrics = [
      ('Total Produk', '${storeProvider.totalProductsCount}', Icons.inventory_2_outlined, Colors.blue),
      ('Pesanan Masuk', '${storeProvider.incomingOrdersCount}', Icons.receipt_long_outlined, AppColors.warning),
      ('Sedang Diproses', '${storeProvider.processingOrdersCount}', Icons.sync, Colors.purple),
      ('Pesanan Selesai', '${storeProvider.completedOrdersCount}', Icons.check_circle_outline, AppColors.success),
    ];

    final menuItems = [
      ('Manajemen Produk', 'Tambah & perbarui stok', Icons.add_box_outlined, Colors.teal, () => const ManageProductsScreen()),
      ('Manajemen Pesanan', 'Proses & kirim paket', Icons.local_shipping_outlined, Colors.indigo, () => const ManageOrdersScreen()),
      ('Keuangan & Saldo', 'Pencairan rekening', Icons.payments_outlined, Colors.green, () => const StoreFinanceScreen()),
      ('Statistik Penjualan', 'Grafik & tren produk', Icons.bar_chart, Colors.deepOrange, () => const StoreStatsScreen()),
      ('Ulasan & Rating', 'Balas feedback pembeli', Icons.star_rate_outlined, Colors.amber, () => const StoreReviewsScreen()),
      ('Promosi & Voucher', 'Buat kupon diskon', Icons.discount_outlined, Colors.pink, () => const StorePromotionsScreen()),
      ('Pengaturan Toko', 'Edit profil & alamat', Icons.store_outlined, Colors.blueGrey, () => const StoreSettingsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(store.storeName),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (store.isApproved ? AppColors.success : AppColors.warning).withOpacity(0.15),
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
                  gradient: const LinearGradient(colors: [Color(0xFF1E824C), Color(0xFF145A32)]),
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
                          store.logoPath ?? 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.storeName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text('${store.city ?? 'Indonesia'} • Rating ${store.rating.toStringAsFixed(1)} ★', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            'Saldo Tersedia: ${CurrencyFormatter.format(storeProvider.availableBalance)}',
                            style: const TextStyle(color: AppColors.secondaryLight, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Ringkasan Dashboard
              const Text('Ringkasan Penjualan & Operasional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  for (final m in metrics)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: m.$4.withOpacity(0.12), shape: BoxShape.circle),
                            child: Icon(m.$3, color: m.$4, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(m.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(m.$1, style: TextStyle(fontSize: 11, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Pendapatan Toko', style: TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(storeProvider.totalRevenue),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? AppColors.primaryLight : AppColors.primary),
                        ),
                      ],
                    ),
                    const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 30),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu Fitur Penjual
              const Text('Menu Manajemen Toko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  for (final item in menuItems)
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.$5())),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
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
                                  decoration: BoxDecoration(color: item.$4.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(item.$3, color: item.$4, size: 20),
                                ),
                                const Icon(Icons.arrow_forward, size: 14, color: AppColors.textMutedLight),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(item.$2, style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
