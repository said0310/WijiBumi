import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/supabase_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/lucide_icons.dart';
import '../../widgets/smart_image.dart';

class ChatRoomScreen extends StatefulWidget {
  final String? chatId;
  final String storeId;
  final String? productId;
  final String title;
  final bool isSellerMode;

  const ChatRoomScreen({
    super.key,
    this.chatId,
    required this.storeId,
    this.productId,
    required this.title,
    this.isSellerMode = false,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatProvider? _chatProvider;
  bool _isInit = true;
  bool _isSending = false;
  String? _resolvedChatId;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<ChatProvider>();
    if (_isInit) {
      _isInit = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initializeRoom();
      });
    }
  }

  Future<void> _initializeRoom() async {
    final chatProvider = _chatProvider;
    if (chatProvider == null) return;
    final myStoreId = widget.isSellerMode
        ? widget.storeId
        : context.read<StoreProvider>().myStore?.id;
    if (widget.chatId != null) {
      _resolvedChatId = widget.chatId;
      await chatProvider.openChatById(widget.chatId!, myStoreId: myStoreId);
    } else {
      final chat = await chatProvider.openChatRoom(
        storeId: widget.storeId,
        productId: widget.productId,
        myStoreId: myStoreId,
      );
      _resolvedChatId = chat?.id;
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _chatProvider?.leaveChatRoom(_resolvedChatId);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isSending) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedImageBytes = bytes;
          _pickedImageName = picked.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _showAttachmentOptions() {
    if (_isSending) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih Gambar dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil Foto dengan Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _msgController.text.trim();
    final imageBytes = _pickedImageBytes;
    if (text.isEmpty && imageBytes == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final chatProvider = context.read<ChatProvider>();
    final myStoreId = widget.isSellerMode
        ? widget.storeId
        : context.read<StoreProvider>().myStore?.id;

    setState(() => _isSending = true);
    String? mediaPath;
    try {
      if (imageBytes != null) {
        mediaPath = await SupabaseService.instance.uploadImageBytes(
          bytes: imageBytes,
          bucket: 'chat-media',
          fileName: _pickedImageName ?? 'chat_image.jpg',
        );
        if (!mounted) return;
        if (mediaPath == null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Gagal mengunggah gambar. Periksa koneksi Anda.'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isSending = false);
          return;
        }
      }

      final ok = await chatProvider.sendMessage(
        text,
        mediaPath: mediaPath,
        myStoreId: myStoreId,
      );
      if (!mounted) return;

      if (ok) {
        _msgController.clear();
        setState(() {
          _pickedImageBytes = null;
          _pickedImageName = null;
        });
        _scrollToBottom();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              chatProvider.lastError ??
                  'Gagal mengirim pesan. Periksa koneksi Anda.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _openImagePreview(String source) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: SmartImage(
                source: source,
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
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
    final chatProvider = context.watch<ChatProvider>();
    final currentUser = context.watch<AuthProvider>().user;
    final currentUserId = currentUser?.id;

    final messages = chatProvider.currentMessages;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryContainer,
              child: Icon(
                widget.isSellerMode ? Icons.person : Icons.storefront,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isSellerMode
                        ? 'Pembeli • WijiBumi Chat'
                        : 'Penjual Mitra WijiBumi',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chatProvider.lastError != null && messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 42,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                chatProvider.lastError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _initializeRoom,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LucideMessageCircleIcon(
                                    size: 48,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Kirim pesan untuk menanyakan ketersediaan stok, pengiriman, atau kualitas panen.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg.senderId == currentUserId;
                              final senderLabel = isMe
                                  ? (currentUser?.fullName ?? 'Anda')
                                  : widget.title;
                              final hasImage = msg.mediaPath != null &&
                                  msg.mediaPath!.trim().isNotEmpty;
                              final hasText = msg.body != null &&
                                  msg.body!.trim().isNotEmpty;

                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.76,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? (isDark
                                            ? AppColors.primaryDark
                                            : AppColors.primary)
                                        : (isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(14),
                                      topRight: const Radius.circular(14),
                                      bottomLeft: Radius.circular(isMe ? 14 : 2),
                                      bottomRight:
                                          Radius.circular(isMe ? 2 : 14),
                                    ),
                                    border: Border.all(
                                      color: isMe
                                          ? Colors.transparent
                                          : (isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        senderLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isMe
                                              ? Colors.white70
                                              : AppColors.secondaryEmerald,
                                        ),
                                      ),
                                      if (hasImage) ...[
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () =>
                                              _openImagePreview(msg.mediaPath!),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 220,
                                                maxHeight: 220,
                                              ),
                                              child: SmartImage(
                                                source: msg.mediaPath,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (hasText) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          msg.body!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isMe
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimaryLight),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormatter.formatTime(msg.createdAt),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white70
                                              : (isDark
                                                  ? AppColors.textMutedDark
                                                  : AppColors.textMutedLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          if (_pickedImageBytes != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _pickedImageBytes!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Lampiran gambar siap dikirim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Hapus gambar',
                    onPressed: _isSending
                        ? null
                        : () => setState(() {
                              _pickedImageBytes = null;
                              _pickedImageName = null;
                            }),
                  ),
                ],
              ),
            ),

          // Message Input Field
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.image_outlined,
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    tooltip: 'Lampirkan Gambar',
                    onPressed: _isSending ? null : _showAttachmentOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan Anda...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        fillColor:
                            isDark ? AppColors.surfaceDark : Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primaryLight : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: isDark ? Colors.black : Colors.white,
                              size: 20,
                            ),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
