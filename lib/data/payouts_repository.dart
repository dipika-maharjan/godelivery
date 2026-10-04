import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/pagination.dart';
import '../models/payout.dart';

final payoutsRepositoryProvider = Provider<PayoutsRepository>((ref) {
  return PayoutsRepository(ref.watch(dioProvider));
});

/// Rider reimbursement record-keeping (admin): `/payouts*`.
class PayoutsRepository {
  PayoutsRepository(this._dio);

  final Dio _dio;

  Future<Paginated<Payout>> list({
    int page = 1,
    int pageSize = 50,
    String? riderId,
    PayoutStatus? status,
  }) async {
    try {
      final response = await _dio.get(
        '/payouts',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (riderId != null) 'riderId': riderId,
          if (status != null) 'status': payoutStatusToJson(status),
        },
      );
      return Paginated.fromJson(
        response.data as Map<String, dynamic>,
        Payout.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Payout> getOne(String id) async {
    try {
      final response = await _dio.get('/payouts/$id');
      return Payout.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Payout> create({
    required String riderId,
    required List<String> orderIds,
    String? referenceNote,
  }) async {
    try {
      final response = await _dio.post(
        '/payouts',
        data: {
          'riderId': riderId,
          'orderIds': orderIds,
          if (referenceNote != null) 'referenceNote': referenceNote,
        },
      );
      return Payout.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Payout> markPaid(String id) async {
    try {
      final response = await _dio.post('/payouts/$id/mark-paid');
      return Payout.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Payout> markFailed(String id, {String? reason}) async {
    try {
      final response = await _dio.post(
        '/payouts/$id/mark-failed',
        data: {if (reason != null) 'reason': reason},
      );
      return Payout.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
