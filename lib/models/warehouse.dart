import 'location.dart';

/// A sorting/routing hub, matching `WarehouseResponseDto`.
class Warehouse {
  const Warehouse({
    required this.id,
    required this.name,
    required this.location,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LocationResponse.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String name;
  final LocationResponse location;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
