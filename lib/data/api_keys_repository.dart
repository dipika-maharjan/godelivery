import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/api_key.dart';

final apiKeysRepositoryProvider = Provider<ApiKeysRepository>((ref) {
  return ApiKeysRepository(ref.watch(dioProvider));
});

/// Partner/integration API key management: `/api-keys*`.
class ApiKeysRepository {
  ApiKeysRepository(this._dio);

  final Dio _dio;

  Future<List<ApiKeyListItem>> list() async {
    try {
      final response = await _dio.get('/api-keys');
      return (response.data as List)
          .map((e) => ApiKeyListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CreatedApiKey> create({required String name, List<String>? scopes}) async {
    try {
      final response = await _dio.post(
        '/api-keys',
        data: {'name': name, if (scopes != null) 'scopes': scopes},
      );
      return CreatedApiKey.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> revoke(String id) async {
    try {
      await _dio.delete('/api-keys/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
