import 'package:baato_maps/baato_maps.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:galli_maps_package/galli_maps_package.dart';

import 'core/config/app_config.dart';
import 'core/notifications/push_notifications_service.dart';
import 'core/router/app_router.dart';
import 'core/shortcuts/quick_actions_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // No google-services.json / GoogleService-Info.plist yet — push
    // notifications stay off until real Firebase credentials are added.
  }

  await Baato.configure(apiKey: AppConfig.baatomapsApiKey);
  await GalliMaps.initialize(accessToken: AppConfig.gallimapsApiKey);

  runApp(const ProviderScope(child: GoDeliveryApp()));
}

class GoDeliveryApp extends ConsumerStatefulWidget {
  const GoDeliveryApp({super.key});

  @override
  ConsumerState<GoDeliveryApp> createState() => _GoDeliveryAppState();
}

class _GoDeliveryAppState extends ConsumerState<GoDeliveryApp> {
  @override
  void initState() {
    super.initState();
    // Registers the home-screen long-press shortcuts; safe to call
    // regardless of auth state since it only wires up the OS-level menu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quickActionsServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'GoDelivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child!,
      ),
      routerConfig: router,
    );
  }
}
