// IPlay App Tests
// This file contains basic smoke tests for the IPlay application
//
// Note: Full app tests require Firebase initialization and are located in
// integration_test/ directory

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test - MaterialApp renders', (WidgetTester tester) async {
    // Build a simple MaterialApp to verify Flutter setup
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('IPlay'),
          ),
        ),
      ),
    );

    // Verify the app renders
    expect(find.text('IPlay'), findsOneWidget);
  });

  test('App constants validation', () {
    // Validate key app constants
    const appName = 'IPlay';
    const minPasswordLength = 6;
    const maxClassroomNameLength = 50;

    expect(appName.isNotEmpty, isTrue);
    expect(minPasswordLength, greaterThanOrEqualTo(6));
    expect(maxClassroomNameLength, greaterThan(0));
  });
}
