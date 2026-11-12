import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../models/order.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/lucide_icons.dart';
import '../../widgets/order_review_dialog.dart';
import '../../widgets/smart_image.dart';
import '../auth/login_screen.dart';
import '../chat/chat_room_screen.dart';
import '../profile/profile_screen.dart';
import 'order_detail_screen.dart';
import 'shipment_tracking_screen.dart';

enum _OrderSortOption { newest, oldest, highestTotal, lowestTotal }

class _OrderStatusFilterTab {
  final String label;
  final Set<String> statuses;

  const _OrderStatusFilterTab({
    required this.label,
    required this.statuses,
  });
}

class OrdersScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const OrdersScreen({super.key, this.onProfileTap});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const List<_OrderStatusFilterTab> _statusTabs = [
    _OrderStatusFilterTab(label: 'Semua', statuses: {}),
    _OrderStatusFilterTab(
      label: 'Menunggu Pembayaran',
      statuses: {AppConstants.statusPendingPayment},
    ),
    _OrderStatusFilterTab(
      label: 'Menunggu Konfirmasi',
      statuses: {AppConstants.statusAwaitingConfirmation},
    ),
    _OrderStatusFilterTab(
      label: 'Pesanan Diproses',
      statuses: {
        AppConstants.statusProcessing,
        AppConstants.statusReadyToShip,
      },
    ),
    _OrderStatusFilterTab(
      label: 'Dikirim',
      statuses: {AppConstants.statusShipped},
    ),
    _OrderStatusFilterTab(
      label: 'Selesai',
      statuses: {AppConstants.statusCompleted},
    ),
    _OrderStatusFilterTab(
      label: 'Dibatalkan',
      statuses: {AppConstants.statusCancelled},
    ),
  ];

  int _selectedTabIndex = 0;
  _OrderSortOption _sortOption = _OrderSortOption.newest;
  bool _previewEmptyState = false;
  final Set<String> _processingOrderIds = {};

  bool get _hasActiveFilter =>
      _selectedTabIndex != 0 || _sortOption != _OrderSortOption.newest;

  List<Order> _getVisibleOrders(List<Order> allOrders) {
    final activeStatuses = _statusTabs[_selectedTabIndex].statuses;
    final list = activeStatuses.isEmpty
        ? List<Order>.from(allOrders)
        : allOrders
            .where((o) => activeStatuses.contains(o.status))
            .toList();

    switch (_sortOption) {
      case _OrderSortOption.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _OrderSortOption.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _OrderSortOption.highestTotal:
        list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case _OrderSortOption.lowestTotal:
        list.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }
    return list;
  }

  void _openProfile() {
    if (widget.onProfileTap != null) {
      widget.onProfileTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _showFilterSheet() async {
    var tempTab = _selectedTabIndex;
    var tempSort = _sortOption;

    await showGlassBottomSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final accentGreen =
            isDark ? AppColors.primaryLight : AppColors.forestGreen;
        final titleColor =
            isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;

        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Filter & Urutkan Pesanan',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempTab = 0;
                              tempSort = _OrderSortOption.newest;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: accentGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Urutkan Berdasarkan',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChipPill(
                          label: 'Terbaru',
                          selected: tempSort == _OrderSortOption.newest,
                          isDark: isDark,
                          onTap: () => setSheetState(
                            () => tempSort = _OrderSortOption.newest,
                          ),
                        ),
                        _FilterChipPill(
                          label: 'Terlama',
                          selected: tempSort == _OrderSortOption.oldest,
                          isDark: isDark,
                          onTap: () => setSheetState(
                            () => tempSort = _OrderSortOption.oldest,
                          ),
                        ),
                        _FilterChipPill(
                          label: 'Total Tertinggi',
                          selected: tempSort == _OrderSortOption.highestTotal,
                          isDark: isDark,
                          onTap: () => setSheetState(
                            () => tempSort = _OrderSortOption.highestTotal,
                          ),
                        ),
                        _FilterChipPill(
                          label: 'Total Terendah',
                          selected: tempSort == _OrderSortOption.lowestTotal,
                          isDark: isDark,
                          onTap: () => setSheetState(
                            () => tempSort = _OrderSortOption.lowestTotal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status Pesanan',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_statusTabs.length, (i) {
                        return _FilterChipPill(
                          label: _statusTabs[i].label,
                          selected: tempTab == i,
                          isDark: isDark,
                          onTap: () => setSheetState(() => tempTab = i),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTabIndex = tempTab;
                          _sortOption = tempSort;
                          _previewEmptyState = false;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    if (_processingOrderIds.contains(order.id)) return;
    setState(() => _processingOrderIds.add(order.id));

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
      if (mounted) {
        setState(() => _processingOrderIds.remove(order.id));
      }
    }
  }

  Future<void> _handlePayNow(Order order) async {
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
      'Pembayaran berhasil dikonfirmasi! Menunggu konfirmasi penjual.',
    );
  }

  Future<void> _handleCompleteOrder(Order order) async {
    final confirmed = await showGlassConfirmDialog(
      context,
      title: 'Konfirmasi Pesanan Diterima',
      message:
          'Pastikan seluruh produk pada pesanan ${order.orderCode} telah diterima dalam kondisi baik. Setelah dikonfirmasi, pesanan dinyatakan selesai.',
      cancelText: 'Nanti',
      confirmText: 'Pesanan Diterima',
      icon: Icons.check_circle_outline,
    );
    if (!confirmed || !mounted) return;
    await _updateOrderStatus(
      order,
      AppConstants.statusCompleted,
      'Pesanan ${order.orderCode} selesai! Terima kasih telah berbelanja di WijiBumi.',
    );
  }

  Future<void> _handleCancelOrder(Order order) async {
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

  Future<void> _showReviewDialog(Order order) {
    return showOrderReviewDialog(context, order: order);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderProvider = context.watch<OrderProvider>();
    final visibleOrders = _getVisibleOrders(orderProvider.allOrders);
    final showEmpty = _previewEmptyState || visibleOrders.isEmpty;

    final pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFECF4EE);
    final cardBg = isDark ? AppColors.cardDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderDark : const Color(0xFFE0EBE3);
    final accentGreen =
        isDark ? AppColors.primaryLight : AppColors.forestGreen;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;
    final mutedTextColor =
        isDark ? AppColors.textMutedDark : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 54,
        titleSpacing: ModalRoute.of(context)?.canPop == true ? 4 : 16,
        iconTheme: IconThemeData(color: accentGreen),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Daftar Pesanan Saya',
            maxLines: 1,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: accentGreen,
              letterSpacing: -0.3,
            ),
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.tune, color: accentGreen, size: 22),
                tooltip: 'Filter Pesanan',
                onPressed: _showFilterSheet,
              ),
              if (_hasActiveFilter)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryEmerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: pageBg, width: 1.2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tooltip(
              message: 'Profil Pengguna',
              child: InkWell(
                onTap: _openProfile,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_outline,
                    size: 19,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: pageBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: SizedBox(
              height: 49,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 9),
                child: Row(
                  children: List.generate(_statusTabs.length, (index) {
                    final isSelected = _selectedTabIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == _statusTabs.length - 1 ? 0 : 8,
                      ),
                      child: _StatusPillButton(
                        label: _statusTabs[index].label,
                        selected: isSelected,
                        isDark: isDark,
                        borderColor: borderColor,
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index;
                            _previewEmptyState = false;
                          });
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.loadOrders(),
        child: orderProvider.isLoading && orderProvider.allOrders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : showEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _previewEmptyState
                        ? 'Pratinjau Status Kosong'
                        : 'Tidak Ada Pesanan',
                    message: _previewEmptyState
                        ? 'Ini adalah tampilan halaman ketika Anda belum memiliki transaksi pada status terpilih.'
                        : 'Belum ada transaksi dengan status yang dipilih.',
                    buttonText:
                        _previewEmptyState ? 'Tampilkan Daftar Pesanan' : null,
                    onButtonPressed: _previewEmptyState
                        ? () => setState(() => _previewEmptyState = false)
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    itemCount: visibleOrders.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (index == visibleOrders.length) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: _EmptyPreviewFooter(
                              mutedTextColor: mutedTextColor,
                              accentGreen: accentGreen,
                              onPreviewTap: () =>
                                  setState(() => _previewEmptyState = true),
                            ),
                          ),
                        );
                      }

                      final order = visibleOrders[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _OrderCard(
                            order: order,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            titleColor: titleColor,
                            mutedTextColor: mutedTextColor,
                            accentGreen: accentGreen,
                            isDark: isDark,
                            isProcessing:
                                _processingOrderIds.contains(order.id),
                            isReviewed: orderProvider.isOrderFullyReviewed(order),
                            onTapCard: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailScreen(order: order),
                                ),
                              );
                            },
                            onChatSeller: () => _openChatWithSeller(order),
                            onTrackShipment: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ShipmentTrackingScreen(order: order),
                                ),
                              );
                            },
                            onPayNow: () => _handlePayNow(order),
                            onCancelOrder: () => _handleCancelOrder(order),
                            onCompleteOrder: () => _handleCompleteOrder(order),
                            onReviewOrder: () => _showReviewDialog(order),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _StatusPillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _StatusPillButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? (isDark ? AppColors.primaryLight : AppColors.forestGreen)
        : (isDark ? AppColors.surfaceDark : const Color(0xFFE3EFE7));
    final textColor = selected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? AppColors.textSecondaryDark : AppColors.neutralDark);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor:
          isDark ? AppColors.primaryLight : AppColors.forestGreen,
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFE9F4EC),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? AppColors.textPrimaryDark : AppColors.neutralDark),
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      showCheckmark: false,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final Color cardBg;
  final Color borderColor;
  final Color titleColor;
  final Color mutedTextColor;
  final Color accentGreen;
  final bool isDark;
  final bool isProcessing;
  final bool isReviewed;
  final VoidCallback onTapCard;
  final VoidCallback onChatSeller;
  final VoidCallback onTrackShipment;
  final VoidCallback onPayNow;
  final VoidCallback onCancelOrder;
  final VoidCallback onCompleteOrder;
  final VoidCallback onReviewOrder;

  const _OrderCard({
    required this.order,
    required this.cardBg,
    required this.borderColor,
    required this.titleColor,
    required this.mutedTextColor,
    required this.accentGreen,
    required this.isDark,
    required this.isProcessing,
    required this.isReviewed,
    required this.onTapCard,
    required this.onChatSeller,
    required this.onTrackShipment,
    required this.onPayNow,
    required this.onCancelOrder,
    required this.onCompleteOrder,
    required this.onReviewOrder,
  });

  @override
  Widget build(BuildContext context) {
    final isPendingPayment = order.status == AppConstants.statusPendingPayment;
    final hasFirstItem = order.items.isNotEmpty;
    final firstItem = hasFirstItem ? order.items.first : null;
    final totalProducts = order.items.length;
    final canTrack = order.shipment != null &&
        !isPendingPayment &&
        order.status != AppConstants.statusCancelled;
    final deadline = order.createdAt.add(const Duration(hours: 24));
    final softMintBg = isDark
        ? AppColors.primary.withValues(alpha: 0.14)
        : const Color(0xFFEBF5EE);
    final productBlockBg = isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.55)
        : const Color(0xFFF0F7F2);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.045),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTapCard,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Store Header + Status Pill
                LayoutBuilder(
                  builder: (context, headerConstraints) {
                    return Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 17,
                                color: accentGreen,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.storeName ?? 'Toko Mitra',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: headerConstraints.maxWidth * 0.56,
                          ),
                          child: _OrganicStatusBadge(
                            status: order.status,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 4),

                // 2. Date & Invoice
                Text(
                  '${DateFormatter.formatShort(order.createdAt)} • ${order.orderCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedTextColor,
                  ),
                ),

                // 3. Payment Deadline Banner (ONLY for Pending Payment)
                if (isPendingPayment && order.paymentStatus != 'paid') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: softMintBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Bayar sebelum ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: titleColor,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${DateFormatter.formatShort(deadline)}, ${DateFormatter.formatTime(deadline)} WIB',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 4. Product Snapshot Block
                if (firstItem != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: productBlockBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardBg,
                            border: Border.all(color: borderColor),
                          ),
                          child: ClipOval(
                            child: SmartImage(
                              source: firstItem.imageSnapshot,
                              fit: BoxFit.cover,
                              fallback: Container(
                                color: softMintBg,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.eco_outlined,
                                  color: accentGreen,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstItem.productNameSnapshot,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${firstItem.quantity} ${firstItem.unitSnapshot} x ${CurrencyFormatter.format(firstItem.unitPrice)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: mutedTextColor,
                                ),
                              ),
                              if (totalProducts > 1) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '+ ${totalProducts - 1} produk lainnya',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: accentGreen,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 5),
                              _ShippingInfoLine(
                                order: order,
                                isDark: isDark,
                                mutedTextColor: mutedTextColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // 5. Total & Shipping Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        isPendingPayment
                            ? 'Total Tagihan:'
                            : 'Total Pesanan ($totalProducts produk):',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: mutedTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                if (order.shippingFee > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '(Termasuk ongkos kirim ${CurrencyFormatter.format(order.shippingFee)})',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: mutedTextColor,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // 6. Action Buttons
                _buildActionRow(
                  isPendingPayment: isPendingPayment,
                  canTrack: canTrack,
                  softMintBg: softMintBg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required bool isPendingPayment,
    required bool canTrack,
    required Color softMintBg,
  }) {
    final secondaryFg = isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;
    final primaryBg = isDark ? AppColors.primaryLight : AppColors.forestGreen;
    final primaryFg = isDark ? Colors.black : Colors.white;

    if (isPendingPayment) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: _PillActionButton(
              label: 'Batalkan',
              backgroundColor: softMintBg,
              foregroundColor: secondaryFg,
              onPressed: isProcessing ? null : onCancelOrder,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _PillActionButton(
              label: 'Bayar Sekarang',
              icon: Icon(Icons.payments_outlined, size: 17, color: primaryFg),
              backgroundColor: primaryBg,
              foregroundColor: primaryFg,
              isLoading: isProcessing,
              onPressed: isProcessing ? null : onPayNow,
            ),
          ),
        ],
      );
    }

    if (order.status == AppConstants.statusCompleted) {
      return Row(
        children: [
          Expanded(
            child: _PillActionButton(
              label: 'Hubungi Penjual',
              icon: LucideMessageCircleIcon(size: 16, color: accentGreen),
              backgroundColor: softMintBg,
              foregroundColor: secondaryFg,
              onPressed: onChatSeller,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PillActionButton(
              label: isReviewed ? 'Sudah Diulas' : 'Beri Ulasan',
              icon: Icon(
                isReviewed ? Icons.check_circle_outline : Icons.star_outline,
                size: 17,
                color: isReviewed ? accentGreen : primaryFg,
              ),
              backgroundColor: isReviewed ? softMintBg : primaryBg,
              foregroundColor: isReviewed ? accentGreen : primaryFg,
              onPressed: onReviewOrder,
            ),
          ),
        ],
      );
    }

    if (order.status == AppConstants.statusCancelled) {
      return Row(
        children: [
          Expanded(
            child: _PillActionButton(
              label: 'Hubungi Penjual',
              icon: LucideMessageCircleIcon(size: 16, color: accentGreen),
              backgroundColor: softMintBg,
              foregroundColor: secondaryFg,
              onPressed: onChatSeller,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PillActionButton(
              label: 'Lihat Detail',
              icon: Icon(Icons.receipt_long_outlined, size: 16, color: primaryFg),
              backgroundColor: primaryBg,
              foregroundColor: primaryFg,
              onPressed: onTapCard,
            ),
          ),
        ],
      );
    }

    final canComplete = order.status == AppConstants.statusShipped;
    final canCancel = order.status == AppConstants.statusAwaitingConfirmation ||
        order.status == AppConstants.statusProcessing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _PillActionButton(
                label: 'Hubungi Penjual',
                icon: LucideMessageCircleIcon(size: 16, color: accentGreen),
                backgroundColor: softMintBg,
                foregroundColor: secondaryFg,
                onPressed: onChatSeller,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PillActionButton(
                label: canTrack ? 'Lacak Pengiriman' : 'Detail Pesanan',
                icon: Icon(
                  canTrack
                      ? Icons.near_me_outlined
                      : Icons.receipt_long_outlined,
                  size: 16,
                  color: canComplete ? secondaryFg : primaryFg,
                ),
                backgroundColor: canComplete ? softMintBg : primaryBg,
                foregroundColor: canComplete ? secondaryFg : primaryFg,
                onPressed: canTrack ? onTrackShipment : onTapCard,
              ),
            ),
          ],
        ),
        if (canComplete) ...[
          const SizedBox(height: 8),
          _PillActionButton(
            label: 'Pesanan Diterima',
            icon: Icon(Icons.check_circle_outline, size: 17, color: primaryFg),
            backgroundColor: primaryBg,
            foregroundColor: primaryFg,
            isLoading: isProcessing,
            onPressed: isProcessing ? null : onCompleteOrder,
          ),
        ] else if (canCancel) ...[
          const SizedBox(height: 8),
          _PillActionButton(
            label: 'Batalkan Pesanan',
            icon: const Icon(
              Icons.cancel_outlined,
              size: 16,
              color: AppColors.error,
            ),
            backgroundColor: AppColors.error.withValues(alpha: 0.1),
            foregroundColor: AppColors.error,
            isLoading: isProcessing,
            onPressed: isProcessing ? null : onCancelOrder,
          ),
        ],
      ],
    );
  }
}

