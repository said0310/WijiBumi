import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/lucide_icons.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_room_screen.dart';
import '../orders/order_detail_screen.dart';
import '../orders/orders_screen.dart';
import '../orders/shipment_tracking_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filters = const [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'transaction', 'label': 'Transaksi'},
    {'key': 'order', 'label': 'Pesanan'},
    {'key': 'shipment', 'label': 'Pengiriman'},
    {'key': 'chat', 'label': 'Chat'},
    {'key': 'system', 'label': 'Sistem'},
  ];

  Future<void> _runNotifAction(
    Future<bool> Function(NotificationProvider p) action,
  ) async {
    final provider = context.read<NotificationProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action(provider);
    if (!mounted) return;
    if (!ok && provider.lastError != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.lastError!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(AppNotification notif) async {
    final orderProv = context.read<OrderProvider>();
    final chatProv = context.read<ChatProvider>();
    final myStore = context.read<StoreProvider>().myStore;
    final myUserId = context.read<AuthProvider>().user?.id;
    final navigator = Navigator.of(context);

    if (!notif.isRead) {
      await _runNotifAction((p) => p.markAsRead(notif.id));
      if (!mounted) return;
    }

    final refId = notif.referenceId?.trim();
    switch (notif.type) {
      case 'transaction':
      case 'order':
      case 'shipment':
        var matched = refId != null && refId.isNotEmpty
            ? orderProv.allOrders.where((o) => o.id == refId).firstOrNull
            : null;
        if (matched == null && refId != null && refId.isNotEmpty) {
          await orderProv.loadOrders();
          if (!mounted) return;
          matched = orderProv.allOrders.where((o) => o.id == refId).firstOrNull;
        }
        if (matched != null) {
          final target = (notif.type == 'shipment' && matched.shipment != null)
              ? ShipmentTrackingScreen(order: matched)
              : OrderDetailScreen(order: matched);
          navigator.push(MaterialPageRoute(builder: (_) => target));
        } else {
          navigator.push(
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
          );
        }
        break;
      case 'chat':
        var chat = refId != null && refId.isNotEmpty
            ? chatProv.chats.where((c) => c.id == refId).firstOrNull
            : null;
        if (chat == null && refId != null && refId.isNotEmpty) {
          await chatProv.loadChats(myStoreId: myStore?.id);
          if (!mounted) return;
          chat = chatProv.chats.where((c) => c.id == refId).firstOrNull;
        }
        if (chat != null) {
          final isSellerSide = myStore != null &&
              chat.storeId == myStore.id &&
              chat.buyerId != myUserId;
          final title = isSellerSide
              ? (chat.buyerName ?? 'Pembeli WijiBumi')
              : (chat.storeName ?? 'Toko Mitra');
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                chatId: chat!.id,
                storeId: chat.storeId,
                productId: chat.productId,
                title: title,
                isSellerMode: isSellerSide,
              ),
            ),
          );
        } else {
          navigator.push(
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          );
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifProvider = context.watch<NotificationProvider>();

    final filtered = _selectedFilter == 'all'
        ? notifProvider.notifications
        : notifProvider.notifications
            .where((n) => n.type == _selectedFilter)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (notifProvider.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Baca Semua', style: TextStyle(fontSize: 12)),
              onPressed: () => _runNotifAction((p) => p.markAllAsRead()),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Filter Chips
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_filters.length, (index) {
                    final f = _filters[index];
                    final isSelected = _selectedFilter == f['key'];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == _filters.length - 1 ? 0 : 8,
                      ),
                      child: ChoiceChip(
                        label: Text(f['label']!),
                        selected: isSelected,
                        selectedColor: isDark
                            ? AppColors.secondaryEmerald
                            : AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedFilter = f['key']!),
                      ),
                    );
                  }),
                ),
              ),
            ),

            Expanded(
              child: notifProvider.isLoading &&
                      notifProvider.notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => notifProvider.loadNotifications(),
                      child: filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.notifications_none_outlined,
                              title: 'Belum Ada Notifikasi',
                              message:
                                  'Aktivitas pesanan, pembayaran, pengiriman, dan chat akan tampil di sini.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final notif = filtered[index];
                                return Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 760),
                                    child: _buildNotificationCard(
                                      context,
                                      notif,
                                      isDark,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notif,
    bool isDark,
  ) {
    final (icon, color) = switch (notif.type) {
      'transaction' => (Icons.payments_outlined, AppColors.success),
      'order' => (Icons.receipt_long_outlined, Colors.indigo),
      'shipment' => (Icons.local_shipping_outlined, AppColors.secondary),
      'chat' => (Icons.chat_bubble_outline, AppColors.info),
      _ => (Icons.notifications_outlined, AppColors.primary),
    };

    return InkWell(
      onTap: () => _handleNotificationTap(notif),
      borderRadius: BorderRadius.circular(14),
      child: GlassContainer(
        borderRadius: 14,
        enableGlow: !notif.isRead,
        padding: const EdgeInsets.all(14),
        border: Border.all(
          color: notif.isRead
              ? (isDark ? AppColors.borderDark : AppColors.borderLight)
              : AppColors.secondaryEmerald.withValues(alpha: 0.6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: notif.type == 'chat'
                  ? LucideMessageCircleIcon(size: 20, color: color)
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          DateFormatter.formatFull(notif.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!notif.isRead)
                            InkWell(
                              onTap: () =>
                                  _runNotifAction((p) => p.markAsRead(notif.id)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Tandai dibaca',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondaryEmerald,
                                  ),
                                ),
                              ),
                            ),
                          InkWell(
                            onTap: () => _runNotifAction(
                              (p) => p.deleteNotification(notif.id),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
