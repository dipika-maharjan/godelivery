import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'session_events.dart';

/// Builds the single shared [Dio] client used by every repository.
///
/// Attaches the stored bearer token to every request and, on a 401, makes
/// one attempt to refresh the session via `/auth/refresh` before retrying
/// the original request. If the refresh itself fails, the stored tokens are
/// cleared and [SessionEvents.onSessionExpired] is fired so the auth layer
/// can drop back to the signed-out state.
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final sessionEvents = ref.watch(sessionEventsProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final tokens = await tokenStorage.read();
        if (tokens != null) {
          options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;
        final isRefreshCall = error.requestOptions.path.contains(
          '/auth/refresh',
        );

        if (!isUnauthorized || alreadyRetried || isRefreshCall) {
          handler.next(error);
          return;
        }

        final stored = await tokenStorage.read();
        if (stored == null) {
          handler.next(error);
          return;
        }

        try {
          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refreshToken': stored.refreshToken},
          );
          final data = response.data as Map<String, dynamic>;
          final newTokens = StoredTokens(
            accessToken: data['accessToken'] as String,
            refreshToken: data['refreshToken'] as String,
          );
          await tokenStorage.save(newTokens);

          final retryOptions = error.requestOptions
            ..extra['retried'] = true
            ..headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
          final retryResponse = await dio.fetch(retryOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          await tokenStorage.clear();
          sessionEvents.onSessionExpired?.call();
          handler.next(error);
        }
      },
    ),
  );

  return dio;
});
