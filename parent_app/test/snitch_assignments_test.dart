import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:parent_app/screens/snitch/snitch_assignments.dart';

void main() {
  testWidgets('Assignments screen loads and shows title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SnitchAssignments()));
    await tester.pump();

    expect(find.text('Assignments'), findsOneWidget);
  });
}
