import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/location.dart';
import '../models/receiver_lookup.dart';
import '../models/user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(dioProvider));
});

class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  Future<AppUser> getMe() async {
    try {
      final response = await _dio.get('/users/me');
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppUser> updateMe({
    String? name,
    String? shopName,
    String? email,
    LocationInput? shopLocation,
  }) async {
    try {
      final response = await _dio.patch(
        '/users/me',
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

  Future<ReceiverLookupResult> lookup(String phoneNumber) async {
    try {
      final response = await _dio.get(
        '/users/lookup',
        queryParameters: {'phoneNumber': phoneNumber},
      );
      return ReceiverLookupResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
