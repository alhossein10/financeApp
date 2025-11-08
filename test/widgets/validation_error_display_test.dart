import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_exception.dart';

void main() {
  group('Validation Error Display Tests', () {
    testWidgets('should display single validation error', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'email': ['The email field is required.']
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    exception.userFriendlyMessage,
                    style: const TextStyle(color: Colors.orange, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('The email field is required.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display multiple validation errors', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'email': ['The email field is required.'],
          'password': ['The password must be at least 8 characters.'],
          'name': ['The name field is required.'],
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        exception.userFriendlyMessage,
                        style: const TextStyle(color: Colors.orange, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('The email field is required.'), findsOneWidget);
      expect(find.textContaining('The password must be at least 8 characters.'), findsOneWidget);
      expect(find.textContaining('The name field is required.'), findsOneWidget);
    });

    testWidgets('should display validation error below text field', (tester) async {
      const errorMessage = 'The email field is required.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: errorMessage,
                      errorStyle: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should display validation errors in form', (tester) async {
      final formKey = GlobalKey<FormState>();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      formKey.currentState!.validate();
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('should display formatted validation errors', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'amount': ['The amount field is required.', 'The amount must be greater than 0.'],
          'date': ['The date field is required.'],
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Validation Errors:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        exception.getFormattedValidationErrors(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('amount:'), findsOneWidget);
      expect(find.textContaining('date:'), findsOneWidget);
    });

    testWidgets('should display validation error in snackbar', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'payment_method': ['The payment method field is required.']
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(exception.userFriendlyMessage),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    child: const Text('Submit'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('The payment method field is required.'), findsOneWidget);
    });

    testWidgets('should display validation errors as list', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'from_account': ['The from account field is required.'],
          'to_account': ['The to account field is required.'],
          'amount': ['The amount must be greater than 0.'],
        },
      );
      
      final errorList = exception.getValidationErrors();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: errorList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.error, color: Colors.red),
                  title: Text(
                    errorList[index],
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.byIcon(Icons.error), findsNWidgets(3));
      expect(find.textContaining('from_account:'), findsOneWidget);
      expect(find.textContaining('to_account:'), findsOneWidget);
      expect(find.textContaining('amount:'), findsOneWidget);
    });

    testWidgets('should clear validation error when field is corrected', (tester) async {
      String? errorText;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          errorText: errorText,
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              errorText = 'Email is required';
                            } else if (!value.contains('@')) {
                              errorText = 'Invalid email format';
                            } else {
                              errorText = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initially no error
      expect(find.text('Email is required'), findsNothing);

      // Enter invalid email
      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.pump();
      expect(find.text('Invalid email format'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();
      expect(find.text('Invalid email format'), findsNothing);
    });

    testWidgets('should display validation error with custom styling', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'category': ['The category field is required.']
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        exception.userFriendlyMessage,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('The category field is required.'), findsOneWidget);
    });

    testWidgets('should display payment method validation error', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'payment_method': ['The payment method must be one of: cash, card, bank_transfer.']
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  exception.userFriendlyMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('payment method'), findsOneWidget);
    });

    testWidgets('should display date format validation error', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'date': ['The date must be in YYYY-MM-DD format.']
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                exception.userFriendlyMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );

      expect(find.text('The date must be in YYYY-MM-DD format.'), findsOneWidget);
    });

    testWidgets('should display amount validation error', (tester) async {
      final exception = ValidationException(
        message: 'Validation failed',
        errors: {
          'amount': ['The amount must be greater than 0.', 'The amount must be a number.']
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  exception.userFriendlyMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('amount must be greater than 0'), findsOneWidget);
      expect(find.textContaining('amount must be a number'), findsOneWidget);
    });
  });
}
