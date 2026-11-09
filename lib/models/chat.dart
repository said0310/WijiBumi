class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String messageType; // 'text', 'image'
  final String? body;
  final String? mediaPath;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.messageType = 'text',
    this.body,
    this.mediaPath,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      body: json['body'] as String?,
      mediaPath: json['media_path'] as String?,
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'] as String) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'message_type': messageType,
      'body': body,
      'media_path': mediaPath,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Chat {
  final String id;
  final String buyerId;
  final String storeId;
  final String? productId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  // Joined/Helper fields
  final String? storeName;
  final String? storeLogo;
  final String? buyerName;
  final String? lastMessageBody;
  final String? productName;
  final String? productImage;

  Chat({
    required this.id,
    required this.buyerId,
    required this.storeId,
    this.productId,
    this.lastMessageAt,
    required this.createdAt,
    this.storeName,
    this.storeLogo,
    this.buyerName,
    this.lastMessageBody,
    this.productName,
    this.productImage,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      storeId: json['store_id'] as String,
      productId: json['product_id'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      storeName: json['stores'] != null ? json['stores']['store_name'] as String? : json['store_name'] as String?,
      storeLogo: json['stores'] != null ? json['stores']['logo_path'] as String? : json['store_logo'] as String?,
      buyerName: json['profiles'] != null ? json['profiles']['full_name'] as String? : json['buyer_name'] as String?,
      lastMessageBody: json['last_message_body'] as String?,
      productName: json['products'] != null ? json['products']['name'] as String? : json['product_name'] as String?,
      productImage: json['product_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'store_id': storeId,
      'product_id': productId,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
