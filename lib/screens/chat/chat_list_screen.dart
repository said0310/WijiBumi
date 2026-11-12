import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/store_provider.dart';
import '../../models/chat.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lucide_icons.dart';
import '../../widgets/smart_image.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool sellerOnly;

  const ChatListScreen({super.key, this.sellerOnly = false});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final storeId = context.read<StoreProvider>().myStore?.id;
      final uid = context.read<AuthProvider>().user?.id;
      final chatProv = context.read<ChatProvider>();
      chatProv.loadChats(myStoreId: storeId);
      if (widget.sellerOnly && storeId != null) {
        chatProv.subscribeSellerChats(storeId);
      } else if (!widget.sellerOnly && uid != null) {
        chatProv.subscribeBuyerChats(uid, myStoreId: storeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatProvider = context.watch<ChatProvider>();
    final myStore = context.watch<StoreProvider>().myStore;
    final myUserId = context.watch<AuthProvider>().user?.id;

    final List<Chat> displayedChats = widget.sellerOnly && myStore != null
        ? chatProvider.sellerChats(myStore.id)
        : chatProvider.buyerChats(
            myUserId: myUserId,
            myStoreId: myStore?.id,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sellerOnly ? 'Chat Pembeli Toko' : 'Pesan Masuk'),
      ),
      body: chatProvider.isLoading && displayedChats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => chatProvider.loadChats(myStoreId: myStore?.id),
              child: displayedChats.isEmpty
                  ? EmptyState(
                      icon: Icons.chat_bubble_outline,
                      iconBuilder: (color, size) =>
                          LucideMessageCircleIcon(size: size, color: color),
                      title: 'Belum Ada Pesan',
                      message: widget.sellerOnly
                          ? 'Pesan dari pembeli yang menanyakan produk toko Anda akan tampil di sini.'
                          : 'Mulai percakapan dengan petani atau penjual toko dari halaman produk.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayedChats.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chat = displayedChats[index];
                        final isSellerSide = widget.sellerOnly ||
                            (myStore != null &&
                                chat.storeId == myStore.id &&
                                chat.buyerId != myUserId);

                        final displayTitle = isSellerSide
                            ? (chat.buyerName ?? 'Pembeli WijiBumi')
                            : (chat.storeName ?? 'Toko Mitra');
                        final hasUnread = chat.unreadCount > 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          leading: ClipOval(
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: isSellerSide
                                  ? Container(
                                      color: AppColors.primaryContainer,
                                      child: const Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : SmartImage(
                                      source: chat.storeLogo ??
                                          'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&w=300&q=80',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayTitle,
                                        style: TextStyle(
                                          fontWeight: hasUnread
                                              ? FontWeight.w800
                                              : FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSellerSide) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryEmerald
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Pembeli',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondaryEmerald,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (chat.lastMessageAt != null)
                                Text(
                                  DateFormatter.formatTime(
                                    chat.lastMessageAt!,
                                  ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: hasUnread
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: hasUnread
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.textMutedDark
                                            : AppColors.textMutedLight),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat.lastMessageBody ??
                                          'Mulai percakapan baru...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: hasUnread
                                            ? (isDark
                                                ? Colors.white
                                                : AppColors.textPrimaryLight)
                                            : (isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight),
                                      ),
                                    ),
                                  ),
                                  if (hasUnread) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        chat.unreadCount > 99
                                            ? '99+'
                                            : '${chat.unreadCount}',
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
                              if (chat.productName != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Produk: ${chat.productName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  chatId: chat.id,
                                  storeId: chat.storeId,
                                  productId: chat.productId,
                                  title: displayTitle,
                                  isSellerMode: isSellerSide,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
