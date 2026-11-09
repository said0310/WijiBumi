import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/empty_state.dart';
import 'order_detail_screen.dart';
import 'shipment_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _statusTabs = [
    {'label': 'Semua', 'status': ''},
    {'label': 'Menunggu Pembayaran', 'status': AppConstants.statusPendingPayment},
    {'label': 'Menunggu Konfirmasi', 'status': AppConstants.statusAwaitingConfirmation},
    {'label': 'Pesanan Diproses', 'status': AppConstants.statusProcessing},
    {'label': 'Siap Dikirim', 'status': AppConstants.statusReadyToShip},
    {'label': 'Sedang Dikirim', 'status': AppConstants.statusShipped},
    {'label': 'Selesai', 'status': AppConstants.statusCompleted},
    {'label': 'Dibatalkan', 'status': AppConstants.statusCancelled},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
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
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pesanan Saya'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: isDark ? AppColors.primaryLight : AppColors.primary,
          labelColor: isDark ? AppColors.primaryLight : AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          tabs: _statusTabs.map((t) => Tab(text: t['label'])).toList(),
          onTap: (index) {
            orderProvider.setStatusFilter(_statusTabs[index]['status']!);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.loadOrders(),
        child: orderProvider.orders.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Tidak Ada Pesanan',
                message: 'Belum ada transaksi dengan status yang dipilih.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = orderProvider.orders[index];
                  return _buildOrderCard(context, order, isDark, theme);
                },
              ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, bool isDark, ThemeData theme) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Store Name & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      order.storeName ?? 'Toko Mitra',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${order.orderCode} • ${DateFormatter.formatShort(order.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const Divider(height: 18),

            // First item snapshot
            if (order.items.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.network(
                        order.items.first.imageSnapshot ??
                            'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=300&q=80',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.eco),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items.first.productNameSnapshot,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.items.first.quantity} x ${CurrencyFormatter.format(order.items.first.unitPrice)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (order.items.length > 1) ...[
                const SizedBox(height: 6),
                Text(
                  '+ ${order.items.length - 1} produk lainnya',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],

            const Divider(height: 18),

            // Footer: Total & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Belanja', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (order.shipment != null) ...[
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShipmentTrackingScreen(order: order),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Lacak', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Detail', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
