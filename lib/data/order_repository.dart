import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/location.dart';
import '../models/order.dart';
import '../models/pagination.dart';
import '../models/tracking.dart';

enum OrderRoleFilter { sent, received, all }

extension on OrderRoleFilter {
  String get apiValue => switch (this) {
    OrderRoleFilter.sent => 'sent',
    OrderRoleFilter.received => 'received',
    OrderRoleFilter.all => 'all',
  };
}

class PackageDraft {
  const PackageDraft({
    required this.name,
    required this.weightKg,
    this.isDangerous = false,
  });

  final String name;
  final double weightKg;
  final bool isDangerous;

  Map<String, dynamic> toJson() => {
    'name': name,
    'weightKg': weightKg,
    'isDangerous': isDangerous,
  };
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioProvider));
});

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<Paginated<Order>> list({
    required OrderRoleFilter role,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/orders',
        queryParameters: {
          'role': role.apiValue,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return Paginated.fromJson(
        response.data as Map<String, dynamic>,
        Order.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Order> getOne(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PublicTracking> track(String trackingNumber) async {
    try {
      final response = await _dio.get('/orders/track/$trackingNumber');
      return PublicTracking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Order> create({
    String? senderName,
    LocationInput? pickupLocation,
    required String receiverName,
    required String receiverPhoneNumber,
    String? receiverEmail,
    required LocationInput receiverLocation,
    required List<PackageDraft> packages,
  }) async {
    try {
      final response = await _dio.post(
        '/orders',
        data: {
          if (senderName != null) 'senderName': senderName,
          if (pickupLocation != null)
            'pickupLocation': pickupLocation.toJson(),
          'receiver': {
            'name': receiverName,
            'phoneNumber': receiverPhoneNumber,
            if (receiverEmail != null && receiverEmail.isNotEmpty)
              'email': receiverEmail,
            'location': receiverLocation.toJson(),
          },
          'packages': packages.map((p) => p.toJson()).toList(),
        },
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Order> cancel(String id) async {
    try {
      final response = await _dio.post('/orders/$id/cancel');
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
