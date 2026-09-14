import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/pricing_rule.dart';

final pricingRulesRepositoryProvider = Provider<PricingRulesRepository>((ref) {
  return PricingRulesRepository(ref.watch(dioProvider));
});

/// Pricing-formula management (admin): `/pricing-rules*`.
class PricingRulesRepository {
  PricingRulesRepository(this._dio);

  final Dio _dio;

  Future<List<PricingRule>> list() async {
    try {
      final response = await _dio.get('/pricing-rules');
      return (response.data as List)
          .map((e) => PricingRule.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PricingRule> create({
    required String name,
    required double baseFare,
    required double ratePerKg,
    required double ratePerKm,
    double? dangerousGoodsSurcharge,
    required double minCharge,
    String? currency,
    bool? isActive,
    String? effectiveFrom,
    String? effectiveTo,
  }) async {
    try {
      final response = await _dio.post(
        '/pricing-rules',
        data: {
          'name': name,
          'baseFare': baseFare,
          'ratePerKg': ratePerKg,
          'ratePerKm': ratePerKm,
          if (dangerousGoodsSurcharge != null)
            'dangerousGoodsSurcharge': dangerousGoodsSurcharge,
          'minCharge': minCharge,
          if (currency != null) 'currency': currency,
          if (isActive != null) 'isActive': isActive,
          if (effectiveFrom != null) 'effectiveFrom': effectiveFrom,
          if (effectiveTo != null) 'effectiveTo': effectiveTo,
        },
      );
      return PricingRule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PricingRule> update(
    String id, {
    String? name,
    double? baseFare,
    double? ratePerKg,
    double? ratePerKm,
    double? dangerousGoodsSurcharge,
    double? minCharge,
    String? currency,
    bool? isActive,
    String? effectiveFrom,
    String? effectiveTo,
  }) async {
    try {
      final response = await _dio.patch(
        '/pricing-rules/$id',
        data: {
          if (name != null) 'name': name,
          if (baseFare != null) 'baseFare': baseFare,
          if (ratePerKg != null) 'ratePerKg': ratePerKg,
          if (ratePerKm != null) 'ratePerKm': ratePerKm,
          if (dangerousGoodsSurcharge != null)
            'dangerousGoodsSurcharge': dangerousGoodsSurcharge,
          if (minCharge != null) 'minCharge': minCharge,
          if (currency != null) 'currency': currency,
          if (isActive != null) 'isActive': isActive,
          if (effectiveFrom != null) 'effectiveFrom': effectiveFrom,
          if (effectiveTo != null) 'effectiveTo': effectiveTo,
        },
      );
      return PricingRule.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/pricing-rules/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
