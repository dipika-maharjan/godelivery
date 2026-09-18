import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/location.dart';
import '../models/order.dart';
import '../models/pagination.dart';
import '../models/tracking.dart';

enum OrderRoleFilter { sent, received, assigned, all }

extension on OrderRoleFilter {
  String get apiValue => switch (this) {
    OrderRoleFilter.sent => 'sent',
    OrderRoleFilter.received => 'received',
    OrderRoleFilter.assigned => 'assigned',
    OrderRoleFilter.all => 'all',
  };
}

class PackageDraft {
  const PackageDraft({
    required this.name,
    required this.weightKg,
    this.isDangerous = false,
    this.isFragile = true,
    this.isFlammable = true,
    this.needsToBeDry = true,
    this.imageAssetIds = const [],
  });

  final String name;
  final double weightKg;
  final bool isDangerous;
  final bool isFragile;
  final bool isFlammable;
  final bool needsToBeDry;
  final List<String> imageAssetIds;

  Map<String, dynamic> toJson() => {
    'name': name,
    'weightKg': weightKg,
    'isDangerous': isDangerous,
    'isFragile': isFragile,
    'isFlammable': isFlammable,
    'needsToBeDry': needsToBeDry,
    if (imageAssetIds.isNotEmpty) 'imageAssetIds': imageAssetIds,
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
    OrderStatus? status,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/orders',
        queryParameters: {
          'role': role.apiValue,
          'page': page,
          'pageSize': pageSize,
          if (status != null) 'status': orderStatusToJson(status),
          if (search != null && search.isNotEmpty) 'search': search,
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

  /// Unclaimed pickup or delivery tasks, nearest-first when the rider has a
  /// known location (admin/rider).
  Future<Paginated<Order>> listAvailable({
    required String leg,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/orders/available',
        queryParameters: {'leg': leg, 'page': page, 'pageSize': pageSize},
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
    String? pickupLocationId,
    LocationInput? pickupLocation,
    String? pickupContactName,
    String? pickupContactPhone,
    DateTime? scheduledPickupDate,
    required String receiverName,
    required String receiverPhoneNumber,
    String? receiverEmail,
    required LocationInput receiverLocation,
    required List<PackageDraft> packages,
    OrderPayer payer = OrderPayer.sender,
    PaymentMethod paymentMethod = PaymentMethod.cod,
    double? codAmount,
  }) async {
    try {
      final response = await _dio.post(
        '/orders',
        data: {
          if (senderName != null) 'senderName': senderName,
          'payer': orderPayerToJson(payer),
          'paymentMethod': paymentMethodToJson(paymentMethod),
          if (codAmount != null) 'codAmount': codAmount,
          if (pickupLocationId != null) 'pickupLocationId': pickupLocationId,
          if (pickupLocationId == null && pickupLocation != null)
            'pickupLocation': pickupLocation.toJson(),
          if (pickupContactName != null) 'pickupContactName': pickupContactName,
          if (pickupContactPhone != null)
            'pickupContactPhone': pickupContactPhone,
          if (scheduledPickupDate != null)
            'scheduledPickupDate':
                '${scheduledPickupDate.year.toString().padLeft(4, '0')}-'
                '${scheduledPickupDate.month.toString().padLeft(2, '0')}-'
                '${scheduledPickupDate.day.toString().padLeft(2, '0')}',
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

  Future<Order> updatePickupLocation(
    String id,
    LocationInput pickupLocation,
  ) async {
    try {
      final response = await _dio.patch(
        '/orders/$id',
        data: {'pickupLocation': pickupLocation.toJson()},
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Order> _post(String path) async {
    try {
      final response = await _dio.post(path);
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Directly assigns a rider to the pickup leg, bypassing self-claim
  /// approval (admin).
  Future<Order> assignPickupRider(String id, String riderId) async {
    try {
      final response = await _dio.post(
        '/orders/$id/assign-pickup',
        data: {'riderId': riderId},
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Directly assigns a rider to the delivery leg, bypassing self-claim
  /// approval (admin). Only possible once the order is AT_WAREHOUSE.
  Future<Order> assignDeliveryRider(String id, String riderId) async {
    try {
      final response = await _dio.post(
        '/orders/$id/assign-delivery',
        data: {'riderId': riderId},
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Requests the pickup leg of an unclaimed order; needs admin approval
  /// before it counts as assigned (rider).
  Future<Order> claimPickup(String id) => _post('/orders/$id/claim-pickup');

  /// Requests the delivery leg of an order staged at a warehouse; needs
  /// admin approval before it counts as assigned (rider).
  Future<Order> claimDelivery(String id) => _post('/orders/$id/claim-delivery');

  Future<Order> approvePickupRider(String id) =>
      _post('/orders/$id/approve-pickup-rider');

  Future<Order> rejectPickupRider(String id) =>
      _post('/orders/$id/reject-pickup-rider');

  Future<Order> approveDeliveryRider(String id) =>
      _post('/orders/$id/approve-delivery-rider');

  Future<Order> rejectDeliveryRider(String id) =>
      _post('/orders/$id/reject-delivery-rider');

  Future<Order> unassignPickup(String id) => _post('/orders/$id/unassign-pickup');

  Future<Order> unassignDelivery(String id) =>
      _post('/orders/$id/unassign-delivery');

  /// Cancels an order at any (non-terminal) stage — unlike [cancel], which
  /// only works before a rider is assigned (admin).
  Future<Order> adminCancel(String id) => _post('/orders/$id/admin-cancel');

  Future<Order> collectCodAmount(String id) =>
      _post('/orders/$id/collect-cod-amount');

  /// The admin half of the two-party (receiver + admin) delivery sign-off.
  Future<Order> verifyDeliveryAdmin(String id) =>
      _post('/orders/$id/verify-delivery/admin');

  Future<Order> updateStatus(
    String id, {
    required OrderStatus status,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.patch(
        '/orders/$id/status',
        data: {
          'status': orderStatusToJson(status),
          'title': title,
          if (description != null) 'description': description,
          if (location != null) 'location': location,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Uint8List> _getPdfBytes(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// A 6x4in shipping label PDF, with a Code128 barcode of the tracking
  /// number for warehouse/admin scanners (admin).
  Future<Uint8List> getLabelPdf(String id) => _getPdfBytes('/orders/$id/label/pdf');

  /// The order invoice PDF, rendered on demand.
  Future<Uint8List> getInvoicePdf(String id) => _getPdfBytes('/orders/$id/invoice/pdf');
}
