import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery/core/network/api_exception.dart';

void main() {
  test('maps throttler exceptions to a user-friendly message', () {
    final exception = ApiException.fromDioException(
      DioException(
        requestOptions: RequestOptions(path: '/auth/otp/request'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/otp/request'),
          statusCode: 429,
          data: {'message': 'ThrottlerException: Too Many Requests'},
        ),
      ),
    );

    expect(
      exception.message,
      'We’re receiving a high volume of requests right now. '
      'Please wait a moment and try again.',
    );
    expect(exception.statusCode, 429);
  });

  test('maps throttler text even when the response has no status code', () {
    final exception = ApiException.fromDioException(
      DioException(
        requestOptions: RequestOptions(path: '/auth/otp/request'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/otp/request'),
          data: {'message': 'ThrottlerException'},
        ),
      ),
    );

    expect(
      exception.message,
      'We’re receiving a high volume of requests right now. '
      'Please wait a moment and try again.',
    );
  });
}
