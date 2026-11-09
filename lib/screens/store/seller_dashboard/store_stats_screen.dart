import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';

class StoreStatsScreen extends StatelessWidget {
  const StoreStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final products = storeProvider.myStoreProducts;

    // Daily/Weekly simulated metrics
    final totalSales = storeProvider.totalRevenue;
    final weeklySales = totalSales * 0.7;
    final completedOrders = storeProvider.completedOrdersCount;

    // Top selling products sorted by totalSales
    final topProducts = List.from(products);
    topProducts.sort((a, b) => b.totalSales.compareTo(a.totalSales));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Penjualan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Weekly Summary Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Penjualan Minggu Ini', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(weeklySales),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.trending_up, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('+18% vs minggu lalu', style: TextStyle(fontSize: 10, color: AppColors.success)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pesanan Selesai', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(
                        '$completedOrders Pesanan',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('Tingkat kepuasan 99%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Weekly Bar Chart Visual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perkembangan Penjualan 7 Hari Terakhir',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(day: 'Sen', height: 45, isDark: isDark),
                    _buildBar(day: 'Sel', height: 70, isDark: isDark),
                    _buildBar(day: 'Rab', height: 55, isDark: isDark),
                    _buildBar(day: 'Kam', height: 85, isDark: isDark),
                    _buildBar(day: 'Jum', height: 110, isDark: isDark),
                    _buildBar(day: 'Sab', height: 130, isDark: isDark, isHighlight: true),
                    _buildBar(day: 'Min', height: 95, isDark: isDark),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Top Selling Products Section
          const Text(
            'Produk Paling Laris (Best Sellers)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (topProducts.isEmpty)
            const Text('Belum ada data penjualan produk.', style: TextStyle(color: Colors.grey))
          else
            ...topProducts.take(5).map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 45,
                        height: 45,
                        child: Image.network(
                          p.primaryImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.eco),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                          const SizedBox(height: 2),
                          Text('${CurrencyFormatter.format(p.price)} / ${p.unit}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${p.totalSales} Terjual',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                        ),
                        Text(
                          'Sisa: ${p.stock}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String day,
    required double height,
    required bool isDark,
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            color: isHighlight
                ? AppColors.secondary
                : (isDark ? AppColors.primaryLight : AppColors.primary),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
