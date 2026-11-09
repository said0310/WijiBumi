import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/order_status_badge.dart';
import '../../../widgets/empty_state.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _orderTabs = [
    {'label': 'Semua', 'status': ''},
    {'label': 'Pesanan Masuk', 'status': AppConstants.statusPendingPayment},
    {'label': 'Diproses', 'status': AppConstants.statusProcessing},
    {'label': 'Siap Dikirim', 'status': AppConstants.statusReadyToShip},
    {'label': 'Sedang Dikirim', 'status': AppConstants.statusShipped},
    {'label': 'Selesai', 'status': AppConstants.statusCompleted},
    {'label': 'Dibatalkan', 'status': AppConstants.statusCancelled},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _orderTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final allOrders = storeProvider.myStoreOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pesanan Masuk'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _orderTabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _orderTabs.map((tab) {
          final filterStatus = tab['status']!;
          final orders = filterStatus.isEmpty
              ? allOrders
              : allOrders.where((o) => o.status == filterStatus).toList();

          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Tidak Ada Pesanan',
              message: 'Belum ada pesanan dengan kategori status ini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = orders[index];

              return Container(
                padding: const EdgeInsets.all(14),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.orderCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        OrderStatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pembeli: ${order.buyerName ?? 'Pelanggan'} • ${DateFormatter.formatShort(order.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const Divider(height: 18),
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.quantity}x ${item.productNameSnapshot}', style: const TextStyle(fontSize: 12)),
                            Text(CurrencyFormatter.format(item.lineTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Pendapatan Pesanan:', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                            Text(
                              CurrencyFormatter.format(order.subtotal),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                              ),
                            ),
                          ],
                        ),

                        // Action button to update order status
                        _buildStatusActionButton(context, order, storeProvider),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusActionButton(BuildContext context, dynamic order, StoreProvider provider) {
    if (order.status == AppConstants.statusPendingPayment) {
      return ElevatedButton(
        onPressed: () {
          provider.updateOrderStatus(order.id, AppConstants.statusProcessing);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan dikonfirmasi dan diproses.')),
          );
        },
        child: const Text('Konfirmasi & Siapkan', style: TextStyle(fontSize: 11)),
      );
    } else if (order.status == AppConstants.statusProcessing) {
      return ElevatedButton(
        onPressed: () {
          provider.updateOrderStatus(order.id, AppConstants.statusReadyToShip);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paket telah dikemas dan siap dijemput kurir.')),
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        child: const Text('Siap Dikirim', style: TextStyle(fontSize: 11)),
      );
    } else if (order.status == AppConstants.statusReadyToShip) {
      return ElevatedButton(
        onPressed: () {
          provider.updateOrderStatus(order.id, AppConstants.statusShipped);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paket diserahkan ke kurir (Sedang Dikirim).')),
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
        child: const Text('Kirim ke Kurir', style: TextStyle(fontSize: 11)),
      );
    } else if (order.status == AppConstants.statusShipped) {
      return ElevatedButton(
        onPressed: () {
          provider.updateOrderStatus(order.id, AppConstants.statusCompleted);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan diselesaikan!')),
          );
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
        child: const Text('Selesaikan Pesanan', style: TextStyle(fontSize: 11)),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
