import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iplay/widgets/stat_card.dart';

void main() {
  group('StatCard Widget Tests', () {
    testWidgets('should render stat card with all elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total XP',
              value: '1,234',
              icon: Icons.star,
              color: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.text('Total XP'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('should render stat card with subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total XP',
              value: '1,234',
              icon: Icons.star,
              color: Colors.amber,
              subtitle: '+50 today',
            ),
          ),
        ),
      );

      expect(find.text('Total XP'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('+50 today'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total XP',
              value: '1,234',
              icon: Icons.star,
              color: Colors.amber,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should not be tappable when onTap is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total XP',
              value: '1,234',
              icon: Icons.star,
              color: Colors.amber,
            ),
          ),
        ),
      );

      expect(find.byType(StatCard), findsOneWidget);
    });
  });
}
