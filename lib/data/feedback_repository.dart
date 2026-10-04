import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.watch(dioProvider));
});

class FeedbackRepository {
  FeedbackRepository(this._dio);

  final Dio _dio;

  Future<void> submit({
    required String category,
    required String message,
    int? rating,
  }) async {
    try {
      await _dio.post(
        '/feedback',
        data: {
          'category': category,
          'message': message,
          if (rating != null) 'rating': rating,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
