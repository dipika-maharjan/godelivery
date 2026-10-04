import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';

class UploadTicket {
  const UploadTicket({required this.assetId, required this.uploadUrl});

  factory UploadTicket.fromJson(Map<String, dynamic> json) {
    return UploadTicket(
      assetId: json['assetId'] as String,
      uploadUrl: json['uploadUrl'] as String,
    );
  }

  final String assetId;
  final String uploadUrl;
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(dioProvider));
});

class MediaRepository {
  MediaRepository(this._dio);

  final Dio _dio;

  Future<UploadTicket> requestUploadUrl({
    required String purpose,
    required String filename,
    required String mimeType,
    required int sizeBytes,
  }) async {
    try {
      final response = await _dio.post(
        '/media/uploads',
        data: {
          'purpose': purpose,
          'filename': filename,
          'mimeType': mimeType,
          'sizeBytes': sizeBytes,
        },
      );
      return UploadTicket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Uploads directly to the presigned MinIO URL — deliberately not using
  /// [dioProvider]'s client, which injects the API baseUrl/auth header that
  /// would break this absolute, unauthenticated URL.
  Future<void> uploadBytes({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      await Dio().put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
