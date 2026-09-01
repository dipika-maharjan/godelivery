import 'package:flutter/material.dart';

import '../features/splash/presentation/splash_screen.dart';
import 'theme/app_theme.dart';

class GoDeliveryApp extends StatelessWidget {
  const GoDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoDelivery',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
