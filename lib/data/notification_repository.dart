import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/notification.dart';
import '../models/pagination.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<Paginated<AppNotification>> list({
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (unreadOnly != null) 'unreadOnly': unreadOnly,
        },
      );
      return Paginated.fromJson(
        response.data as Map<String, dynamic>,
        AppNotification.fromJson,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return ((response.data as Map<String, dynamic>)['count'] as num).toInt();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppNotification> markRead(String id) async {
    try {
      final response = await _dio.patch('/notifications/$id/read');
      return AppNotification.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
