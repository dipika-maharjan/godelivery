import 'package:flutter/material.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/signin/presentation/signin_screen.dart';
import '../features/otp/presentation/otp_screen.dart';
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
      routes: {
        '/signin': (context) => const SigninScreen(),
        '/phone-input': (context) => const SigninScreen(),
        '/business-info': (context) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verify-otp') {
          final args = settings.arguments;
          final phoneNumber = args is String ? args : '';
          return MaterialPageRoute(
            builder: (_) => OtpScreen(phoneNumber: phoneNumber),
          );
        }

        return null;
      },
    );
  }
}
