import 'package:dio/dio.dart';

/// A user-presentable wrapper around a failed API call.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException error) {
    final data = error.response?.data;
    String? message;
    if (data is Map) {
      final rawMessage = data['message'];
      if (rawMessage is String) {
        message = rawMessage;
      } else if (rawMessage is List && rawMessage.isNotEmpty) {
        message = rawMessage.join(', ');
      }
    }
    message ??= switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The connection timed out. Please try again.',
      DioExceptionType.connectionError =>
        "Couldn't reach the server. Check your connection and try again.",
      _ => error.message ?? 'Something went wrong. Please try again.',
    };
    return ApiException(message, statusCode: error.response?.statusCode);
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
