import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/chat.dart';
import '../services/supabase_service.dart';

class ChatProvider with ChangeNotifier {
  List<Chat> _chats = [];
  List<ChatMessage> _currentMessages = [];
  String? _activeChatId;
  bool _isLoading = false;
  String? _lastError;
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _sellerChatsChannel;
  RealtimeChannel? _buyerChatsChannel;

  List<Chat> get chats => _chats;
  List<ChatMessage> get currentMessages => _currentMessages;
  String? get activeChatId => _activeChatId;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  List<Chat> _sortedByLatest(Iterable<Chat> items) {
    final list = items.toList();
    list.sort((a, b) {
      final tA = a.lastMessageAt ?? a.createdAt;
      final tB = b.lastMessageAt ?? b.createdAt;
      return tB.compareTo(tA);
    });
    return list;
  }

  List<Chat> sellerChats(String storeId) {
    return _sortedByLatest(_chats.where((c) => c.storeId == storeId));
  }

  int sellerUnreadCount(String storeId) {
    return sellerChats(storeId).fold(0, (sum, c) => sum + c.unreadCount);
  }

  List<Chat> buyerChats({String? myUserId, String? myStoreId}) {
    if (myUserId != null && myUserId.isNotEmpty) {
      return _sortedByLatest(
        _chats.where(
          (c) => c.buyerId == myUserId && (myStoreId == null || c.storeId != myStoreId),
        ),
      );
    }
    return _sortedByLatest(
      _chats.where((c) => myStoreId == null || c.storeId != myStoreId),
    );
  }

  int buyerUnreadCount(String? myStoreId, {String? myUserId}) {
    return buyerChats(myUserId: myUserId, myStoreId: myStoreId)
        .fold(0, (sum, c) => sum + c.unreadCount);
  }

  ChatProvider() {
    loadChats();
  }

  Future<void> loadChats({String? myStoreId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _chats = await SupabaseService.instance.getChats(myStoreId: myStoreId);
    } catch (e) {
      debugPrint('Error loading chats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  RealtimeChannel? _subscribeChatListChannel({
    required String channelName,
    required String filterColumn,
    required String filterValue,
    String? myStoreId,
  }) {
    if (!SupabaseService.instance.isConnected) return null;
    final client = SupabaseConfig.client;
    if (client == null) return null;

    return client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filterColumn,
            value: filterValue,
          ),
          callback: (_) {
            loadChats(myStoreId: myStoreId);
          },
        )
        .subscribe();
  }

  void subscribeSellerChats(String storeId) {
    _unsubscribeChannel(_sellerChatsChannel);
    _sellerChatsChannel = _subscribeChatListChannel(
      channelName: 'public:chats:store:$storeId',
      filterColumn: 'store_id',
      filterValue: storeId,
      myStoreId: storeId,
    );
  }

  void subscribeBuyerChats(String userId, {String? myStoreId}) {
    _unsubscribeChannel(_buyerChatsChannel);
    _buyerChatsChannel = _subscribeChatListChannel(
      channelName: 'public:chats:buyer:$userId',
      filterColumn: 'buyer_id',
      filterValue: userId,
      myStoreId: myStoreId,
    );
  }

  void _unsubscribeChannel(RealtimeChannel? channel) {
    if (channel != null && SupabaseConfig.client != null) {
      SupabaseConfig.client!.removeChannel(channel);
    }
  }

  Future<Chat?> openChatRoom({
    required String storeId,
    String? productId,
    String? myStoreId,
  }) async {
    _unsubscribeChannel(_messageChannel);
    _messageChannel = null;
    _activeChatId = null;
    _currentMessages = [];
    _lastError = null;
    _isLoading = true;
    notifyListeners();
    try {
      final chat = await SupabaseService.instance.startOrGetChat(
        storeId: storeId,
        productId: productId,
      );
      await openChatById(chat.id, myStoreId: myStoreId);
      await loadChats(myStoreId: myStoreId);
      return chat;
    } catch (e) {
      debugPrint('Error opening chat room: $e');
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      _lastError = raw.isNotEmpty
          ? raw
          : 'Gagal membuka percakapan. Periksa koneksi Anda.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> openChatById(String chatId, {String? myStoreId}) async {
    _lastError = null;
    if (_activeChatId != chatId) {
      _currentMessages = [];
      _isLoading = true;
      notifyListeners();
    }
    _activeChatId = chatId;
    try {
      await loadMessages(chatId);
      await SupabaseService.instance.markChatMessagesAsRead(chatId);
      final idx = _chats.indexWhere((c) => c.id == chatId);
      if (idx != -1 && _chats[idx].unreadCount > 0) {
        _chats[idx] = _chats[idx].copyWith(unreadCount: 0);
      }
      _subscribeToChat(chatId, myStoreId: myStoreId);
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      _lastError = raw.isNotEmpty
          ? raw
          : 'Gagal memuat riwayat pesan. Coba lagi nanti.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void leaveChatRoom([String? chatId]) {
    if (chatId != null && _activeChatId != null && _activeChatId != chatId) {
      return;
    }
    _unsubscribeChannel(_messageChannel);
    _messageChannel = null;
    _activeChatId = null;
  }

  Future<void> loadMessages(String chatId) async {
    _activeChatId = chatId;
    _currentMessages = await SupabaseService.instance.getChatMessages(chatId);
    notifyListeners();
  }

  void _subscribeToChat(String chatId, {String? myStoreId}) {
    if (!SupabaseService.instance.isConnected) return;
    final client = SupabaseConfig.client;
    if (client == null) return;

    _unsubscribeChannel(_messageChannel);
    _messageChannel = client
        .channel('public:chat_messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            try {
              final incoming = ChatMessage.fromJson(payload.newRecord);
              if (!_currentMessages.any((m) => m.id == incoming.id)) {
                _currentMessages.add(incoming);
                notifyListeners();
                if (_activeChatId == chatId) {
                  SupabaseService.instance.markChatMessagesAsRead(chatId);
                }
                loadChats(myStoreId: myStoreId);
              }
            } catch (e) {
              debugPrint('Realtime chat parse error: $e');
            }
          },
        )
        .subscribe();
  }

  Future<bool> sendMessage(
    String text, {
    String? mediaPath,
    String? myStoreId,
  }) async {
    final trimmed = text.trim();
    final hasMedia = mediaPath != null && mediaPath.trim().isNotEmpty;
    if (_activeChatId == null || (trimmed.isEmpty && !hasMedia)) return false;

    _lastError = null;
    try {
      final msg = await SupabaseService.instance.sendChatMessage(
        chatId: _activeChatId!,
        body: trimmed.isNotEmpty ? trimmed : null,
        mediaPath: mediaPath,
      );
      if (!_currentMessages.any((m) => m.id == msg.id)) {
        _currentMessages.add(msg);
      }
      notifyListeners();
      await loadChats(myStoreId: myStoreId);
      return true;
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      _lastError = raw.isNotEmpty
          ? raw
          : 'Gagal mengirim pesan. Periksa koneksi Anda.';
      notifyListeners();
      return false;
    }
  }

  void clearSession() {
    _unsubscribeChannel(_messageChannel);
    _messageChannel = null;
    _unsubscribeChannel(_sellerChatsChannel);
    _sellerChatsChannel = null;
    _unsubscribeChannel(_buyerChatsChannel);
    _buyerChatsChannel = null;
    _chats = [];
    _currentMessages = [];
    _activeChatId = null;
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubscribeChannel(_messageChannel);
    _unsubscribeChannel(_sellerChatsChannel);
    _unsubscribeChannel(_buyerChatsChannel);
    super.dispose();
  }
}
