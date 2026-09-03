import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:godelivery/main.dart';

void main() {
  testWidgets('Welcome page shows the sign-in entry point', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GoDeliveryApp()));

    // The auth bootstrap reads secure storage over a real platform channel,
    // which the fake-async test clock won't drain on its own — hop into
    // runAsync so the resulting unauthenticated state actually lands.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    expect(find.text('Sign In'), findsOneWidget);
  });
}
