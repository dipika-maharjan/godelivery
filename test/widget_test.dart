import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery/app/app.dart';

void main() {
  testWidgets('GoDelivery app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GoDeliveryApp());

    expect(find.text('GoDelivery'), findsOneWidget);
  });
}