class Review {
  final String id;
  final String orderId;
  final String reviewerId;
  final String storeId;
  final String? productId;
  final int rating;
  final String? reviewText;
  final String? replyText;
  final DateTime? repliedAt;
  final DateTime createdAt;

  // Joined helpers
  final String? reviewerName;
  final String? reviewerAvatar;
  final String? productName;

  Review({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.storeId,
    this.productId,
    required this.rating,
    this.reviewText,
    this.replyText,
    this.repliedAt,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatar,
    this.productName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      storeId: json['store_id'] as String,
      productId: json['product_id'] as String?,
      rating: (json['rating'] as num).toInt(),
      reviewText: json['review_text'] as String?,
      replyText: json['reply_text'] as String?,
      repliedAt: json['replied_at'] != null
          ? DateTime.tryParse(json['replied_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      reviewerName: json['profiles'] != null ? json['profiles']['full_name'] as String? : json['reviewer_name'] as String?,
      reviewerAvatar: json['profiles'] != null ? json['profiles']['avatar_path'] as String? : json['reviewer_avatar'] as String?,
      productName: json['products'] != null ? json['products']['name'] as String? : json['product_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'reviewer_id': reviewerId,
      'store_id': storeId,
      'product_id': productId,
      'rating': rating,
      'review_text': reviewText,
      'reply_text': replyText,
      'replied_at': repliedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? replyText,
    DateTime? repliedAt,
  }) {
    return Review(
      id: id,
      orderId: orderId,
      reviewerId: reviewerId,
      storeId: storeId,
      productId: productId,
      rating: rating,
      reviewText: reviewText,
      replyText: replyText ?? this.replyText,
      repliedAt: repliedAt ?? this.repliedAt,
      createdAt: createdAt,
      reviewerName: reviewerName,
      reviewerAvatar: reviewerAvatar,
      productName: productName,
    );
  }
}
