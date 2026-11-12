import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/chat.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/lucide_icons.dart';
import '../../../widgets/smart_image.dart';
import '../../chat/chat_room_screen.dart';
import 'seller_ui_components.dart';

class SellerChatListScreen extends StatefulWidget {
  const SellerChatListScreen({super.key});

  @override
  State<SellerChatListScreen> createState() => _SellerChatListScreenState();
}

class _SellerChatListScreenState extends State<SellerChatListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _subscribedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncChats();
    });
  }

  void _syncChats() {
    if (!mounted) return;
    final storeId = context.read<StoreProvider>().myStore?.id;
    if (storeId == null) return;
    final chatProvider = context.read<ChatProvider>();
    chatProvider.loadChats(myStoreId: storeId);
    if (_subscribedStoreId != storeId) {
      _subscribedStoreId = storeId;
      chatProvider.subscribeSellerChats(storeId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openConversation(Chat chat, String storeId) async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.openChatById(chat.id, myStoreId: storeId);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          chatId: chat.id,
          storeId: chat.storeId,
          productId: chat.productId,
          title: chat.buyerName ?? 'Customer',
          isSellerMode: true,
        ),
      ),
    );
    if (mounted) {
      chatProvider.loadChats(myStoreId: storeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);
    final store = context.watch<StoreProvider>().myStore;
    final chatProvider = context.watch<ChatProvider>();

    if (store == null) {
      return Scaffold(
        backgroundColor: tokens.pageBg,
        appBar: AppBar(
          backgroundColor: tokens.pageBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Chat Customer',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: tokens.accentGreen,
            ),
          ),
        ),
        body: const EmptyState(
          icon: Icons.store_mall_directory_outlined,
          title: 'Toko Belum Terdaftar',
          message:
              'Daftarkan toko Anda terlebih dahulu untuk menerima chat customer.',
        ),
      );
    }

    final allSellerChats = chatProvider.sellerChats(store.id);
    final filtered = _searchQuery.isEmpty
        ? allSellerChats
        : allSellerChats.where((c) {
            final name = (c.buyerName ?? '').toLowerCase();
            final msg = (c.lastMessageBody ?? '').toLowerCase();
            final prod = (c.productName ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return name.contains(q) || msg.contains(q) || prod.contains(q);
          }).toList();

    final totalUnread = chatProvider.sellerUnreadCount(store.id);

    return Scaffold(
      backgroundColor: tokens.pageBg,
      appBar: AppBar(
        backgroundColor: tokens.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Flexible(
              child: Text(
                'Chat Customer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: tokens.accentGreen,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (totalUnread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalUnread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: tokens.borderColor),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13.5, color: tokens.titleColor),
              decoration: InputDecoration(
                hintText: 'Cari nama customer atau pesan...',
                hintStyle: TextStyle(fontSize: 13, color: tokens.mutedTextColor),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: tokens.mutedTextColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: tokens.cardBg,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: tokens.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: tokens.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(color: tokens.accentGreen, width: 1.4),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => chatProvider.loadChats(myStoreId: store.id),
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 36),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 780),
                            child: SellerCardSurface(
                              borderRadius: 22,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: EmptyState(
                                icon: Icons.chat_bubble_outline,
                                iconBuilder: (color, size) =>
                                    LucideMessageCircleIcon(
                                  size: size,
                                  color: tokens.accentGreen,
                                ),
                                title: 'Belum Ada Pesan Customer',
                                message:
                                    'Pesan dari pembeli yang menanyakan produk atau pesanan toko Anda akan tampil di sini.',
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        20 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final chat = filtered[index];
                        final buyerName = chat.buyerName ?? 'Customer';
                        final initial = buyerName.isNotEmpty
                            ? buyerName.substring(0, 1).toUpperCase()
                            : 'C';
                        final hasUnread = chat.unreadCount > 0;

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 780),
                            child: SellerCardSurface(
                              borderRadius: 18,
                              backgroundColor: hasUnread
                                  ? (isDark
                                      ? AppColors.primary.withValues(alpha: 0.16)
                                      : const Color(0xFFF3FAF5))
                                  : tokens.cardBg,
                              onTap: () => _openConversation(chat, store.id),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: tokens.softMintBg,
                                    child: chat.buyerAvatar != null &&
                                            chat.buyerAvatar!.isNotEmpty
                                        ? ClipOval(
                                            child: SizedBox(
                                              width: 48,
                                              height: 48,
                                              child: SmartImage(
                                                source: chat.buyerAvatar,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            initial,
                                            style: TextStyle(
                                              color: tokens.accentGreen,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                buyerName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: tokens.titleColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormatter.formatTime(
                                                chat.lastMessageAt ??
                                                    chat.createdAt,
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: hasUnread
                                                    ? tokens.accentGreen
                                                    : tokens.mutedTextColor,
                                                fontWeight: hasUnread
                                                    ? FontWeight.w700
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (chat.productName != null &&
                                            chat.productName!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Produk: ${chat.productName}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: tokens.emeraldAccent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chat.lastMessageBody ??
                                                    'Mulai percakapan dengan customer...',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: hasUnread
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  color: hasUnread
                                                      ? tokens.titleColor
                                                      : tokens.mutedTextColor,
                                                ),
                                              ),
                                            ),
                                            if (hasUnread) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: tokens.accentGreen,
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  '${chat.unreadCount}',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.black
                                                        : Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
