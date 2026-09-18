import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/device_repository.dart';
import '../../models/device.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/rider_jobs_provider.dart';
import '../router/app_router.dart';
import '../storage/device_storage.dart';

/// Must match the channel id declared in AndroidManifest.xml's
/// `com.google.firebase.messaging.default_notification_channel_id` — that's
/// what FCM uses for a "notification"-payload push received while the app is
/// backgrounded/killed; this app also posts through it explicitly for
/// foreground pushes and data-only messages, which Android never surfaces on
/// its own.
const _androidChannelId = 'godelivery_default';
const _androidChannelName = 'General notifications';
const _androidNotificationIcon = 'ic_launcher_foreground';

final _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Must be a top-level (or static) function — the background isolate that
/// invokes this has no access to anything set up in `main()`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // No Firebase config yet — nothing to do until credentials are added.
    return;
  }
  // A "notification"-payload message is already shown by the OS at this
  // point. A data-only message (no `notification` block) is not — Android
  // silently drops it unless the app builds one itself.
  if (message.notification == null) {
    await _showLocalNotification(message);
  }
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'] as String?;
  final body = message.notification?.body ?? message.data['body'] as String?;
  if (title == null && body == null) return;

  await _initLocalNotifications();
  await _localNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        icon: _androidNotificationIcon,
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: message.data['orderId'] as String?,
  );
}

/// Routes a tapped notification's order to the right detail page for the
/// signed-in user's role — riders and admins have their own order detail
/// routes with role-specific actions (accept/pick up/deliver, assign rider).
void _navigateToOrder(Ref ref, String? orderId) {
  final router = ref.read(routerProvider);
  final role = ref.read(authControllerProvider).user?.role;
  if (orderId == null || orderId.isEmpty) {
    switch (role) {
      case UserRole.rider:
        router.push('/rider/notifications');
      case UserRole.admin:
        router.push('/admin/notifications');
      default:
        router.push('/home/notifications');
    }
    return;
  }
  switch (role) {
    case UserRole.rider:
      router.push('/rider/orders/$orderId');
    case UserRole.admin:
      router.push('/admin/orders/$orderId');
    default:
      router.push('/orders/$orderId');
  }
}

bool _localNotificationsInitialized = false;

/// Set from [PushNotificationsService]'s constructor so a tap on a
/// locally-shown notification (foreground pushes, data-only messages) can
/// navigate the same way a real FCM tap does via [PushNotificationsService._handleTap].
Ref? _serviceRef;

Future<void> _initLocalNotifications() async {
  if (_localNotificationsInitialized) return;
  _localNotificationsInitialized = true;

  await _localNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings(_androidNotificationIcon),
      // Permission is already requested (cross-platform) via
      // FirebaseMessaging.requestPermission() in
      // PushNotificationsService.initialize() before this runs — don't
      // also trigger flutter_local_notifications' own native iOS prompt.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: (response) {
      final ref = _serviceRef;
      if (ref == null) return;
      _navigateToOrder(ref, response.payload);
    },
  );

  if (!kIsWeb && Platform.isAndroid) {
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _androidChannelId,
            _androidChannelName,
            importance: Importance.high,
          ),
        );
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
/// FCM only auto-displays a "notification"-payload push while the app is
/// backgrounded or killed — never while it's in the foreground, and never
/// for a data-only push regardless of app state. Both of those gaps are
/// covered here by building a local notification through
/// [_showLocalNotification].
///
/// Every step is defensive about Firebase not being configured yet (no
/// `google-services.json` / `GoogleService-Info.plist`) — until real
/// credentials are dropped in, this quietly no-ops instead of crashing.
class PushNotificationsService {
  PushNotificationsService(this._ref) {
    _serviceRef = _ref;
  }

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

    await _initLocalNotifications();

    try {
      final token = await _getTokenSafely(messaging);
      await _registerDevice(token);

      if (!_listenersRegistered) {
        _listenersRegistered = true;
        messaging.onTokenRefresh.listen(_registerDevice);

        FirebaseMessaging.onMessage.listen((message) {
          _ref.invalidate(unreadCountProvider);
          _ref.invalidate(notificationsListProvider);
          // A rider/pickup assignment push means the rider's job lists are
          // now stale — those providers are built once at login and never
          // refetch on their own, so nudge them here too.
          _ref.invalidate(riderAssignedOrdersProvider);
          _ref.invalidate(availableJobsProvider);
          // Neither a notification- nor data-payload push is ever shown by
          // the OS while the app is in the foreground — always build it.
          _showLocalNotification(message);
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
        await deviceRepository.heartbeat(
          existingDeviceId,
          pushToken: pushToken,
        );
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
    _navigateToOrder(_ref, message.data['orderId'] as String?);
  }
}
