import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/location.dart';
import '../models/warehouse.dart';

final warehousesRepositoryProvider = Provider<WarehousesRepository>((ref) {
  return WarehousesRepository(ref.watch(dioProvider));
});

/// Sorting-hub management (admin): `/warehouses*`.
class WarehousesRepository {
  WarehousesRepository(this._dio);

  final Dio _dio;

  Future<List<Warehouse>> list() async {
    try {
      final response = await _dio.get('/warehouses');
      return (response.data as List)
          .map((e) => Warehouse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Warehouse> create({
    required String name,
    required LocationInput location,
  }) async {
    try {
      final response = await _dio.post(
        '/warehouses',
        data: {'name': name, 'location': location.toJson()},
      );
      return Warehouse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Warehouse> update(
    String id, {
    String? name,
    LocationInput? location,
    bool? isActive,
  }) async {
    try {
      final response = await _dio.patch(
        '/warehouses/$id',
        data: {
          if (name != null) 'name': name,
          if (location != null) 'location': location.toJson(),
          if (isActive != null) 'isActive': isActive,
        },
      );
      return Warehouse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/warehouses/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
