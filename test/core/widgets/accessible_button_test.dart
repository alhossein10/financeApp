import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/widgets/accessible_button.dart';

void main() {
  group('AccessibleButton', () {
    testWidgets('renders with correct label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('has proper semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              onPressed: () {},
              semanticLabel: 'Submit form',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(AccessibleButton));
      expect(semantics.label, equals('Submit form'));
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AccessibleButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when loading', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              onPressed: () => pressed = true,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AccessibleButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('renders with icon when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              onPressed: () {},
              icon: const Icon(Icons.check),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('has tooltip when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Submit',
              onPressed: () {},
              tooltip: 'Submit the form',
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });
  });

  group('AccessibleIconButton', () {
    testWidgets('renders with correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.delete,
              onPressed: () {},
              semanticLabel: 'Delete',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('has proper semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.delete,
              onPressed: () {},
              semanticLabel: 'Delete item',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(AccessibleIconButton));
      expect(semantics.label, equals('Delete item'));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.delete,
              onPressed: () => pressed = true,
              semanticLabel: 'Delete',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AccessibleIconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('meets minimum touch target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.delete,
              onPressed: () {},
              semanticLabel: 'Delete',
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.constraints?.minWidth, greaterThanOrEqualTo(48.0));
      expect(iconButton.constraints?.minHeight, greaterThanOrEqualTo(48.0));
    });
  });

  group('AccessibleFAB', () {
    testWidgets('renders as regular FAB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFAB(
              icon: Icons.add,
              onPressed: () {},
              semanticLabel: 'Add expense',
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders as extended FAB when specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFAB(
              icon: Icons.add,
              onPressed: () {},
              semanticLabel: 'Add expense',
              isExtended: true,
              extendedLabel: 'Add Expense',
            ),
          ),
        ),
      );

      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('has proper semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFAB(
              icon: Icons.add,
              onPressed: () {},
              semanticLabel: 'Add new expense',
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(AccessibleFAB));
      expect(semantics.label, equals('Add new expense'));
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFAB(
              icon: Icons.add,
              onPressed: () => pressed = true,
              semanticLabel: 'Add',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AccessibleFAB));
      await tester.pump();

      expect(pressed, isTrue);
    });
  });
}
