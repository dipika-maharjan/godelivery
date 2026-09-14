import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/pagination.dart';
import '../models/rider.dart';

final ridersRepositoryProvider = Provider<RidersRepository>((ref) {
  return RidersRepository(ref.watch(dioProvider));
});

/// Delivery-partner management (admin) and self-service rider endpoints:
/// `/riders*`.
class RidersRepository {
  RidersRepository(this._dio);

  final Dio _dio;

  Future<Rider> getMe() async {
    try {
      final response = await _dio.get('/riders/me');
      return Rider.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Rider> updateMe({VehicleType? vehicleType, String? vehiclePlateNumber}) async {
    try {
      final response = await _dio.patch(
        '/riders/me',
        data: {
          if (vehicleType != null) 'vehicleType': vehicleTypeToJson(vehicleType),
          if (vehiclePlateNumber != null) 'vehiclePlateNumber': vehiclePlateNumber,
        },
      );
      return Rider.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Rider> setAvailability(bool isAvailable) async {
    try {
      final response = await _dio.post(
        '/riders/me/availability',
        data: {'isAvailable': isAvailable},
      );
      return Rider.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Submits a GPS ping — updates this rider's live location and appends
  /// to their trail. [orderId] tags the ping with the delivery currently
  /// in progress, if any.
  Future<void> submitLocation({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    double? speedKmh,
    double? heading,
    String? orderId,
  }) async {
    try {
      await _dio.post(
        '/riders/me/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
          if (speedKmh != null) 'speedKmh': speedKmh,
          if (heading != null) 'heading': heading,
          if (orderId != null) 'orderId': orderId,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BankAccount> getOwnBankAccount() async {
    try {
      final response = await _dio.get('/riders/me/bank-account');
      return BankAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BankAccount> upsertOwnBankAccount({
    required String bankName,
    required String accountName,
    required String accountNumber,
    String? branch,
  }) async {
    try {
      final response = await _dio.put(
        '/riders/me/bank-account',
        data: {
          'bankName': bankName,
          'accountName': accountName,
          'accountNumber': accountNumber,
          if (branch != null) 'branch': branch,
        },
      );
      return BankAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Paginated<Rider>> list({
    int page = 1,
    int pageSize = 50,
    bool? isActive,
    bool? isAvailable,
  }) async {
    try {
      final response = await _dio.get(
        '/riders',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (isActive != null) 'isActive': isActive,
          if (isAvailable != null) 'isAvailable': isAvailable,
        },
      );
      return Paginated.fromJson(
        response.data as Map<String, dynamic>,
        Rider.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Rider> getOne(String id) async {
    try {
      final response = await _dio.get('/riders/$id');
      return Rider.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Rider> onboard({
    required String phoneNumber,
    required String name,
    VehicleType? vehicleType,
    String? vehiclePlateNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/riders',
        data: {
          'phoneNumber': phoneNumber,
          'name': name,
          if (vehicleType != null) 'vehicleType': vehicleTypeToJson(vehicleType),
          if (vehiclePlateNumber != null)
            'vehiclePlateNumber': vehiclePlateNumber,
        },
      );
      return Rider.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Rider> update(
    String id, {
    String? name,
    VehicleType? vehicleType,
    String? vehiclePlateNumber,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.patch(
        '/riders/$id',
        data: {
          if (name != null) 'name': name,
          if (vehicleType != null) 'vehicleType': vehicleTypeToJson(vehicleType),
          if (vehiclePlateNumber != null)
            'vehiclePlateNumber': vehiclePlateNumber,
          if (isActive != null) 'isActive': isActive,
        },
      );
      return Rider.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<RiderMetrics> metrics(String id) async {
    try {
      final response = await _dio.get('/riders/$id/metrics');
      return RiderMetrics.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BankAccount> bankAccount(String id) async {
    try {
      final response = await _dio.get('/riders/$id/bank-account');
      return BankAccount.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<RiderUnpaidDeliveries> unpaidDeliveries(String id) async {
    try {
      final response = await _dio.get('/riders/$id/unpaid-deliveries');
      return RiderUnpaidDeliveries.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
