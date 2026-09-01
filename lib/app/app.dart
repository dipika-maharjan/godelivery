import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

class GoDeliveryApp extends StatelessWidget {
  const GoDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'GoDelivery',

      theme: AppTheme.lightTheme,

      home: const Scaffold(
        body: Center(
          child: Text('GoDelivery'),
        ),
      ),
    );
  }
}