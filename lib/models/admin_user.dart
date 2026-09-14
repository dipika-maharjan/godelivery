import 'location.dart';
import 'rider.dart';
import 'user.dart';

class AdminRiderProfileSummary {
  const AdminRiderProfileSummary({
    required this.isActive,
    required this.isAvailable,
    required this.vehicleType,
    this.vehiclePlateNumber,
  });

  factory AdminRiderProfileSummary.fromJson(Map<String, dynamic> json) {
    return AdminRiderProfileSummary(
      isActive: json['isActive'] as bool,
      isAvailable: json['isAvailable'] as bool,
      vehicleType: vehicleTypeFromJson(json['vehicleType'] as String),
      vehiclePlateNumber: json['vehiclePlateNumber'] as String?,
    );
  }

  final bool isActive;
  final bool isAvailable;
  final VehicleType vehicleType;
  final String? vehiclePlateNumber;
}

class AdminUserOrderSummary {
  const AdminUserOrderSummary({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  factory AdminUserOrderSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserOrderSummary(
      id: json['id'] as String,
      trackingNumber: json['trackingNumber'] as String,
      status: json['status'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String trackingNumber;
  final String status;
  final String amount;
  final String currency;
  final DateTime createdAt;
}

/// Any account on the platform, as seen by an admin — matches
/// `AdminUserResponseDto`.
class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.phoneNumber,
    this.phoneVerifiedAt,
    required this.name,
    this.email,
    required this.role,
    this.shopName,
    this.shopLocation,
    required this.createdAt,
    required this.updatedAt,
    required this.sentOrdersCount,
    required this.receivedOrdersCount,
    required this.riderOrdersCount,
    this.riderProfile,
  });

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      phoneVerifiedAt: json['phoneVerifiedAt'] == null
          ? null
          : DateTime.parse(json['phoneVerifiedAt'] as String),
      name: json['name'] as String,
      email: json['email'] as String?,
      role: _roleFromJson(json['role'] as String),
      shopName: json['shopName'] as String?,
      shopLocation: json['shopLocation'] == null
          ? null
          : LocationResponse.fromJson(json['shopLocation'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sentOrdersCount: (json['sentOrdersCount'] as num).toInt(),
      receivedOrdersCount: (json['receivedOrdersCount'] as num).toInt(),
      riderOrdersCount: (json['riderOrdersCount'] as num).toInt(),
      riderProfile: json['riderProfile'] == null
          ? null
          : AdminRiderProfileSummary.fromJson(
              json['riderProfile'] as Map<String, dynamic>,
            ),
    );
  }

  final String id;
  final String phoneNumber;
  final DateTime? phoneVerifiedAt;
  final String name;
  final String? email;
  final UserRole role;
  final String? shopName;
  final LocationResponse? shopLocation;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sentOrdersCount;
  final int receivedOrdersCount;
  final int riderOrdersCount;
  final AdminRiderProfileSummary? riderProfile;
}

/// Full detail for one account — matches `AdminUserDetailResponseDto`.
class AdminUserDetail extends AdminUserSummary {
  const AdminUserDetail({
    required super.id,
    required super.phoneNumber,
    super.phoneVerifiedAt,
    required super.name,
    super.email,
    required super.role,
    super.shopName,
    super.shopLocation,
    required super.createdAt,
    required super.updatedAt,
    required super.sentOrdersCount,
    required super.receivedOrdersCount,
    required super.riderOrdersCount,
    super.riderProfile,
    required this.recentSentOrders,
    required this.recentReceivedOrders,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final summary = AdminUserSummary.fromJson(json);
    return AdminUserDetail(
      id: summary.id,
      phoneNumber: summary.phoneNumber,
      phoneVerifiedAt: summary.phoneVerifiedAt,
      name: summary.name,
      email: summary.email,
      role: summary.role,
      shopName: summary.shopName,
      shopLocation: summary.shopLocation,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      sentOrdersCount: summary.sentOrdersCount,
      receivedOrdersCount: summary.receivedOrdersCount,
      riderOrdersCount: summary.riderOrdersCount,
      riderProfile: summary.riderProfile,
      recentSentOrders: (json['recentSentOrders'] as List)
          .map((e) => AdminUserOrderSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentReceivedOrders: (json['recentReceivedOrders'] as List)
          .map((e) => AdminUserOrderSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<AdminUserOrderSummary> recentSentOrders;
  final List<AdminUserOrderSummary> recentReceivedOrders;
}

UserRole _roleFromJson(String value) => switch (value) {
  'RIDER' => UserRole.rider,
  'ADMIN' => UserRole.admin,
  _ => UserRole.customer,
};
