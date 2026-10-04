import 'order.dart';

/// Public tracking response, matching `PublicTrackingResponseDto`.
class PublicTracking {
  const PublicTracking({
    required this.trackingNumber,
    required this.status,
    required this.shopName,
    required this.receiverName,
    required this.packages,
    required this.trackingEvents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PublicTracking.fromJson(Map<String, dynamic> json) {
    return PublicTracking(
      trackingNumber: json['trackingNumber'] as String,
      status: orderStatusFromJson(json['status'] as String),
      shopName: json['shopName'] as String,
      receiverName: json['receiverName'] as String,
      packages: (json['packages'] as List)
          .map((e) => OrderPackage.fromJson(e as Map<String, dynamic>))
          .toList(),
      trackingEvents: (json['trackingEvents'] as List)
          .map((e) => OrderTrackingEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String trackingNumber;
  final OrderStatus status;
  final String shopName;
  final String receiverName;
  final List<OrderPackage> packages;
  final List<OrderTrackingEvent> trackingEvents;
  final DateTime createdAt;
  final DateTime updatedAt;
}
