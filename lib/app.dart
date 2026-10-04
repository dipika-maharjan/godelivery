import 'package:flutter/material.dart';
import 'package:godelivery/presentation/pages/account_page.dart';
import 'package:godelivery/presentation/pages/dashboard_page.dart';
import 'package:godelivery/presentation/pages/phone_input_page.dart';
import 'package:godelivery/presentation/pages/otp_verification_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoDelivery',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFCC00),
          primary: const Color(0xFFFFCC00),
        ),
      ),
      home: const PhoneInputPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/account': (context) => const AccountPage(),
        '/verify-otp': (context) {
          final phoneNumber = ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return OtpVerificationPage(phoneNumber: phoneNumber);
        },
      },
    );
  }
}
