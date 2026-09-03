import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/auth.dart';
import '../models/location.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<void> requestOtp(String phoneNumber) async {
    try {
      await _dio.post(
        '/auth/otp/request',
        data: {'phoneNumber': phoneNumber},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/otp/verify',
        data: {'phoneNumber': phoneNumber, 'code': code},
      );
      return VerifyOtpResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AuthTokens> completeSignup({
    required String signupToken,
    required String name,
    required String shopName,
    required LocationInput shopLocation,
    String? email,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup/complete',
        data: {
          'signupToken': signupToken,
          'name': name,
          'shopName': shopName,
          'shopLocation': shopLocation.toJson(),
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      return AuthTokens.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout(String? refreshToken) async {
    try {
      await _dio.post(
        '/auth/logout',
        data: {if (refreshToken != null) 'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
