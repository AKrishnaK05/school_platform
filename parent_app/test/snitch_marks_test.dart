import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:parent_app/screens/snitch/snitch_marks.dart';

void main() {
  testWidgets('Marks screen shows exam selector', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SnitchMarks()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Select Exam:'), findsOneWidget);
  });
}
