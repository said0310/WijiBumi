import 'shipment.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final String productNameSnapshot;
  final String unitSnapshot;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String? qualityGradeSnapshot;
  final String? imageSnapshot;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productNameSnapshot,
    required this.unitSnapshot,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.qualityGradeSnapshot,
    this.imageSnapshot,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String?,
      productNameSnapshot: json['product_name_snapshot'] as String? ?? '',
      unitSnapshot: json['unit_snapshot'] as String? ?? 'kg',
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      lineTotal: (json['line_total'] as num).toDouble(),
      qualityGradeSnapshot: json['quality_grade_snapshot'] as String?,
      imageSnapshot: json['image_snapshot'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name_snapshot': productNameSnapshot,
      'unit_snapshot': unitSnapshot,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
      'quality_grade_snapshot': qualityGradeSnapshot,
      'image_snapshot': imageSnapshot,
    };
  }
}

class Payment {
  final String id;
  final String orderId;
  final String paymentMethod;
  final String? provider;
  final String? providerReference;
  final double amount;
  final String status; // 'pending', 'paid', 'failed', 'expired', 'refunded'
  final String? paymentUrl;
  final DateTime? paidAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    this.provider,
    this.providerReference,
    required this.amount,
    this.status = 'pending',
    this.paymentUrl,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      paymentMethod: json['payment_method'] as String? ?? 'Transfer Bank',
      provider: json['provider'] as String?,
      providerReference: json['provider_reference'] as String?,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      paymentUrl: json['payment_url'] as String?,
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'payment_method': paymentMethod,
      'provider': provider,
      'provider_reference': providerReference,
      'amount': amount,
      'status': status,
      'payment_url': paymentUrl,
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}

class Order {
  final String id;
  final String orderCode;
  final String buyerId;
  final String storeId;
  final String? addressId;
  final Map<String, dynamic> shippingAddressSnapshot;
  final String status; // pending_payment, awaiting_confirmation, processing, ready_to_ship, shipped, completed, cancelled
  final String paymentStatus; // unpaid, pending, paid, failed, refunded
  final double subtotal;
  final double shippingFee;
  final double discountTotal;
  final double totalAmount;
  final String? buyerNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined / Helper fields
  final String? storeName;
  final String? buyerName;
  final List<OrderItem> items;
  final Shipment? shipment;
  final Payment? payment;

  Order({
    required this.id,
    required this.orderCode,
    required this.buyerId,
    required this.storeId,
    this.addressId,
    required this.shippingAddressSnapshot,
    this.status = 'pending_payment',
    this.paymentStatus = 'unpaid',
    required this.subtotal,
    required this.shippingFee,
    this.discountTotal = 0.0,
    required this.totalAmount,
    this.buyerNote,
    required this.createdAt,
    required this.updatedAt,
    this.storeName,
    this.buyerName,
    this.items = const [],
    this.shipment,
    this.payment,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> itemsList = [];
    if (json['order_items'] != null && json['order_items'] is List) {
      itemsList = (json['order_items'] as List)
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    Shipment? s;
    if (json['shipments'] != null && json['shipments'] is Map) {
      s = Shipment.fromJson(json['shipments'] as Map<String, dynamic>);
    }

    Payment? p;
    if (json['payments'] != null && json['payments'] is List && (json['payments'] as List).isNotEmpty) {
      p = Payment.fromJson((json['payments'] as List).first as Map<String, dynamic>);
    } else if (json['payments'] != null && json['payments'] is Map) {
      p = Payment.fromJson(json['payments'] as Map<String, dynamic>);
    }

    String? sName;
    if (json['stores'] != null && json['stores'] is Map) {
      sName = json['stores']['store_name'] as String?;
    } else {
      sName = json['store_name'] as String?;
    }

    return Order(
      id: json['id'] as String,
      orderCode: json['order_code'] as String,
      buyerId: json['buyer_id'] as String,
      storeId: json['store_id'] as String,
      addressId: json['address_id'] as String?,
      shippingAddressSnapshot: json['shipping_address_snapshot'] is Map
          ? Map<String, dynamic>.from(json['shipping_address_snapshot'] as Map)
          : {},
      status: json['status'] as String? ?? 'pending_payment',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingFee: (json['shipping_fee'] as num).toDouble(),
      discountTotal: (json['discount_total'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      buyerNote: json['buyer_note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      storeName: sName,
      buyerName: json['buyer_name'] as String?,
      items: itemsList,
      shipment: s,
      payment: p,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'buyer_id': buyerId,
      'store_id': storeId,
      'address_id': addressId,
      'shipping_address_snapshot': shippingAddressSnapshot,
      'status': status,
      'payment_status': paymentStatus,
      'subtotal': subtotal,
      'shipping_fee': shippingFee,
      'discount_total': discountTotal,
      'total_amount': totalAmount,
      'buyer_note': buyerNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Order copyWith({
    String? status,
    String? paymentStatus,
    Shipment? shipment,
    Payment? payment,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      orderCode: orderCode,
      buyerId: buyerId,
      storeId: storeId,
      addressId: addressId,
      shippingAddressSnapshot: shippingAddressSnapshot,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal,
      shippingFee: shippingFee,
      discountTotal: discountTotal,
      totalAmount: totalAmount,
      buyerNote: buyerNote,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      storeName: storeName,
      buyerName: buyerName,
      items: items ?? this.items,
      shipment: shipment ?? this.shipment,
      payment: payment ?? this.payment,
    );
  }
}
