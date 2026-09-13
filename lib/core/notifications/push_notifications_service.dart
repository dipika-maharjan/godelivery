import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/device_repository.dart';
import '../../models/device.dart';
import '../../providers/notifications_provider.dart';
import '../router/app_router.dart';
import '../storage/device_storage.dart';

/// Must be a top-level (or static) function — the background isolate that
/// invokes this has no access to anything set up in `main()`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // No Firebase config yet — nothing to do until credentials are added.
  }
}

final pushNotificationsServiceProvider = Provider<PushNotificationsService>((
  ref,
) {
  return PushNotificationsService(ref);
});

/// Wires up FCM: permission + token registration, refreshing the device's
/// push token, badge-count refresh on a foreground push, and navigating to
/// the relevant order when a notification is tapped.
///
/// Every step is defensive about Firebase not being configured yet (no
/// `google-services.json` / `GoogleService-Info.plist`) — until real
/// credentials are dropped in, this quietly no-ops instead of crashing.
class PushNotificationsService {
  PushNotificationsService(this._ref);

  final Ref _ref;
  bool _listenersRegistered = false;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // No google-services.json / GoogleService-Info.plist yet.
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return;

    try {
      final token = await _getTokenSafely(messaging);
      await _registerDevice(token);

      if (!_listenersRegistered) {
        _listenersRegistered = true;
        messaging.onTokenRefresh.listen(_registerDevice);

        FirebaseMessaging.onMessage.listen((message) {
          _ref.invalidate(unreadCountProvider);
          _ref.invalidate(notificationsListProvider);
        });

        FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) _handleTap(initialMessage);
      }
    } catch (_) {
      // Best-effort — push just won't be registered for this session;
      // the next launch (or token refresh) gets another chance.
    }
  }

  /// On iOS, FCM can't hand back a token until the OS has finished
  /// registering the device for remote notifications (the APNs token).
  /// That registration lands a moment after permission is granted, so
  /// `getToken()` called immediately can throw `apns-token-not-set` —
  /// poll briefly for it instead of failing outright.
  Future<String?> _getTokenSafely(FirebaseMessaging messaging) async {
    if (!kIsWeb && Platform.isIOS) {
      var apnsToken = await messaging.getAPNSToken();
      var attempts = 0;
      while (apnsToken == null && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        apnsToken = await messaging.getAPNSToken();
        attempts++;
      }
      if (apnsToken == null) return null;
    }
    return messaging.getToken();
  }

  Future<void> _registerDevice(String? pushToken) async {
    final deviceStorage = _ref.read(deviceStorageProvider);
    final deviceRepository = _ref.read(deviceRepositoryProvider);
    final deviceIdentifier = await deviceStorage.getOrCreateDeviceIdentifier();
    final existingDeviceId = await deviceStorage.readRegisteredDeviceId();

    try {
      if (existingDeviceId != null) {
        await deviceRepository.heartbeat(existingDeviceId, pushToken: pushToken);
        return;
      }
      final device = await deviceRepository.register(
        platform: kIsWeb
            ? DevicePlatform.web
            : Platform.isIOS
            ? DevicePlatform.ios
            : DevicePlatform.android,
        deviceIdentifier: deviceIdentifier,
        pushToken: pushToken,
      );
      await deviceStorage.saveRegisteredDeviceId(device.id);
    } catch (_) {
      // Best-effort — push just won't be registered for this session.
    }
  }

  void _handleTap(RemoteMessage message) {
    final orderId = message.data['orderId'] as String?;
    final router = _ref.read(routerProvider);
    if (orderId != null) {
      router.push('/orders/$orderId');
    } else {
      router.push('/home/notifications');
    }
  }
}
