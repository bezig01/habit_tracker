import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HabitTrackerApp());

    // Verify that the app loads (we can check for any basic widget)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
