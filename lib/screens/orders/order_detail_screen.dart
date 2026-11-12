import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/lucide_icons.dart';
import '../../widgets/order_review_dialog.dart';
import '../../widgets/smart_image.dart';
import '../auth/login_screen.dart';
import '../chat/chat_room_screen.dart';
import 'shipment_tracking_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _currentOrder;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  void _openChatWithSeller(Order order) {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          storeId: order.storeId,
          productId:
              order.items.isNotEmpty ? order.items.first.productId : null,
          title: order.storeName ?? 'Toko Mitra',
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(
    Order order,
    String newStatus,
    String successMessage,
  ) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    final orderProv = context.read<OrderProvider>();
    final notifProv = context.read<NotificationProvider>();
    final storeProv = context.read<StoreProvider>();
    final productProv = context.read<ProductProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final ok = await orderProv.updateStatus(order.id, newStatus);
      if (!mounted) return;
      if (ok) {
        await Future.wait([
          notifProv.loadNotifications(),
          if (newStatus == AppConstants.statusCancelled)
            productProv.fetchProducts(),
          if (storeProv.hasStore) storeProv.loadMyStoreData(),
        ]);
        if (!mounted) return;
        final updated = orderProv.allOrders
            .where((o) => o.id == order.id)
            .firstOrNull;
        final nextPaymentStatus =
            (newStatus == AppConstants.statusAwaitingConfirmation ||
                    newStatus == AppConstants.statusCompleted)
                ? 'paid'
                : order.paymentStatus;
        setState(() {
          _currentOrder = updated ??
              order.copyWith(
                status: newStatus,
                paymentStatus: nextPaymentStatus,
              );
        });
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui status pesanan. Coba lagi nanti.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat memproses pesanan.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _confirmPayNow(Order order) async {
    final confirmed = await showGlassConfirmDialog(
      context,
      title: 'Konfirmasi Pembayaran',
      message:
          'Lanjutkan konfirmasi pembayaran untuk pesanan ${order.orderCode} sebesar ${CurrencyFormatter.format(order.totalAmount)} (${order.payment?.paymentMethod ?? 'Transfer Bank'})?',
      cancelText: 'Nanti',
      confirmText: 'Bayar Sekarang',
      icon: Icons.payments_outlined,
    );
    if (!confirmed || !mounted) return;
    await _updateOrderStatus(
      order,
      AppConstants.statusAwaitingConfirmation,
      'Pembayaran berhasil dikonfirmasi! Menunggu proses penjual.',
    );
  }

  Future<void> _confirmCompleteOrder(Order order) async {
    final confirmed = await showGlassConfirmDialog(
      context,
      title: 'Konfirmasi Pesanan Diterima',
      message:
          'Pastikan seluruh barang pada pesanan ${order.orderCode} telah diterima dalam kondisi baik.',
      cancelText: 'Nanti',
      confirmText: 'Pesanan Diterima',
      icon: Icons.check_circle_outline,
    );
    if (!confirmed || !mounted) return;
    await _updateOrderStatus(
      order,
      AppConstants.statusCompleted,
      'Pesanan berhasil diselesaikan!',
    );
  }

  Future<void> _confirmCancelOrder(Order order) async {
    final confirmed = await showGlassConfirmDialog(
      context,
      title: 'Batalkan Pesanan?',
      message:
          'Apakah Anda yakin ingin membatalkan pesanan ${order.orderCode}?',
      cancelText: 'Kembali',
      confirmText: 'Batalkan Pesanan',
      confirmColor: AppColors.error,
      icon: Icons.cancel_outlined,
    );
    if (!confirmed || !mounted) return;
    await _updateOrderStatus(
      order,
      AppConstants.statusCancelled,
      'Pesanan ${order.orderCode} berhasil dibatalkan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderProv = context.watch<OrderProvider>();
    final order = orderProv.allOrders
            .where((o) => o.id == _currentOrder.id)
            .firstOrNull ??
        _currentOrder;
    final isReviewed = orderProv.isOrderFullyReviewed(order);

    final addr = order.shippingAddressSnapshot;
    final recipientName = addr['recipient_name']?.toString() ?? 'Penerima';
    final recipientPhone = addr['phone']?.toString() ?? '-';
    final recipientAddress = addr['address']?.toString() ?? '-';

    final canShowTracking = order.shipment != null &&
        order.status != AppConstants.statusPendingPayment &&
        order.status != AppConstants.statusCancelled;

    final canCancel =
        order.status == AppConstants.statusPendingPayment ||
        order.status == AppConstants.statusAwaitingConfirmation ||
        order.status == AppConstants.statusProcessing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status & Code Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              order.orderCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            OrderStatusBadge(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Waktu Pemesanan: ${DateFormatter.formatFull(order.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Status Pembayaran:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                            Text(
                              AppConstants.getPaymentStatusLabel(
                                order.paymentStatus,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: order.paymentStatus == 'paid'
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tracking Card (only after payment confirmed and not cancelled)
                  if (canShowTracking) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.shipment?.courierName ?? 'Kurir Mitra',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No. Resi: ${order.shipment?.trackingNumber ?? '-'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ShipmentTrackingScreen(order: order),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Lacak',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Shipping Address Snapshot
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Alamat Pengiriman (Snapshot)',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$recipientName • $recipientPhone',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipientAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        if (order.buyerNote != null &&
                            order.buyerNote!.trim().isNotEmpty) ...[
                          const Divider(height: 16),
                          Text(
                            'Catatan Pembeli: ${order.buyerNote!.trim()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Order Items List
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.storeName ?? 'Toko Mitra',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        ...order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: SmartImage(
                                      source: item.imageSnapshot ??
                                          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=300&q=80',
                                      fit: BoxFit.cover,
                                      fallback: const Icon(Icons.eco),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productNameSnapshot,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (item.qualityGradeSnapshot != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Grade ${item.qualityGradeSnapshot}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gradeA,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.quantity} ${item.unitSnapshot} x ${CurrencyFormatter.format(item.unitPrice)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppColors.textMutedDark
                                              : AppColors.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(item.lineTotal),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Financial Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rincian Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPriceRow(
                          'Subtotal Produk',
                          CurrencyFormatter.format(order.subtotal),
                        ),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                          'Biaya Pengiriman',
                          CurrencyFormatter.format(order.shippingFee),
                        ),
                        if (order.discountTotal > 0) ...[
                          const SizedBox(height: 6),
                          _buildPriceRow(
                            'Diskon',
                            '- ${CurrencyFormatter.format(order.discountTotal)}',
                            valueColor: AppColors.error,
                          ),
                        ],
                        const Divider(height: 16),
                        _buildPriceRow(
                          'Total Pembayaran',
                          CurrencyFormatter.format(order.totalAmount),
                          isBold: true,
                          valueColor: isDark
                              ? AppColors.primaryLight
                              : AppColors.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Metode: ${order.payment?.paymentMethod ?? 'Transfer Bank'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Chat Seller button
                  OutlinedButton.icon(
                    onPressed: () => _openChatWithSeller(order),
                    icon: LucideMessageCircleIcon(
                      size: 18,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    label: const Text('Hubungi Penjual'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                    ),
                  ),

                  // Action Buttons based on status
                  if (order.status == AppConstants.statusPendingPayment) ...[
                    const SizedBox(height: 10),
                    CustomButton(
                      text: 'Konfirmasi Pembayaran',
                      width: double.infinity,
                      icon: Icons.payment,
                      isLoading: _isUpdatingStatus,
                      onPressed: () => _confirmPayNow(order),
                    ),
                  ] else if (order.status == AppConstants.statusShipped) ...[
                    const SizedBox(height: 10),
                    CustomButton(
                      text: 'Pesanan Telah Diterima (Selesaikan)',
                      width: double.infinity,
                      backgroundColor: AppColors.success,
                      icon: Icons.check_circle_outline,
                      isLoading: _isUpdatingStatus,
                      onPressed: () => _confirmCompleteOrder(order),
                    ),
                  ] else if (order.status == AppConstants.statusCompleted) ...[
                    const SizedBox(height: 10),
                    CustomButton(
                      text: isReviewed
                          ? 'Semua Produk Sudah Diulas'
                          : 'Beri Ulasan Produk & Toko',
                      width: double.infinity,
                      isOutlined: isReviewed,
                      icon: isReviewed
                          ? Icons.check_circle_outline
                          : Icons.star_outline,
                      onPressed: () =>
                          showOrderReviewDialog(context, order: order),
                    ),
                  ],

                  if (canCancel) ...[
                    const SizedBox(height: 10),
                    CustomButton(
                      text: 'Batalkan Pesanan',
                      width: double.infinity,
                      isOutlined: true,
                      backgroundColor: AppColors.error,
                      textColor: AppColors.error,
                      icon: Icons.cancel_outlined,
                      isLoading: _isUpdatingStatus,
                      onPressed: () => _confirmCancelOrder(order),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