class _ShippingInfoLine extends StatelessWidget {
  final Order order;
  final bool isDark;
  final Color mutedTextColor;

  const _ShippingInfoLine({
    required this.order,
    required this.isDark,
    required this.mutedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final shipment = order.shipment;
    if (shipment != null &&
        order.status != AppConstants.statusPendingPayment &&
        order.status != AppConstants.statusCancelled) {
      final courier = shipment.courierName ?? 'Kurir Mitra';
      final service = shipment.serviceName;
      final label = (service != null && service.trim().isNotEmpty)
          ? '$courier • $service'
          : courier;
      final infoColor =
          isDark ? AppColors.primaryLight : const Color(0xFF2E8555);

      return Row(
        children: [
          Icon(Icons.local_shipping_outlined, size: 15, color: infoColor),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: infoColor,
              ),
            ),
          ),
        ],
      );
    }

    final isPending = order.status == AppConstants.statusPendingPayment;
    final text = order.status == AppConstants.statusCancelled
        ? 'Pesanan telah dibatalkan'
        : (isPending
            ? 'Dikemas aman setelah pembayaran terverifikasi'
            : 'Sedang disiapkan oleh toko mitra');

    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 15, color: mutedTextColor),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: mutedTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrganicStatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;

  const _OrganicStatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case AppConstants.statusPendingPayment:
        bg = isDark
            ? AppColors.warning.withValues(alpha: 0.20)
            : const Color(0xFFDFF2CC);
        fg = isDark ? const Color(0xFFFDE68A) : const Color(0xFF3F6212);
        break;
      case AppConstants.statusAwaitingConfirmation:
        bg = isDark
            ? Colors.amber.withValues(alpha: 0.20)
            : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
        break;
      case AppConstants.statusProcessing:
      case AppConstants.statusReadyToShip:
        bg = isDark
            ? AppColors.primary.withValues(alpha: 0.25)
            : const Color(0xFFD7F2DF);
        fg = isDark ? AppColors.primaryLight : const Color(0xFF166534);
        break;
      case AppConstants.statusShipped:
        bg = isDark
            ? Colors.teal.withValues(alpha: 0.22)
            : const Color(0xFFCCFBF1);
        fg = isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
        break;
      case AppConstants.statusCompleted:
        bg = isDark
            ? AppColors.success.withValues(alpha: 0.22)
            : const Color(0xFFDCFCE7);
        fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF14532D);
        break;
      case AppConstants.statusCancelled:
        bg = isDark
            ? AppColors.error.withValues(alpha: 0.22)
            : const Color(0xFFFEE2E2);
        fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
        break;
      default:
        bg = isDark
            ? AppColors.surfaceDark
            : const Color(0xFFE5ECE7);
        fg = isDark ? AppColors.textSecondaryDark : AppColors.neutralDark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppConstants.getStatusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PillActionButton({
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: foregroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyPreviewFooter extends StatelessWidget {
  final Color mutedTextColor;
  final Color accentGreen;
  final VoidCallback onPreviewTap;

  const _EmptyPreviewFooter({
    required this.mutedTextColor,
    required this.accentGreen,
    required this.onPreviewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(
            'Pratinjau Status Kosong:',
            style: TextStyle(
              fontSize: 12,
              color: mutedTextColor,
            ),
          ),
          InkWell(
            onTap: onPreviewTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Lihat Tampilan Kosong',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentGreen,
                  decoration: TextDecoration.underline,
                  decorationColor: accentGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
