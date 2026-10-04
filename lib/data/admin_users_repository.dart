import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/admin_user.dart';
import '../models/location.dart';
import '../models/pagination.dart';
import '../models/user.dart';

final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  return AdminUsersRepository(ref.watch(dioProvider));
});

/// Platform-wide account management (admin): `/users*`.
class AdminUsersRepository {
  AdminUsersRepository(this._dio);

  final Dio _dio;

  Future<Paginated<AdminUserSummary>> listAll({
    int page = 1,
    int pageSize = 50,
    UserRole? role,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (role != null) 'role': _roleToJson(role),
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return Paginated.fromJson(
        response.data as Map<String, dynamic>,
        AdminUserSummary.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AdminUserDetail> getOne(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return AdminUserDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppUser> updateOne(
    String id, {
    String? name,
    String? shopName,
    String? email,
    LocationInput? shopLocation,
  }) async {
    try {
      final response = await _dio.patch(
        '/users/$id',
        data: {
          if (name != null) 'name': name,
          if (shopName != null) 'shopName': shopName,
          if (email != null) 'email': email,
          if (shopLocation != null) 'shopLocation': shopLocation.toJson(),
        },
      );
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppUser> createAdmin({
    required String phoneNumber,
    required String name,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        '/users/admins',
        data: {
          'phoneNumber': phoneNumber,
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

String _roleToJson(UserRole role) => switch (role) {
  UserRole.customer => 'CUSTOMER',
  UserRole.rider => 'RIDER',
  UserRole.admin => 'ADMIN',
};
