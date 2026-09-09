import 'location.dart';

enum OrderStatus {
  pending,
  confirmed,
  pickedUp,
  inTransit,
  atWarehouse,
  outForDelivery,
  deliveredPendingVerification,
  delivered,
  failedDelivery,
  cancelled,
  returned,
}

OrderStatus orderStatusFromJson(String value) {
  switch (value) {
    case 'CONFIRMED':
      return OrderStatus.confirmed;
    case 'PICKED_UP':
      return OrderStatus.pickedUp;
    case 'IN_TRANSIT':
      return OrderStatus.inTransit;
    case 'AT_WAREHOUSE':
      return OrderStatus.atWarehouse;
    case 'OUT_FOR_DELIVERY':
      return OrderStatus.outForDelivery;
    case 'DELIVERED_PENDING_VERIFICATION':
      return OrderStatus.deliveredPendingVerification;
    case 'DELIVERED':
      return OrderStatus.delivered;
    case 'FAILED_DELIVERY':
      return OrderStatus.failedDelivery;
    case 'CANCELLED':
      return OrderStatus.cancelled;
    case 'RETURNED':
      return OrderStatus.returned;
    case 'PENDING':
    default:
      return OrderStatus.pending;
  }
}

enum OrderPayer { sender, receiver }

OrderPayer orderPayerFromJson(String value) =>
    value == 'RECEIVER' ? OrderPayer.receiver : OrderPayer.sender;

String orderPayerToJson(OrderPayer payer) => switch (payer) {
  OrderPayer.sender => 'SENDER',
  OrderPayer.receiver => 'RECEIVER',
};

enum PaymentMethod { cod, bankTransfer, esewa, khalti, fonepay, connectIps }

PaymentMethod paymentMethodFromJson(String value) => switch (value) {
  'BANK_TRANSFER' => PaymentMethod.bankTransfer,
  'ESEWA' => PaymentMethod.esewa,
  'KHALTI' => PaymentMethod.khalti,
  'FONEPAY' => PaymentMethod.fonepay,
  'CONNECTIPS' => PaymentMethod.connectIps,
  _ => PaymentMethod.cod,
};

String paymentMethodToJson(PaymentMethod method) => switch (method) {
  PaymentMethod.cod => 'COD',
  PaymentMethod.bankTransfer => 'BANK_TRANSFER',
  PaymentMethod.esewa => 'ESEWA',
  PaymentMethod.khalti => 'KHALTI',
  PaymentMethod.fonepay => 'FONEPAY',
  PaymentMethod.connectIps => 'CONNECTIPS',
};

enum PaymentStatus { pending, paid, failed }

PaymentStatus paymentStatusFromJson(String value) => switch (value) {
  'PAID' => PaymentStatus.paid,
  'FAILED' => PaymentStatus.failed,
  _ => PaymentStatus.pending,
};

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );
  }

  final String id;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;
}

class OrderPackage {
  const OrderPackage({
    required this.id,
    required this.name,
    required this.weightKg,
    required this.isDangerous,
    required this.images,
  });

