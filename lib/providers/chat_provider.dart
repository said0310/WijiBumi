import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../services/supabase_service.dart';

class ChatProvider with ChangeNotifier {
  List<Chat> _chats = [];
  List<ChatMessage> _currentMessages = [];
  String? _activeChatId;
  bool _isLoading = false;

  List<Chat> get chats => _chats;
  List<ChatMessage> get currentMessages => _currentMessages;
  String? get activeChatId => _activeChatId;
  bool get isLoading => _isLoading;

  ChatProvider() {
    loadChats();
  }

  Future<void> loadChats() async {
    _isLoading = true;
    notifyListeners();
    try {
      _chats = await SupabaseService.instance.getChats();
    } catch (e) {
      debugPrint('Error loading chats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Chat> openChatRoom({required String storeId, String? productId}) async {
    final chat = await SupabaseService.instance.startOrGetChat(storeId: storeId, productId: productId);
    _activeChatId = chat.id;
    await loadMessages(chat.id);
    await loadChats();
    return chat;
  }

  Future<void> loadMessages(String chatId) async {
    _activeChatId = chatId;
    _currentMessages = await SupabaseService.instance.getChatMessages(chatId);
    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? mediaPath}) async {
    if (_activeChatId == null || text.trim().isEmpty) return;
    final msg = await SupabaseService.instance.sendChatMessage(
      chatId: _activeChatId!,
      body: text.trim(),
      mediaPath: mediaPath,
    );
    _currentMessages.add(msg);
    notifyListeners();
  }
}
