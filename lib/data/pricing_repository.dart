import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/pricing.dart';

final pricingRepositoryProvider = Provider<PricingRepository>((ref) {
  return PricingRepository(ref.watch(dioProvider));
});

class PricingRepository {
  PricingRepository(this._dio);

  final Dio _dio;

  Future<EstimateResult> estimate(EstimateRequest request) async {
    try {
      final response = await _dio.post(
        '/pricing/estimate',
        data: request.toJson(),
      );
      return EstimateResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
