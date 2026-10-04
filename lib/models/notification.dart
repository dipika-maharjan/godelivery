enum NotificationType {
  orderCreated,
  orderStatusChanged,
  orderAssigned,
  orderUnassigned,
  orderCancelled,
  newOrderAvailable,
  generic,
}

NotificationType _typeFromJson(String value) {
  switch (value) {
    case 'ORDER_CREATED':
      return NotificationType.orderCreated;
    case 'ORDER_STATUS_CHANGED':
      return NotificationType.orderStatusChanged;
    case 'ORDER_ASSIGNED':
      return NotificationType.orderAssigned;
    case 'ORDER_UNASSIGNED':
      return NotificationType.orderUnassigned;
    case 'ORDER_CANCELLED':
      return NotificationType.orderCancelled;
    case 'NEW_ORDER_AVAILABLE':
      return NotificationType.newOrderAvailable;
    case 'GENERIC':
    default:
      return NotificationType.generic;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.orderId,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: _typeFromJson(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      orderId: json['orderId'] as String?,
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? orderId;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;
}
