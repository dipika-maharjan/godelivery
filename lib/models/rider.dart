enum VehicleType { onFoot, bicycle, motorbike, car, van, truck }

VehicleType vehicleTypeFromJson(String value) => switch (value) {
  'ON_FOOT' => VehicleType.onFoot,
  'BICYCLE' => VehicleType.bicycle,
  'CAR' => VehicleType.car,
  'VAN' => VehicleType.van,
  'TRUCK' => VehicleType.truck,
  _ => VehicleType.motorbike,
};

String vehicleTypeToJson(VehicleType type) => switch (type) {
  VehicleType.onFoot => 'ON_FOOT',
  VehicleType.bicycle => 'BICYCLE',
  VehicleType.motorbike => 'MOTORBIKE',
  VehicleType.car => 'CAR',
  VehicleType.van => 'VAN',
  VehicleType.truck => 'TRUCK',
};

String vehicleTypeLabel(VehicleType type) => switch (type) {
  VehicleType.onFoot => 'On foot',
  VehicleType.bicycle => 'Bicycle',
  VehicleType.motorbike => 'Motorbike',
  VehicleType.car => 'Car',
  VehicleType.van => 'Van',
  VehicleType.truck => 'Truck',
};

class RiderCurrentLocation {
  const RiderCurrentLocation({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  factory RiderCurrentLocation.fromJson(Map<String, dynamic> json) {
    return RiderCurrentLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final double latitude;
  final double longitude;
  final DateTime updatedAt;
}

/// A delivery partner account, matching `RiderResponseDto`.
class Rider {
  const Rider({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.vehicleType,
    this.vehiclePlateNumber,
    required this.isAvailable,
    required this.isActive,
    this.currentLocation,
    required this.createdAt,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      vehicleType: vehicleTypeFromJson(json['vehicleType'] as String),
      vehiclePlateNumber: json['vehiclePlateNumber'] as String?,
      isAvailable: json['isAvailable'] as bool,
      isActive: json['isActive'] as bool,
      currentLocation: json['currentLocation'] == null
          ? null
          : RiderCurrentLocation.fromJson(
              json['currentLocation'] as Map<String, dynamic>,
            ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
  final VehicleType vehicleType;
  final String? vehiclePlateNumber;
  final bool isAvailable;
  final bool isActive;
  final RiderCurrentLocation? currentLocation;
  final DateTime createdAt;
}

class RiderCurrentOrder {
  const RiderCurrentOrder({
    required this.id,
    required this.trackingNumber,
    required this.status,
  });

  factory RiderCurrentOrder.fromJson(Map<String, dynamic> json) {
    return RiderCurrentOrder(
      id: json['id'] as String,
      trackingNumber: json['trackingNumber'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final String trackingNumber;
  final String status;
}

class RiderMetrics {
  const RiderMetrics({
    required this.totalDeliveries,
    this.averageDeliveryDurationMinutes,
    this.currentOrder,
  });

  factory RiderMetrics.fromJson(Map<String, dynamic> json) {
    return RiderMetrics(
      totalDeliveries: (json['totalDeliveries'] as num).toInt(),
      averageDeliveryDurationMinutes:
          (json['averageDeliveryDurationMinutes'] as num?)?.toDouble(),
      currentOrder: json['currentOrder'] == null
          ? null
          : RiderCurrentOrder.fromJson(
              json['currentOrder'] as Map<String, dynamic>,
            ),
    );
  }

  final int totalDeliveries;
  final double? averageDeliveryDurationMinutes;
  final RiderCurrentOrder? currentOrder;
}

class BankAccount {
  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.branch,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      bankName: json['bankName'] as String,
      accountName: json['accountName'] as String,
      accountNumber: json['accountNumber'] as String,
      branch: json['branch'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String? branch;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class UnpaidOrder {
  const UnpaidOrder({
    required this.id,
    required this.trackingNumber,
    required this.amount,
    required this.currency,
    required this.deliveredAt,
  });

  factory UnpaidOrder.fromJson(Map<String, dynamic> json) {
    return UnpaidOrder(
      id: json['id'] as String,
      trackingNumber: json['trackingNumber'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      deliveredAt: DateTime.parse(json['deliveredAt'] as String),
    );
  }

  final String id;
  final String trackingNumber;
  final String amount;
  final String currency;
  final DateTime deliveredAt;
}

class RiderUnpaidDeliveries {
  const RiderUnpaidDeliveries({
    required this.orders,
    required this.totalAmountOwed,
    required this.currency,
  });

  factory RiderUnpaidDeliveries.fromJson(Map<String, dynamic> json) {
    return RiderUnpaidDeliveries(
      orders: (json['orders'] as List)
          .map((e) => UnpaidOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmountOwed: json['totalAmountOwed'] as String,
      currency: json['currency'] as String,
    );
  }

  final List<UnpaidOrder> orders;
  final String totalAmountOwed;
  final String currency;
}
