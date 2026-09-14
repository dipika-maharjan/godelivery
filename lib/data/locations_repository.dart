import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/saved_location.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepository(ref.watch(dioProvider));
});

/// The sender's saved pickup-address book: `GET/POST /locations`,
/// `PATCH/DELETE /locations/{id}`.
class LocationsRepository {
  LocationsRepository(this._dio);

  final Dio _dio;

  Future<List<SavedLocation>> list() async {
    try {
      final response = await _dio.get('/locations');
      return (response.data as List)
          .map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SavedLocation> create({
    String? label,
    required String addressLine,
    String? landmark,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    required double latitude,
    required double longitude,
    bool? isDefault,
  }) async {
    try {
      final response = await _dio.post(
        '/locations',
        data: {
          if (label != null) 'label': label,
          'addressLine': addressLine,
          if (landmark != null) 'landmark': landmark,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
          if (postalCode != null) 'postalCode': postalCode,
          if (country != null) 'country': country,
          'latitude': latitude,
          'longitude': longitude,
          if (isDefault != null) 'isDefault': isDefault,
        },
      );
      return SavedLocation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SavedLocation> update(
    String id, {
    String? label,
    String? addressLine,
    String? landmark,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    try {
      final response = await _dio.patch(
        '/locations/$id',
        data: {
          if (label != null) 'label': label,
          if (addressLine != null) 'addressLine': addressLine,
          if (landmark != null) 'landmark': landmark,
          if (city != null) 'city': city,
          if (state != null) 'state': state,
          if (postalCode != null) 'postalCode': postalCode,
          if (country != null) 'country': country,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (isDefault != null) 'isDefault': isDefault,
        },
      );
      return SavedLocation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/locations/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
