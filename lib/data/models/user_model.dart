import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.phone,
    required super.fullName,
    required super.businessName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      businessName: json['businessName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'fullName': fullName,
      'businessName': businessName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      phone: user.phone,
      fullName: user.fullName,
      businessName: user.businessName,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  User toEntity() {
    return User(
      id: id,
      phone: phone,
      fullName: fullName,
      businessName: businessName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
