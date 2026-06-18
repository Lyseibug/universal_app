import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_app/widgets/qty_stepper.dart';

void main() {
  group('QtyStepper Widget Tests', () {
    testWidgets('renders initial value correctly', (tester) async {
      double value = 5.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QtyStepper(
              value: value,
              onChanged: (val) {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('calls onChanged with incremented value when plus button tapped', (tester) async {
      double value = 5.0;
      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QtyStepper(
              value: value,
              onChanged: (val) {
                result = val;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(result, equals(6.0));
    });

    testWidgets('calls onChanged with decremented value when minus button tapped', (tester) async {
      double value = 5.0;
      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QtyStepper(
              value: value,
              onChanged: (val) {
                result = val;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(result, equals(4.0));
    });

    testWidgets('does not decrement below min value', (tester) async {
      double value = 1.0;
      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QtyStepper(
              value: value,
              min: 1.0,
              onChanged: (val) {
                result = val;
              },
            ),
          ),
        ),
      );

      // Try tapping minus
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(result, isNull); // callback not fired because it is disabled
    });
  });
}
