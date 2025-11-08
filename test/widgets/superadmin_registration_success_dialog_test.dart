import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/auth/presentation/widgets/superadmin_registration_success_dialog.dart';
import 'package:finance_app/l10n/app_localizations.dart';

void main() {
  group('SuperAdminRegistrationSuccessDialog Widget Tests', () {
    const testGroupCode = 'ABC123';
    const testAdminGroupName = 'Test Admin Group';

    Widget createWidgetUnderTest() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    SuperAdminRegistrationSuccessDialog.show(
                      context: context,
                      groupCode: testGroupCode,
                      adminGroupName: testAdminGroupName,
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('should display group code prominently', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify group code is displayed in uppercase
      expect(find.text(testGroupCode.toUpperCase()), findsOneWidget);
      
      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should display admin group name', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify admin group name is displayed
      expect(find.text(testAdminGroupName), findsOneWidget);
    });

    testWidgets('should display success icon', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify success icon is displayed
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display copy button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify copy button is displayed
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.widgetWithIcon(ElevatedButton, Icons.copy), findsOneWidget);
    });

    testWidgets('should copy group code to clipboard when copy button is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find and tap copy button
      final copyButton = find.widgetWithIcon(ElevatedButton, Icons.copy);
      await tester.tap(copyButton);
      await tester.pump();

      // Verify snackbar is shown
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify clipboard contains the group code
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      expect(clipboardData?.text, equals(testGroupCode));
    });

    testWidgets('should display info message about sharing code', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify info icon is displayed
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      
      // Verify info container is displayed
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display continue button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify continue button is displayed
      final continueButtons = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueButtons, findsOneWidget);
    });

    testWidgets('should close dialog when continue button is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap continue button
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should not be dismissible by tapping outside', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Try to tap outside the dialog (tap on barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify dialog is still shown (barrierDismissible: false)
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should display group code in monospace font', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the group code text widget
      final groupCodeText = find.text(testGroupCode.toUpperCase());
      expect(groupCodeText, findsOneWidget);

      // Verify text style includes monospace font
      final textWidget = tester.widget<Text>(groupCodeText);
      expect(textWidget.style?.fontFamily, equals('monospace'));
    });

    testWidgets('should display group code with letter spacing', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the group code text widget
      final groupCodeText = find.text(testGroupCode.toUpperCase());
      final textWidget = tester.widget<Text>(groupCodeText);
      
      // Verify letter spacing is applied
      expect(textWidget.style?.letterSpacing, equals(4));
    });

    testWidgets('should display all required UI elements', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify all key elements are present
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // Success icon
      expect(find.text(testGroupCode.toUpperCase()), findsOneWidget); // Group code
      expect(find.text(testAdminGroupName), findsOneWidget); // Group name
      expect(find.byIcon(Icons.copy), findsOneWidget); // Copy button
      expect(find.byIcon(Icons.info_outline), findsOneWidget); // Info icon
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget); // Continue button
    });
  });
}
