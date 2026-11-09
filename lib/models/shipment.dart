class ShipmentTracking {
  final String id;
  final String shipmentId;
  final String status;
  final String? description;
  final String? location;
  final DateTime eventAt;
  final DateTime createdAt;

  ShipmentTracking({
    required this.id,
    required this.shipmentId,
    required this.status,
    this.description,
    this.location,
    required this.eventAt,
    required this.createdAt,
  });

  factory ShipmentTracking.fromJson(Map<String, dynamic> json) {
    return ShipmentTracking(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      status: json['status'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      eventAt: json['event_at'] != null
          ? DateTime.parse(json['event_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'status': status,
      'description': description,
      'location': location,
      'event_at': eventAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Shipment {
  final String id;
  final String orderId;
  final String? courierName;
  final String? serviceName;
  final String? trackingNumber;
  final String status; // 'waiting','picked_up','in_transit','delivered','returned','failed'
  final DateTime? estimatedArrival;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShipmentTracking> trackingHistory;

  Shipment({
    required this.id,
    required this.orderId,
    this.courierName,
    this.serviceName,
    this.trackingNumber,
    this.status = 'waiting',
    this.estimatedArrival,
    this.shippedAt,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    this.trackingHistory = const [],
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    List<ShipmentTracking> trackList = [];
    if (json['shipment_tracking'] != null && json['shipment_tracking'] is List) {
      trackList = (json['shipment_tracking'] as List)
          .map((t) => ShipmentTracking.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return Shipment(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      courierName: json['courier_name'] as String?,
      serviceName: json['service_name'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      status: json['status'] as String? ?? 'waiting',
      estimatedArrival: json['estimated_arrival'] != null
          ? DateTime.tryParse(json['estimated_arrival'] as String)
          : null,
      shippedAt: json['shipped_at'] != null
          ? DateTime.tryParse(json['shipped_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      trackingHistory: trackList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'courier_name': courierName,
      'service_name': serviceName,
      'tracking_number': trackingNumber,
      'status': status,
      'estimated_arrival': estimatedArrival?.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Shipment copyWith({
    String? status,
    String? trackingNumber,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    List<ShipmentTracking>? trackingHistory,
  }) {
    return Shipment(
      id: id,
      orderId: orderId,
      courierName: courierName,
      serviceName: serviceName,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      status: status ?? this.status,
      estimatedArrival: estimatedArrival,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      trackingHistory: trackingHistory ?? this.trackingHistory,
    );
  }
}
