class SupportTicket {
  final String id;
  final String userId;
  final String category;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.category,
    required this.subject,
    required this.message,
    this.status = 'open',
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String? ?? 'Umum',
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

