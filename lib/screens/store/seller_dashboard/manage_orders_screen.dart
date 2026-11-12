import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/order.dart';
import '../../../providers/store_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/order_status_badge.dart';
import '../../../widgets/smart_image.dart';
import '../../orders/shipment_tracking_screen.dart';
import 'seller_ui_components.dart';

class ManageOrdersScreen extends StatefulWidget {
  final int initialTabIndex;

  const ManageOrdersScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 7 tab status pesanan sesuai alur Manajemen Pesanan Penjual
  static const List<Map<String, String>> _orderTabs = [
    {'label': 'Pesanan Masuk', 'status': AppConstants.statusAwaitingConfirmation},
    {'label': 'Menunggu Pembayaran', 'status': AppConstants.statusPendingPayment},
    {'label': 'Diproses', 'status': AppConstants.statusProcessing},
    {'label': 'Siap Dikirim', 'status': AppConstants.statusReadyToShip},
    {'label': 'Sedang Dikirim', 'status': AppConstants.statusShipped},
    {'label': 'Selesai', 'status': AppConstants.statusCompleted},
    {'label': 'Dibatalkan', 'status': AppConstants.statusCancelled},
  ];

  @override
  void initState() {
    super.initState();
    final safeIdx = widget.initialTabIndex.clamp(0, _orderTabs.length - 1);
    _tabController = TabController(
      length: _orderTabs.length,
      vsync: this,
      initialIndex: safeIdx,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _actorLabel(String role) {
    switch (role) {
      case 'seller':
        return 'Penjual';
      case 'buyer':
        return 'Customer';
      case 'admin':
        return 'Admin';
      default:
        return 'Sistem';
    }
  }

  void _showSellerOrderDetail(
    BuildContext context,
    Order order,
    StoreProvider provider,
  ) {
    final addr = order.shippingAddressSnapshot;
    final recipient =
        addr['recipient_name']?.toString() ?? order.buyerName ?? 'Customer';
    final phone = addr['phone']?.toString() ?? '-';
    final fullAddress = [
      addr['address']?.toString(),
      addr['district']?.toString(),
      addr['city']?.toString(),
      addr['province']?.toString(),
      addr['postal_code']?.toString(),
    ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    showGlassBottomSheet(
      context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tanggal: ${DateFormatter.formatFull(order.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(height: 20),
                const Text(
                  'Informasi Customer & Alamat Pengiriman',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '$recipient ($phone)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fullAddress.isEmpty ? '-' : fullAddress,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (order.buyerNote != null && order.buyerNote!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Catatan Pembeli: "${order.buyerNote}"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const Divider(height: 20),
                const Text(
                  'Produk yang Dipesan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: SmartImage(
                              source: item.imageSnapshot,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productNameSnapshot,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${item.quantity} ${item.unitSnapshot} x ${CurrencyFormatter.format(item.unitPrice)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.lineTotal),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal Produk',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      CurrencyFormatter.format(order.subtotal),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ongkos Kirim', style: TextStyle(fontSize: 12)),
                    Text(
                      CurrencyFormatter.format(order.shippingFee),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Transaksi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
                if (order.shipment != null) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kurir: ${order.shipment!.courierName ?? '-'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Resi: ${order.shipment!.trackingNumber ?? 'Belum diinput'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ShipmentTrackingScreen(order: order),
                            ),
                          );
                        },
                        child: const Text('Lihat Tracking'),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 22),
                const Text(
                  'Riwayat Perubahan Status',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<OrderStatusHistoryEntry>>(
                  future:
                      SupabaseService.instance.getOrderStatusHistory(order.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final entries = snapshot.data ?? [];
                    if (entries.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${AppConstants.getStatusLabel(order.status)} • ${DateFormatter.formatFull(order.updatedAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: entries.map((h) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.forestGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${AppConstants.getStatusLabel(h.status)} (${_actorLabel(h.actorRole)})',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (h.note != null && h.note!.isNotEmpty)
                                      Text(
                                        h.note!,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    Text(
                                      DateFormatter.formatFull(h.createdAt),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildStatusActionButton(
                    context,
                    order,
                    provider,
                    onAfterAction: () {
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInputResiDialog(
    BuildContext context,
    Order order,
    StoreProvider provider, {
    VoidCallback? onAfterAction,
  }) {
    final resiController =
        TextEditingController(text: order.shipment?.trackingNumber ?? '');
    final courierController = TextEditingController(
      text: order.shipment?.courierName ?? 'J&T Express Cargo Tani',
    );
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Nomor Resi Pengiriman'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: courierController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kurir / Ekspedisi',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Nama kurir wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: resiController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Resi',
                    hintText: 'Contoh: TN89201948201',
                  ),
                  validator: (v) => v == null || v.trim().length < 4
                      ? 'Nomor resi minimal 4 karakter'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan Pengiriman (Opsional)',
                    hintText: 'Paket dijemput kurir berpendingin',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await provider.updateOrderStatus(
                order.id,
                AppConstants.statusShipped,
                trackingNumber: resiController.text.trim(),
                courierName: courierController.text.trim(),
                note: noteController.text.trim().isNotEmpty
                    ? noteController.text.trim()
                    : null,
              );
              if (context.mounted) {
                Navigator.pop(ctx);
                if (ok) onAfterAction?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Resi disimpan! Pesanan berstatus Sedang Dikirim.'
                          : 'Gagal memperbarui status pengiriman.',
                    ),
                    backgroundColor: ok ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Kirim Pesanan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);
    final storeProvider = context.watch<StoreProvider>();
    final allOrders = storeProvider.myStoreOrders;

    return Scaffold(
      backgroundColor: tokens.pageBg,
      appBar: AppBar(
        backgroundColor: tokens.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          'Pesanan Penjual',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: tokens.accentGreen,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: tokens.pageBg,
              border: Border(bottom: BorderSide(color: tokens.borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: tokens.accentGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              labelColor: isDark ? Colors.black : Colors.white,
              unselectedLabelColor: tokens.mutedTextColor,
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: _orderTabs.map((t) {
                final status = t['status']!;
                final count =
                    allOrders.where((o) => o.status == status).length;
                return Tab(
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      count > 0 ? '${t['label']} ($count)' : t['label']!,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => storeProvider.loadMyStoreData(),
        child: TabBarView(
          controller: _tabController,
          children: _orderTabs.map((tab) {
            final filterStatus = tab['status']!;
            final orders =
                allOrders.where((o) => o.status == filterStatus).toList();

            if (orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 36),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 780),
                      child: const SellerCardSurface(
                        borderRadius: 22,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Tidak Ada Pesanan',
                          message: 'Belum ada pesanan pada tab status ini.',
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                20 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final order = orders[index];
                final customerName = order.buyerName ??
                    order.shippingAddressSnapshot['recipient_name']
                        ?.toString() ??
                    'Customer';
                final addressText = [
                  order.shippingAddressSnapshot['address']?.toString(),
                  order.shippingAddressSnapshot['city']?.toString(),
                ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: SellerCardSurface(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  order.orderCode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: tokens.titleColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: OrderStatusBadge(status: order.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customer: $customerName • ${DateFormatter.formatShort(order.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: tokens.secondaryTextColor,
                            ),
                          ),
                          if (addressText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Tujuan: $addressText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: tokens.mutedTextColor,
                              ),
                            ),
                          ],
                          if (order.shipment?.trackingNumber != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Resi: ${order.shipment!.trackingNumber} (${order.shipment!.courierName ?? '-'})',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: tokens.emeraldAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          Divider(height: 18, color: tokens.borderColor),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: SmartImage(
                                        source: item.imageSnapshot,
                                        fit: BoxFit.cover,
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: tokens.titleColor,
                                          ),
                                        ),
                                        Text(
                                          '${item.quantity}x @ ${CurrencyFormatter.format(item.unitPrice)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: tokens.mutedTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(item.lineTotal),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.titleColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 18, color: tokens.borderColor),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Transaksi:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: tokens.mutedTextColor,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                        order.totalAmount,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: tokens.accentGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showSellerOrderDetail(
                                        context,
                                        order,
                                        storeProvider,
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: tokens.accentGreen,
                                      ),
                                      child: const Text(
                                        'Detail Pesanan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _buildStatusActionButton(
                                      context,
                                      order,
                                      storeProvider,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusActionButton(
    BuildContext context,
    Order order,
    StoreProvider provider, {
    VoidCallback? onAfterAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);

    if (order.status == AppConstants.statusAwaitingConfirmation) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
              size: 20,
            ),
            tooltip: 'Tolak / Batalkan',
            onPressed: () async {
              final ok = await showGlassConfirmDialog(
                context,
                title: 'Batalkan Pesanan?',
                message: 'Stok produk akan dikembalikan secara otomatis.',
                confirmText: 'Batalkan',
                confirmColor: AppColors.error,
              );
              if (ok) {
                final updated = await provider.updateOrderStatus(
                  order.id,
                  AppConstants.statusCancelled,
                  note: 'Dibatalkan oleh penjual',
                );
                if (context.mounted && !updated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal membatalkan pesanan.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                if (updated) onAfterAction?.call();
              }
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accentGreen,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () async {
              final ok = await provider.updateOrderStatus(
                order.id,
                AppConstants.statusProcessing,
                note: 'Pesanan dikonfirmasi penjual dan mulai diproses',
              );
              if (context.mounted) {
                if (ok) {
                  onAfterAction?.call();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pesanan dikonfirmasi dan sedang diproses.',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal mengonfirmasi pesanan.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Konfirmasi Pesanan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }

    if (order.status == AppConstants.statusPendingPayment) {
      // Status Menunggu Pembayaran tidak boleh diubah manual oleh penjual
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Menunggu validasi sistem',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
      );
    }

    if (order.status == AppConstants.statusProcessing) {
      return ElevatedButton(
        onPressed: () async {
          final ok = await provider.updateOrderStatus(
            order.id,
            AppConstants.statusReadyToShip,
            note: 'Pesanan selesai dikemas dan siap dikirim',
          );
          if (context.mounted) {
            if (ok) {
              onAfterAction?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paket telah dikemas dan siap dikirim.'),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gagal memperbarui status pesanan.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        child: const Text(
          'Siap Dikirim',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }

    if (order.status == AppConstants.statusReadyToShip) {
      return ElevatedButton(
        onPressed: () => _showInputResiDialog(
          context,
          order,
          provider,
          onAfterAction: onAfterAction,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accentGreen,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        child: const Text(
          'Input Resi & Kirim',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }

    if (order.status == AppConstants.statusShipped) {
      // Status Selesai hanya berasal dari konfirmasi penerimaan customer (bukan penjual)
      return OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShipmentTrackingScreen(order: order),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.accentGreen,
          side: BorderSide(color: tokens.borderColor),
          backgroundColor: tokens.softMintBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        icon: const Icon(Icons.local_shipping_outlined, size: 14),
        label: const Text(
          'Menunggu Konfirmasi Customer',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
