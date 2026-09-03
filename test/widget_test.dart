import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery/app/app.dart';
import 'package:godelivery/features/otp/presentation/otp_screen.dart';
import 'package:godelivery/features/signin/presentation/signin_screen.dart';

void main() {
  testWidgets('GoDelivery splash screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GoDeliveryApp());
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsAtLeastNWidgets(1));
  });

  testWidgets('Send OTP opens the OTP screen for a valid number', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SigninScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/verify-otp') {
            final phoneNumber = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => OtpScreen(phoneNumber: phoneNumber),
            );
          }
          return null;
        },
      ),
    );

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.text('SEND OTP'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Verify OTP'), findsOneWidget);
  });
}
