import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery/app/app.dart';

void main() {
  testWidgets('GoDelivery splash screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GoDeliveryApp());

    expect(find.byType(Image), findsAtLeastNWidgets(1));
  });
}
