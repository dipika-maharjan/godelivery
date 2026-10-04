class User {
  final String id;
  final String phone;
  final String fullName;
  final String businessName;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.phone,
    required this.fullName,
    required this.businessName,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? phone,
    String? fullName,
    String? businessName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