  factory OrderPackage.fromJson(Map<String, dynamic> json) {
    return OrderPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      isDangerous: json['isDangerous'] as bool,
      images: (json['images'] as List)
          .map((e) => MediaAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final double weightKg;
  final bool isDangerous;
  final List<MediaAsset> images;
}

class OrderTrackingEvent {
  const OrderTrackingEvent({
    required this.id,
    required this.status,
    required this.title,
    this.description,
    this.location,
    required this.createdAt,
  });

  factory OrderTrackingEvent.fromJson(Map<String, dynamic> json) {
    return OrderTrackingEvent(
      id: json['id'] as String,
      status: orderStatusFromJson(json['status'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final OrderStatus status;
  final String title;
  final String? description;
  final String? location;
  final DateTime createdAt;
}

class OrderRider {
  const OrderRider({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  factory OrderRider.fromJson(Map<String, dynamic> json) {
    return OrderRider(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
}

class OrderWarehouse {
  const OrderWarehouse({
    required this.id,
    required this.name,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
  });

  factory OrderWarehouse.fromJson(Map<String, dynamic> json) {
    return OrderWarehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      addressLine: json['addressLine'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final String addressLine;
  final double latitude;
  final double longitude;
}

class Order {
  const Order({
    required this.id,
    required this.trackingNumber,
    required this.senderId,
    this.senderName,
    required this.senderPhoneNumber,
    this.senderEmail,
    this.senderShopName,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhoneNumber,
    this.receiverEmail,
    this.pickupRider,
    this.pickupRiderAssignedAt,
    this.pickupRiderClaimRequestedAt,
    this.warehouse,
    this.warehouseArrivedAt,
    this.deliveryRider,
    this.deliveryRiderAssignedAt,
    this.deliveryRiderClaimRequestedAt,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.distanceKm,
    required this.totalWeightKg,
    required this.hasDangerousGoods,
    required this.amount,
    required this.currency,
    required this.payer,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paidAt,
    this.codAmount,
    this.codCollectedAt,
    required this.status,
    required this.packages,
    required this.trackingEvents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      trackingNumber: json['trackingNumber'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      senderPhoneNumber: json['senderPhoneNumber'] as String,
      senderEmail: json['senderEmail'] as String?,
      senderShopName: json['senderShopName'] as String?,
      receiverId: json['receiverId'] as String,
      receiverName: json['receiverName'] as String,
      receiverPhoneNumber: json['receiverPhoneNumber'] as String,
      receiverEmail: json['receiverEmail'] as String?,
      pickupRider: json['pickupRider'] == null
          ? null
          : OrderRider.fromJson(json['pickupRider'] as Map<String, dynamic>),
      pickupRiderAssignedAt: json['pickupRiderAssignedAt'] == null
          ? null
          : DateTime.parse(json['pickupRiderAssignedAt'] as String),
      pickupRiderClaimRequestedAt: json['pickupRiderClaimRequestedAt'] == null
          ? null
          : DateTime.parse(json['pickupRiderClaimRequestedAt'] as String),
      warehouse: json['warehouse'] == null
          ? null
          : OrderWarehouse.fromJson(json['warehouse'] as Map<String, dynamic>),
      warehouseArrivedAt: json['warehouseArrivedAt'] == null
          ? null
          : DateTime.parse(json['warehouseArrivedAt'] as String),
      deliveryRider: json['deliveryRider'] == null
          ? null
          : OrderRider.fromJson(json['deliveryRider'] as Map<String, dynamic>),
      deliveryRiderAssignedAt: json['deliveryRiderAssignedAt'] == null
          ? null
          : DateTime.parse(json['deliveryRiderAssignedAt'] as String),
      deliveryRiderClaimRequestedAt:
          json['deliveryRiderClaimRequestedAt'] == null
          ? null
          : DateTime.parse(json['deliveryRiderClaimRequestedAt'] as String),
      pickupLocation: LocationResponse.fromJson(
        json['pickupLocation'] as Map<String, dynamic>,
      ),
      deliveryLocation: LocationResponse.fromJson(
        json['deliveryLocation'] as Map<String, dynamic>,
      ),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      totalWeightKg: (json['totalWeightKg'] as num).toDouble(),
      hasDangerousGoods: json['hasDangerousGoods'] as bool,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      payer: orderPayerFromJson(json['payer'] as String),
      paymentMethod: paymentMethodFromJson(json['paymentMethod'] as String),
      paymentStatus: paymentStatusFromJson(json['paymentStatus'] as String),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      codAmount: json['codAmount'] as String?,
      codCollectedAt: json['codCollectedAt'] == null
          ? null
          : DateTime.parse(json['codCollectedAt'] as String),
      status: orderStatusFromJson(json['status'] as String),
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

  final String id;
  final String trackingNumber;
  final String senderId;
  final String? senderName;
  final String senderPhoneNumber;
  final String? senderEmail;
  final String? senderShopName;
  final String receiverId;
  final String receiverName;
  final String receiverPhoneNumber;
  final String? receiverEmail;
  final OrderRider? pickupRider;
  final DateTime? pickupRiderAssignedAt;
  final DateTime? pickupRiderClaimRequestedAt;
  final OrderWarehouse? warehouse;
  final DateTime? warehouseArrivedAt;
  final OrderRider? deliveryRider;
  final DateTime? deliveryRiderAssignedAt;
  final DateTime? deliveryRiderClaimRequestedAt;
  final LocationResponse pickupLocation;
  final LocationResponse deliveryLocation;
  final double distanceKm;
  final double totalWeightKg;
  final bool hasDangerousGoods;
  final String amount;
  final String currency;
  final OrderPayer payer;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime? paidAt;
  final String? codAmount;
  final DateTime? codCollectedAt;
  final OrderStatus status;
  final List<OrderPackage> packages;
  final List<OrderTrackingEvent> trackingEvents;
  final DateTime createdAt;
  final DateTime updatedAt;
}
