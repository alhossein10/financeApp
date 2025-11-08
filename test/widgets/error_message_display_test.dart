import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_exception.dart';

void main() {
  group('Error Message Display Tests', () {
    testWidgets('should display 401 unauthorized error message', (tester) async {
      final exception = UnauthorizedException();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    exception.userFriendlyMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Session expired. Please login again.'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('should display 403 forbidden error message', (tester) async {
      final exception = ForbiddenException();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    exception.userFriendlyMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Access denied. You don\'t have permission for this action.'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('should display 404 not found error message', (tester) async {
      final exception = NotFoundException();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.orange),
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

      expect(find.text('Resource not found.'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('should display 429 rate limit error message', (tester) async {
      final exception = RateLimitException();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_off, size: 64, color: Colors.orange),
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

      expect(find.textContaining('Too many requests'), findsOneWidget);
      expect(find.byIcon(Icons.timer_off), findsOneWidget);
    });

    testWidgets('should display 500 server error message', (tester) async {
      final exception = ServerException(statusCode: 500);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    exception.userFriendlyMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Internal server error. Please try again later.'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('should display network error message', (tester) async {
      final exception = NoInternetException();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
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

      expect(find.text('No internet connection. Please check your network.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('should display connection timeout error message', (tester) async {
      final exception = ConnectionTimeoutException();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    exception.message,
                    style: const TextStyle(color: Colors.orange, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Connection timeout. Please check your internet connection.'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('should display error in snackbar', (tester) async {
      final exception = BadRequestException(message: 'Invalid input data');
      
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
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    child: const Text('Show Error'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid request. Please check your input.'), findsOneWidget);
    });

    testWidgets('should display error in dialog', (tester) async {
      final exception = ServerException(statusCode: 503);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: Text(exception.userFriendlyMessage),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Show Error'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Service unavailable. Please try again later.'), findsOneWidget);
    });

    testWidgets('should display retry button with error', (tester) async {
      final exception = NoInternetException();
      bool retryTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    exception.userFriendlyMessage,
                    style: const TextStyle(color: Colors.orange, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => retryTapped = true,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      
      await tester.tap(find.text('Retry'));
      expect(retryTapped, isTrue);
    });

    testWidgets('should display custom error message', (tester) async {
      final exception = ApiException(
        statusCode: 418,
        message: 'I\'m a teapot',
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

      expect(find.text('I\'m a teapot'), findsOneWidget);
    });

    testWidgets('should display error with icon based on error type', (tester) async {
      final errors = [
        (UnauthorizedException(), Icons.lock_outline),
        (ForbiddenException(), Icons.block),
        (NotFoundException(), Icons.search_off),
        (ServerException(statusCode: 500), Icons.cloud_off),
        (NoInternetException(), Icons.wifi_off),
      ];

      for (final (exception, expectedIcon) in errors) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(expectedIcon, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(exception.userFriendlyMessage),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.byIcon(expectedIcon), findsOneWidget);
        
        await tester.pumpWidget(Container()); // Clear widget tree
      }
    });
  });
}
