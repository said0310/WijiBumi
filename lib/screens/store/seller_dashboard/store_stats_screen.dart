import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/smart_image.dart';

class StoreStatsScreen extends StatelessWidget {
  const StoreStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final products = storeProvider.myStoreProducts;

    final weeklySales = storeProvider.weeklyRevenue;
    final prevWeekSales = storeProvider.previousWeekRevenue;
    final completedOrders = storeProvider.completedOrdersCount;
    final unitsSold = storeProvider.totalUnitsSold;
    final dailySales = storeProvider.last7DaysSales;

    final maxAmount = dailySales.fold<double>(
      0,
      (maxVal, p) => p.amount > maxVal ? p.amount : maxVal,
    );

    String growthText;
    if (prevWeekSales > 0) {
      final pct = ((weeklySales - prevWeekSales) / prevWeekSales * 100).round();
      growthText = '${pct >= 0 ? '+' : ''}$pct% vs minggu lalu';
    } else if (weeklySales > 0) {
      growthText = 'Aktif minggu ini';
    } else {
      growthText = 'Belum ada transaksi minggu ini';
    }

    final topProducts = List.of(products)
      ..sort((a, b) => b.totalSales.compareTo(a.totalSales));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Penjualan'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
          // Weekly Summary Cards
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Penjualan 7 Hari',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                      Row(
                        children: [
                          Icon(
                            weeklySales >= prevWeekSales
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 14,
                            color: weeklySales >= prevWeekSales
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              growthText,
                              style: TextStyle(
                                fontSize: 10,
                                color: weeklySales >= prevWeekSales
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Produk Terjual & Selesai',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text(
                        '$unitsSold Item',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedOrders Pesanan Selesai',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Dynamic 7-Day Bar Chart from actual store orders
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perkembangan Penjualan 7 Hari Terakhir',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dihitung dari data transaksi toko secara aktual',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 18),
                if (maxAmount == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'Belum ada penjualan terbayar dalam 7 hari terakhir.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: dailySales.map((point) {
                      final ratio = maxAmount > 0 ? (point.amount / maxAmount) : 0.0;
                      final barHeight = (ratio * 120).clamp(6.0, 120.0);
                      final isMax = point.amount == maxAmount && point.amount > 0;
                      return Expanded(
                        child: Column(
                          children: [
                            if (point.amount > 0)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${(point.amount / 1000).round()}k',
                                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              width: 24,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: isMax
                                    ? AppColors.secondary
                                    : (isDark ? AppColors.primaryLight : AppColors.primary),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              point.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Top Selling Products Section
          const Text(
            'Produk Terlaris',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (topProducts.isEmpty)
            const Text('Belum ada data penjualan produk.', style: TextStyle(color: Colors.grey))
          else
            ...topProducts.take(5).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 45,
                            height: 45,
                            child: SmartImage(source: p.primaryImage, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('${CurrencyFormatter.format(p.price)} / ${p.unit}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                    ),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
