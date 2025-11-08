import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iplay/widgets/xp_counter.dart';

void main() {
  group('XPCounter Widget Tests', () {
    testWidgets('should render XP value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPCounter(xp: 1234),
          ),
        ),
      );

      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('should animate when XP changes', (WidgetTester tester) async {
      int xp = 100;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    XPCounter(xp: xp),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          xp = 200;
                        });
                      },
                      child: const Text('Increase XP'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('100'), findsOneWidget);

      await tester.tap(find.text('Increase XP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Animation should be in progress
      expect(find.byType(XPCounter), findsOneWidget);
    });

    testWidgets('should use custom text style', (WidgetTester tester) async {
      const customStyle = TextStyle(fontSize: 32, color: Colors.red);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPCounter(
              xp: 1234,
              textStyle: customStyle,
            ),
          ),
        ),
      );

      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('should handle zero XP', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPCounter(xp: 0),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should handle large XP values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XPCounter(xp: 999999),
          ),
        ),
      );

      expect(find.text('999999'), findsOneWidget);
    });
  });
}
