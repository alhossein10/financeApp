import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/utils/accessibility_utils.dart';

void main() {
  group('AccessibilityUtils', () {
    group('Contrast Ratio Calculation', () {
      test('calculates correct contrast ratio for black and white', () {
        final ratio = AccessibilityUtils.calculateContrastRatio(
          Colors.black,
          Colors.white,
        );
        
        expect(ratio, closeTo(21.0, 0.1));
      });

      test('calculates correct contrast ratio for same colors', () {
        final ratio = AccessibilityUtils.calculateContrastRatio(
          Colors.black,
          Colors.black,
        );
        
        expect(ratio, closeTo(1.0, 0.1));
      });

      test('meets contrast requirement for normal text', () {
        final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
          Colors.black,
          Colors.white,
        );
        
        expect(meetsRequirement, isTrue);
      });

      test('fails contrast requirement for low contrast', () {
        final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
          Colors.grey.shade400,
          Colors.grey.shade300,
        );
        
        expect(meetsRequirement, isFalse);
      });

      test('meets contrast requirement for large text with lower ratio', () {
        final meetsRequirement = AccessibilityUtils.meetsContrastRequirement(
          Colors.grey.shade700,
          Colors.white,
          isLargeText: true,
        );
        
        expect(meetsRequirement, isTrue);
      });
    });

    group('Semantic Labels', () {
      test('creates correct currency semantic label for USD', () {
        final label = AccessibilityUtils.currencySemanticLabel(
          100.50,
          'USD',
          locale: 'en',
        );
        
        expect(label, equals('100.50 US dollars'));
      });

      test('creates correct currency semantic label for SYP', () {
        final label = AccessibilityUtils.currencySemanticLabel(
          5000.00,
          'SYP',
          locale: 'en',
        );
        
        expect(label, equals('5000.00 Syrian pounds'));
      });

      test('creates correct currency semantic label for TRY', () {
        final label = AccessibilityUtils.currencySemanticLabel(
          250.75,
          'TRY',
          locale: 'en',
        );
        
        expect(label, equals('250.75 Turkish lira'));
      });

      test('creates correct date semantic label', () {
        final date = DateTime(2024, 3, 15);
        final label = AccessibilityUtils.dateSemanticLabel(
          date,
          locale: 'en',
        );
        
        expect(label, equals('March 15, 2024'));
      });

      test('creates correct navigation semantic label when selected', () {
        final label = AccessibilityUtils.navigationSemanticLabel(
          'Home',
          0,
          5,
          true,
        );
        
        expect(label, equals('Home, Tab 1 of 5, selected'));
      });

      test('creates correct navigation semantic label when not selected', () {
        final label = AccessibilityUtils.navigationSemanticLabel(
          'Profile',
          4,
          5,
          false,
        );
        
        expect(label, equals('Profile, Tab 5 of 5, not selected'));
      });

      test('creates correct loading semantic label', () {
        final label = AccessibilityUtils.loadingSemanticLabel('expenses');
        
        expect(label, equals('Loading expenses, please wait'));
      });

      test('creates correct error semantic label', () {
        final label = AccessibilityUtils.errorSemanticLabel('Network error');
        
        expect(label, equals('Error: Network error'));
      });

      test('creates correct success semantic label', () {
        final label = AccessibilityUtils.successSemanticLabel('Saved');
        
        expect(label, equals('Success: Saved'));
      });

      test('creates correct form field semantic label', () {
        final label = AccessibilityUtils.formFieldSemanticLabel(
          label: 'Email',
          isRequired: true,
          hint: 'Enter your email',
          error: 'Invalid email',
        );
        
        expect(label, contains('Email'));
        expect(label, contains('required'));
        expect(label, contains('Enter your email'));
        expect(label, contains('Error: Invalid email'));
      });

      test('creates correct button semantic label when enabled', () {
        final label = AccessibilityUtils.buttonSemanticLabel(
          label: 'Submit',
          isEnabled: true,
          isLoading: false,
        );
        
        expect(label, equals('Submit, button'));
      });

      test('creates correct button semantic label when loading', () {
        final label = AccessibilityUtils.buttonSemanticLabel(
          label: 'Submit',
          isEnabled: true,
          isLoading: true,
        );
        
        expect(label, equals('Submit, loading'));
      });

      test('creates correct button semantic label when disabled', () {
        final label = AccessibilityUtils.buttonSemanticLabel(
          label: 'Submit',
          isEnabled: false,
          isLoading: false,
        );
        
        expect(label, equals('Submit, disabled'));
      });

      test('creates correct image semantic label', () {
        final label = AccessibilityUtils.imageSemanticLabel(
          description: 'Profile picture',
        );
        
        expect(label, equals('Image: Profile picture'));
      });

      test('creates correct image semantic label when loading', () {
        final label = AccessibilityUtils.imageSemanticLabel(
          description: 'Profile picture',
          isLoading: true,
        );
        
        expect(label, equals('Loading image: Profile picture'));
      });

      test('creates correct image semantic label when error', () {
        final label = AccessibilityUtils.imageSemanticLabel(
          description: 'Profile picture',
          hasError: true,
        );
        
        expect(label, equals('Failed to load image: Profile picture'));
      });

      test('creates correct list item semantic label', () {
        final label = AccessibilityUtils.listItemSemanticLabel(
          title: 'Expense #123',
          subtitle: '\$50.00',
          index: 0,
          total: 10,
        );
        
        expect(label, contains('Expense #123'));
        expect(label, contains('\$50.00'));
        expect(label, contains('Item 1 of 10'));
      });
    });

    group('Touch Target Size', () {
      test('minimum touch target size is 48dp', () {
        expect(AccessibilityUtils.minTouchTargetSize, equals(48.0));
      });

      testWidgets('ensureMinTouchTarget wraps widget with constraints',
          (tester) async {
        final widget = AccessibilityUtils.ensureMinTouchTarget(
          child: const SizedBox(width: 20, height: 20, key: Key('test-widget')),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: widget,
            ),
          ),
        );

        final constrainedBox = tester.widget<ConstrainedBox>(
          find.ancestor(
            of: find.byKey(const Key('test-widget')),
            matching: find.byType(ConstrainedBox),
          ),
        );

        expect(
          constrainedBox.constraints.minWidth,
          equals(AccessibilityUtils.minTouchTargetSize),
        );
        expect(
          constrainedBox.constraints.minHeight,
          equals(AccessibilityUtils.minTouchTargetSize),
        );
      });
    });

    group('Contrast Requirements', () {
      test('minimum contrast ratio for normal text is 4.5:1', () {
        expect(AccessibilityUtils.minContrastRatio, equals(4.5));
      });

      test('minimum contrast ratio for large text is 3:1', () {
        expect(AccessibilityUtils.minLargeTextContrastRatio, equals(3.0));
      });
    });

    group('Text Scaling', () {
      test('maximum text scale factor is 2.0', () {
        expect(AccessibilityUtils.maxTextScaleFactor, equals(2.0));
      });
    });
  });
}
