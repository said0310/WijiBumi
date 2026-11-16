import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/custom_button.dart';
import 'shipment_tracking_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _updateStatus(String status, {String? paymentStatus, required String message}) async {
    await context.read<OrderProvider>().updateStatus(_currentOrder.id, status);
    setState(() {
      _currentOrder = _currentOrder.copyWith(
        status: status,
        paymentStatus: paymentStatus ?? _currentOrder.paymentStatus,
      );
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showReviewDialog() {
    int rating = 5;
    final reviewCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Beri Ulasan Pesanan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Berikan penilaian untuk kualitas hasil panen & layanan toko:'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      IconButton(
                        icon: Icon(i <= rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                        onPressed: () => setDialogState(() => rating = i),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reviewCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tulis Ulasan Anda',
                    hintText: 'Contoh: Sayur sangat segar, bunga wangi tahan lama...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final text = reviewCtrl.text.trim();
                if (text.isEmpty) return;
                await context.read<OrderProvider>().addReview(
                      orderId: _currentOrder.id,
                      storeId: _currentOrder.storeId,
                      productId: _currentOrder.items.isNotEmpty ? _currentOrder.items.first.productId : null,
                      rating: rating,
                      reviewText: text,
                    );
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ulasan berhasil dikirim! Terima kasih.')),
                  );
                }
              },
              child: const Text('Kirim Ulasan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final order = _currentOrder;
    final addr = order.shippingAddressSnapshot;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

    BoxDecoration cardDeco([Color? bg]) => BoxDecoration(
          color: bg ?? theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status & Code Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.orderCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Waktu Pemesanan: ${DateFormatter.formatFull(order.createdAt)}', style: TextStyle(fontSize: 12, color: textMuted)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Status Pembayaran: ', style: TextStyle(fontSize: 12, color: textMuted)),
                      Text(
                        AppConstants.getPaymentStatusLabel(order.paymentStatus),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: order.paymentStatus == 'paid' ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tracking Card
            if (order.shipment != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: cardDeco(isDark ? AppColors.surfaceDark : AppColors.primaryContainer.withOpacity(0.3)),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.shipment?.courierName ?? 'Kurir Mitra', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('No. Resi: ${order.shipment?.trackingNumber ?? '-'}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShipmentTrackingScreen(order: order))),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero),
                      child: const Text('Lacak', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Shipping Address Snapshot
            Container(
              padding: const EdgeInsets.all(14),
              decoration: cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: AppColors.secondary),
                      SizedBox(width: 6),
                      Text('Alamat Pengiriman (Snapshot)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${addr['recipient_name'] ?? 'Penerima'} • ${addr['phone'] ?? '-'}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addr['address']?.toString() ?? '-',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Items List
            Container(
              padding: const EdgeInsets.all(14),
              decoration: cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(order.storeName ?? 'Toko Mitra', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 16),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Image.network(
                                item.imageSnapshot ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=300&q=80',
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
                                Text(item.productNameSnapshot, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                if (item.qualityGradeSnapshot != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Grade ${item.qualityGradeSnapshot}',
                                    style: TextStyle(fontSize: 11, color: AppColors.forGrade(item.qualityGradeSnapshot), fontWeight: FontWeight.bold),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} ${item.unitSnapshot} x ${CurrencyFormatter.format(item.unitPrice)}',
                                  style: TextStyle(fontSize: 12, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(CurrencyFormatter.format(item.lineTotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Financial Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  _priceRow('Subtotal Produk', CurrencyFormatter.format(order.subtotal)),
                  const SizedBox(height: 6),
                  _priceRow('Biaya Pengiriman', CurrencyFormatter.format(order.shippingFee)),
                  if (order.discountTotal > 0) ...[
                    const SizedBox(height: 6),
                    _priceRow('Diskon', '- ${CurrencyFormatter.format(order.discountTotal)}', valueColor: AppColors.error),
                  ],
                  const Divider(height: 16),
                  _priceRow('Total Pembayaran', CurrencyFormatter.format(order.totalAmount), isBold: true, valueColor: primaryColor),
                  const SizedBox(height: 10),
                  Text('Metode: ${order.payment?.paymentMethod ?? 'Transfer Bank'}', style: TextStyle(fontSize: 12, color: textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons based on status
            if (order.status == AppConstants.statusPendingPayment)
              CustomButton(
                text: 'Simulasikan Pembayaran Berhasil',
                width: double.infinity,
                icon: Icons.payment,
                onPressed: () => _updateStatus(
                  AppConstants.statusProcessing,
                  paymentStatus: 'paid',
                  message: 'Pembayaran berhasil dikonfirmasi!',
                ),
              )
            else if (order.status == AppConstants.statusShipped)
              CustomButton(
                text: 'Pesanan Telah Diterima (Selesaikan)',
                width: double.infinity,
                backgroundColor: AppColors.success,
                icon: Icons.check_circle_outline,
                onPressed: () => _updateStatus(
                  AppConstants.statusCompleted,
                  message: 'Pesanan berhasil diselesaikan!',
                ),
              )
            else if (order.status == AppConstants.statusCompleted)
              CustomButton(
                text: 'Beri Ulasan Produk & Toko',
                width: double.infinity,
                icon: Icons.star_outline,
                onPressed: _showReviewDialog,
              ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 15 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor)),
      ],
    );
  }
}
