import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:galli_maps_package/galli_maps_package.dart';

import 'core/config/app_config.dart';
import 'core/notifications/push_notifications_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GalliMaps.initialize(accessToken: AppConfig.galliMapsAccessToken);

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // No google-services.json / GoogleService-Info.plist yet — push
    // notifications stay off until real Firebase credentials are added.
  }

  runApp(const ProviderScope(child: GoDeliveryApp()));
}

class GoDeliveryApp extends ConsumerWidget {
  const GoDeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GoDelivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
