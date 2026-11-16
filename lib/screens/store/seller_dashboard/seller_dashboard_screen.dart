import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../widgets/order_status_badge.dart';
import '../../../widgets/smart_image.dart';
import '../../chat/chat_room_screen.dart';
import '../../profile/notifications_screen.dart';
import 'add_edit_product_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_products_screen.dart';
import 'seller_chat_list_screen.dart';
import 'seller_ui_components.dart';
import 'store_finance_screen.dart';
import 'store_promotions_screen.dart';
import 'store_reviews_screen.dart';
import 'store_settings_screen.dart';
import 'store_stats_screen.dart';
import 'store_verification_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onSelectTab;

  const SellerDashboardScreen({super.key, this.onSelectTab});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    final storeProvider = context.read<StoreProvider>();
    final chatProvider = context.read<ChatProvider>();
    await storeProvider.checkMyStore();
    await storeProvider.loadMyStoreData();
    final storeId = storeProvider.myStore?.id;
    if (storeId != null && mounted) {
      await chatProvider.loadChats(myStoreId: storeId);
      chatProvider.subscribeSellerChats(storeId);
    }
  }

  int _tabIndexForOrderStatus(String status) {
    switch (status) {
      case AppConstants.statusAwaitingConfirmation:
        return 0;
      case AppConstants.statusPendingPayment:
        return 1;
      case AppConstants.statusProcessing:
        return 2;
      case AppConstants.statusReadyToShip:
        return 3;
      case AppConstants.statusShipped:
        return 4;
      case AppConstants.statusCompleted:
        return 5;
      case AppConstants.statusCancelled:
        return 6;
      default:
        return 0;
    }
  }

  void _openTabOrPush(int tabIndex, Widget fallbackScreen) {
    if (widget.onSelectTab != null) {
      widget.onSelectTab!(tabIndex);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => fallbackScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);
    final authUser = context.watch<AuthProvider>().user;
    final storeProvider = context.watch<StoreProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final store = storeProvider.myStore;

    if (store == null) {
      return Scaffold(
        backgroundColor: tokens.pageBg,
        appBar: AppBar(
          backgroundColor: tokens.pageBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Beranda Penjual',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: tokens.accentGreen,
            ),
          ),
        ),
        body: const Center(child: Text('Toko belum terdaftar')),
      );
    }

    final statusColor = store.isApproved
        ? AppColors.success
        : (store.verificationStatus == 'rejected' ||
                store.verificationStatus == 'suspended'
            ? AppColors.error
            : AppColors.warning);

    final sellerChats = chatProvider.sellerChats(store.id);
    final recentChats = sellerChats.take(4).toList();
    final recentOrders = storeProvider.recentOrders.take(4).toList();
    final activeProducts = storeProvider.activeProducts.take(4).toList();
    final avatarSource =
        (authUser?.avatarPath != null && authUser!.avatarPath!.isNotEmpty)
            ? authUser.avatarPath
            : store.logoPath;

    return Scaffold(
      backgroundColor: tokens.pageBg,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 12,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Penjual (Avatar, Nama Toko, Status Toko, Notifikasi)
                        SellerCardSurface(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tokens.softMintBg,
                                  border: Border.all(
                                    color: tokens.borderColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: avatarSource != null &&
                                        avatarSource.isNotEmpty
                                    ? ClipOval(
                                        child: SmartImage(
                                          source: avatarSource,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          store.storeName.trim().isNotEmpty
                                              ? store.storeName
                                                  .trim()
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : 'T',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: tokens.accentGreen,
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
                                      store.storeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: tokens.titleColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const StoreVerificationScreen(),
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              store.isApproved
                                                  ? Icons.verified
                                                  : Icons.hourglass_top,
                                              size: 13,
                                              color: statusColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                store.verificationStatusLabel,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Material(
                                    color: tokens.softMintBg,
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      constraints: const BoxConstraints.tightFor(
                                        width: 40,
                                        height: 40,
                                      ),
                                      padding: EdgeInsets.zero,
                                      tooltip: 'Notifikasi',
                                      icon: Icon(
                                        Icons.notifications_none_outlined,
                                        color: tokens.accentGreen,
                                        size: 21,
                                      ),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationsScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (notifProvider.unreadCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: IgnorePointer(
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: tokens.cardBg,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            '${notifProvider.unreadCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (!store.isApproved) ...[
                          SellerCardSurface(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(14),
                            backgroundColor: isDark
                                ? statusColor.withValues(alpha: 0.14)
                                : const Color(0xFFFFFAEB),
                            borderColor: statusColor.withValues(alpha: 0.35),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: statusColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status Toko: ${store.verificationStatusLabel}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        store.verificationNote ??
                                            'Toko sedang ditinjau oleh admin sebelum produk tampil penuh.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tokens.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // 2. Ringkasan Dashboard Penjual
                        Text(
                          'Ringkasan Toko',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: tokens.titleColor,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Highlight Pendapatan (Deep Forest-to-Emerald Gradient)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0E4A2D),
                                Color(0xFF17663D),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forestGreen.withValues(
                                  alpha: isDark ? 0.28 : 0.18,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StoreFinanceScreen(),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ringkasan Pendapatan',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.78),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              CurrencyFormatter.format(
                                                storeProvider.totalRevenue,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 23,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Hari ini: ${CurrencyFormatter.format(storeProvider.todayRevenue)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.all(11),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.18),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Pesanan Masuk',
                                value: '${storeProvider.incomingOrdersCount}',
                                icon: Icons.mark_email_unread_outlined,
                                color: AppColors.secondary,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ManageOrdersScreen(
                                      initialTabIndex: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: 'Sedang Diproses',
                                value: '${storeProvider.processingOrdersCount}',
                                icon: Icons.inventory_2_outlined,
                                color: AppColors.info,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ManageOrdersScreen(
                                      initialTabIndex: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Sedang Dikirim',
                                value: '${storeProvider.shippedOrdersCount}',
                                icon: Icons.local_shipping_outlined,
                                color: AppColors.secondaryEmerald,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ManageOrdersScreen(
                                      initialTabIndex: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: 'Produk Aktif',
                                value: '${storeProvider.activeProductsCount}',
                                icon: Icons.eco_outlined,
                                color: tokens.accentGreen,
                                onTap: () => _openTabOrPush(
                                  3,
                                  const ManageProductsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Pintasan cepat manajemen
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _QuickPill(
                                icon: Icons.bar_chart_rounded,
                                label: 'Statistik',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StoreStatsScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _QuickPill(
                                icon: Icons.local_offer_outlined,
                                label: 'Promosi',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StorePromotionsScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _QuickPill(
                                icon: Icons.star_outline_rounded,
                                label: 'Ulasan',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StoreReviewsScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _QuickPill(
                                icon: Icons.settings_outlined,
                                label: 'Pengaturan Toko',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StoreSettingsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Pesanan Terbaru
                        _SectionHeader(
                          title: 'Pesanan Terbaru',
                          actionText: 'Lihat Semua',
                          onAction: () => _openTabOrPush(
                            2,
                            const ManageOrdersScreen(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (recentOrders.isEmpty)
                          SellerCardSurface(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SellerIconBox(
                                  icon: Icons.receipt_long_outlined,
                                  color: tokens.accentGreen,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Belum ada pesanan terbaru untuk toko Anda.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: tokens.mutedTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...recentOrders.map((order) {
                            final firstItem = order.items.isNotEmpty
                                ? order.items.first.productNameSnapshot
                                : 'Produk Pertanian';
                            final extraItems = order.items.length > 1
                                ? ' +${order.items.length - 1} lainnya'
                                : '';
                            final totalQty = order.items.fold<int>(
                              0,
                              (sum, item) => sum + item.quantity,
                            );
                            final customerName = order.buyerName ??
                                order.shippingAddressSnapshot['recipient_name']
                                    ?.toString() ??
                                'Customer';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SellerCardSurface(
                                borderRadius: 18,
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Text(
                                          order.orderCode,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: tokens.titleColor,
                                          ),
                                        ),
                                        OrderStatusBadge(status: order.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Customer: $customerName',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.titleColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$firstItem$extraItems • $totalQty item',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: tokens.mutedTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
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
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ManageOrdersScreen(
                                                  initialTabIndex:
                                                      _tabIndexForOrderStatus(
                                                    order.status,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: tokens.accentGreen,
                                            side: BorderSide(
                                              color: tokens.borderColor,
                                            ),
                                            backgroundColor: tokens.softMintBg,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 7,
                                            ),
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text(
                                            'Detail Pesanan',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 18),

                        // 4. Chat Terbaru
                        _SectionHeader(
                          title: 'Chat Terbaru',
                          actionText: 'Buka Chat',
                          onAction: () => _openTabOrPush(
                            1,
                            const SellerChatListScreen(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (recentChats.isEmpty)
                          SellerCardSurface(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                SellerIconBox(
                                  icon: Icons.chat_bubble_outline,
                                  color: tokens.accentGreen,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Belum ada pesan masuk dari customer.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: tokens.mutedTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SellerCardSurface(
                            borderRadius: 18,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              children: recentChats.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final chat = entry.value;
                                final buyerName = chat.buyerName ?? 'Customer';
                                return Column(
                                  children: [
                                    if (idx > 0)
                                      Divider(
                                        height: 1,
                                        indent: 14,
                                        endIndent: 14,
                                        color: tokens.borderColor,
                                      ),
                                    ListTile(
                                      onTap: () async {
                                        await chatProvider.openChatById(
                                          chat.id,
                                          myStoreId: store.id,
                                        );
                                        if (!context.mounted) return;
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatRoomScreen(
                                              chatId: chat.id,
                                              storeId: chat.storeId,
                                              productId: chat.productId,
                                              title: buyerName,
                                              isSellerMode: true,
                                            ),
                                          ),
                                        );
                                        if (mounted) {
                                          chatProvider.loadChats(
                                            myStoreId: store.id,
                                          );
                                        }
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor: tokens.softMintBg,
                                        child: chat.buyerAvatar != null &&
                                                chat.buyerAvatar!.isNotEmpty
                                            ? ClipOval(
                                                child: SizedBox(
                                                  width: 40,
                                                  height: 40,
                                                  child: SmartImage(
                                                    source: chat.buyerAvatar,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                buyerName.trim().isNotEmpty
                                                    ? buyerName
                                                        .trim()
                                                        .substring(0, 1)
                                                        .toUpperCase()
                                                    : 'C',
                                                style: TextStyle(
                                                  color: tokens.accentGreen,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                      ),
                                      title: Text(
                                        buyerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: chat.unreadCount > 0
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: tokens.titleColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        chat.lastMessageBody ?? 'Pesan customer',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: tokens.mutedTextColor,
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            DateFormatter.formatTime(
                                              chat.lastMessageAt ??
                                                  chat.createdAt,
                                            ),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: tokens.mutedTextColor,
                                            ),
                                          ),
                                          if (chat.unreadCount > 0) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.error,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${chat.unreadCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // 5. Produk Saya
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text(
                                'Produk Saya',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.titleColor,
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AddEditProductScreen(),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: tokens.accentGreen,
                                    ),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text(
                                      'Tambah Produk',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _openTabOrPush(
                                      3,
                                      const ManageProductsScreen(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: tokens.accentGreen,
                                      foregroundColor:
                                          isDark ? Colors.black : Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text(
                                      'Kelola Produk',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (activeProducts.isEmpty)
                          SellerCardSurface(
                            borderRadius: 16,
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Belum ada produk aktif. Tambahkan hasil panen terbaik Anda sekarang.',
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.mutedTextColor,
                              ),
                            ),
                          )
                        else
                          ...activeProducts.map(
                            (product) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SellerCardSurface(
                                borderRadius: 16,
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 54,
                                        height: 54,
                                        child: SmartImage(
                                          source: product.primaryImage,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                              color: tokens.titleColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${CurrencyFormatter.format(product.price)} / ${product.unit}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: tokens.accentGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (product.stock > 5
                                                ? AppColors.success
                                                : AppColors.warning)
                                            .withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Stok: ${product.stock}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: product.stock > 5
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens =
        SellerThemeTokens(Theme.of(context).brightness == Brightness.dark);

    return SellerCardSurface(
      borderRadius: 18,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SellerIconBox(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tokens.titleColor,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: tokens.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens =
        SellerThemeTokens(Theme.of(context).brightness == Brightness.dark);

    return SellerCardSurface(
      borderRadius: 999,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tokens.accentGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tokens.titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens =
        SellerThemeTokens(Theme.of(context).brightness == Brightness.dark);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: tokens.titleColor,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: tokens.accentGreen),
          child: Text(
            actionText,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
