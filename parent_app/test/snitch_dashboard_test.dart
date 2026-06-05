import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:parent_app/screens/snitch/snitch_dashboard.dart';

void main() {
  testWidgets('Dashboard builds and shows greeting', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SnitchDashboard()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Snitch Dashboard'), findsOneWidget);
  });
}
