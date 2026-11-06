import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('probe', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('hi')));
    expect(find.text('hi'), findsOneWidget);
  });
}
