import 'location.dart';

enum UserRole { customer, rider, admin }

UserRole _roleFromJson(String value) {
  switch (value) {
    case 'RIDER':
      return UserRole.rider;
    case 'ADMIN':
      return UserRole.admin;
    case 'CUSTOMER':
    default:
      return UserRole.customer;
  }
}

class AppUser {
  const AppUser({
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
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
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
          : LocationResponse.fromJson(
              json['shopLocation'] as Map<String, dynamic>,
            ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
}
