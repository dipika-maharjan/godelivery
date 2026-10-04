import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery/core/theme/app_theme.dart';
import 'package:godelivery/features/welcome/welcome_page.dart';
import 'package:godelivery/providers/auth_provider.dart';

class _UnauthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.unauthenticated();
}

void main() {
  testWidgets('Welcome page shows the sign-in entry point', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            _UnauthenticatedAuthController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WelcomePage(),
        ),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
  });
}
