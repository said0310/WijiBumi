class PayoutAccount {
  final String id;
  final String storeId;
  final String method; // 'bank_transfer', 'e_wallet'
  final String providerName; // BCA, Mandiri, GoPay, OVO, etc.
  final String accountHolder;
  final String accountNumberLast4;
  final bool isDefault;
  final DateTime createdAt;

  PayoutAccount({
    required this.id,
    required this.storeId,
    required this.method,
    required this.providerName,
    required this.accountHolder,
    required this.accountNumberLast4,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PayoutAccount.fromJson(Map<String, dynamic> json) {
    return PayoutAccount(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      method: json['method'] as String? ?? 'bank_transfer',
      providerName: json['provider_name'] as String? ?? '',
      accountHolder: json['account_holder'] as String? ?? '',
      accountNumberLast4: json['account_number_last4'] as String? ?? '****',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'method': method,
      'provider_name': providerName,
      'account_holder': accountHolder,
      'account_number_last4': accountNumberLast4,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PayoutRequest {
  final String id;
  final String storeId;
  final String payoutAccountId;
  final double amount;
  final String status; // 'requested', 'processing', 'paid', 'rejected'
  final String? referenceNumber;
  final String? note;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final PayoutAccount? account;

  PayoutRequest({
    required this.id,
    required this.storeId,
    required this.payoutAccountId,
    required this.amount,
    this.status = 'requested',
    this.referenceNumber,
    this.note,
    required this.requestedAt,
    this.processedAt,
    this.account,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    return PayoutRequest(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      payoutAccountId: json['payout_account_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'requested',
      referenceNumber: json['reference_number'] as String?,
      note: json['note'] as String?,
      requestedAt: json['requested_at'] != null ? DateTime.parse(json['requested_at'] as String) : DateTime.now(),
      processedAt: json['processed_at'] != null ? DateTime.tryParse(json['processed_at'] as String) : null,
      account: json['payout_accounts'] != null ? PayoutAccount.fromJson(json['payout_accounts'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'payout_account_id': payoutAccountId,
      'amount': amount,
      'status': status,
      'reference_number': referenceNumber,
      'note': note,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }
}
