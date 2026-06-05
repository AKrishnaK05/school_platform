import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/services/snitch_api.dart';

void main() {
  test('fetchAssignments returns a non-empty list', () async {
    final items = await SnitchApi.fetchAssignments();
    expect(items, isNotNull);
    expect(items.length, greaterThan(0));
  });

  test('fetchMarks returns data for known exam', () async {
    final marks = await SnitchApi.fetchMarks('Periodic Assessment 1');
    expect(marks, isNotNull);
    expect(marks.length, greaterThan(0));
  });

  test('fetchDashboardSummary returns a map with keys', () async {
    final summary = await SnitchApi.fetchDashboardSummary();
    expect(summary, isNotNull);
    expect(summary.containsKey('fees_due'), isTrue);
    expect(summary.containsKey('notifications'), isTrue);
  });
}
