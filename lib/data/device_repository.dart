import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/device.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(dioProvider));
});

class DeviceRepository {
  DeviceRepository(this._dio);

  final Dio _dio;

  Future<AppDevice> register({
    required DevicePlatform platform,
    required String deviceIdentifier,
    String? pushToken,
  }) async {
    try {
      final response = await _dio.post(
        '/devices/register',
        data: {
          'platform': devicePlatformToJson(platform),
          'deviceIdentifier': deviceIdentifier,
          if (pushToken != null) 'pushToken': pushToken,
        },
      );
      return AppDevice.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppDevice> heartbeat(String deviceId, {String? pushToken}) async {
    try {
      final response = await _dio.patch(
        '/devices/$deviceId/heartbeat',
        data: {if (pushToken != null) 'pushToken': pushToken},
      );
      return AppDevice.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
