import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';
import 'package:finance_app/features/incoming/data/models/incoming_dto.dart';

void main() {
  group('Payment Method Validation', () {
    group('ExpenseDto payment method validation', () {
      test('should accept valid payment methods', () {
        // Arrange
        final validMethods = ['cash', 'card', 'bank_transfer'];

        for (final method in validMethods) {
          final dto = ExpenseDto(
            amount: 100.0,
            category: 'Test',
            date: '2024-10-23',
            paymentMethod: method,
          );

          // Act & Assert
          expect(() => dto.validate(), returnsNormally,
              reason: 'Payment method "$method" should be valid');
        }
      });

      test('should reject invalid payment methods', () {
        // Arrange
        final invalidMethods = [
          'credit',
          'debit',
          'paypal',
          'crypto',
          'check',
          'wire',
          '',
          'CASH', // case sensitive
          'Card', // case sensitive
        ];

        for (final method in invalidMethods) {
          final dto = ExpenseDto(
            amount: 100.0,
            category: 'Test',
            date: '2024-10-23',
            paymentMethod: method,
          );

          // Act & Assert
          expect(() => dto.validate(), throwsArgumentError,
              reason: 'Payment method "$method" should be invalid');
        }
      });

      test('should validate payment method is case-sensitive', () {
        // Arrange
        final dto = ExpenseDto(
          amount: 100.0,
          category: 'Test',
          date: '2024-10-23',
          paymentMethod: 'CASH', // uppercase
        );

        // Act & Assert
        expect(() => dto.validate(), throwsArgumentError);
      });
    });

    group('IncomingDto payment method validation', () {
      test('should accept valid payment methods', () {
        // Arrange
        final validMethods = ['cash', 'card', 'bank_transfer'];

        for (final method in validMethods) {
          final dto = IncomingDto(
            amountUsd: 100.0,
            source: 'Test',
            date: '2024-10-23',
            paymentMethod: method,
          );

          // Act & Assert
          expect(() => dto.validate(), returnsNormally,
              reason: 'Payment method "$method" should be valid');
        }
      });

      test('should reject invalid payment methods', () {
        // Arrange
        final invalidMethods = [
          'credit',
          'debit',
          'paypal',
          'crypto',
          'check',
          'wire',
          '',
          'CASH', // case sensitive
        ];

        for (final method in invalidMethods) {
          final dto = IncomingDto(
            amountUsd: 100.0,
            source: 'Test',
            date: '2024-10-23',
            paymentMethod: method,
          );

          // Act & Assert
          expect(() => dto.validate(), throwsArgumentError,
              reason: 'Payment method "$method" should be invalid');
        }
      });

      test('should default to cash when payment method is not provided', () {
        // Arrange
        final json = {
          'amount_usd': 100.0,
          'source': 'Test',
          'date': '2024-10-23',
        };

        // Act
        final dto = IncomingDto.fromJson(json);

        // Assert
        expect(dto.paymentMethod, 'cash');
        expect(() => dto.validate(), returnsNormally);
      });
    });

    group('Payment method constants', () {
      test('should have correct valid payment methods list', () {
        // Assert
        expect(ExpenseDto.validPaymentMethods, ['cash', 'card', 'bank_transfer']);
        expect(IncomingDto.validPaymentMethods, ['cash', 'card', 'bank_transfer']);
      });

      test('should match API specification', () {
        // These are the only payment methods accepted by Laravel API
        final apiPaymentMethods = ['cash', 'card', 'bank_transfer'];
        
        expect(ExpenseDto.validPaymentMethods, apiPaymentMethods);
        expect(IncomingDto.validPaymentMethods, apiPaymentMethods);
      });
    });
  });

  group('Date Format Validation', () {
    group('DateFormatter.toApiDate', () {
      test('should format dates as YYYY-MM-DD', () {
        // Test cases with various dates
        final testCases = [
          (DateTime(2024, 1, 1), '2024-01-01'),
          (DateTime(2024, 12, 31), '2024-12-31'),
          (DateTime(2024, 10, 23), '2024-10-23'),
          (DateTime(2024, 1, 5), '2024-01-05'),
          (DateTime(2024, 11, 9), '2024-11-09'),
        ];

        for (final testCase in testCases) {
          final (date, expected) = testCase;
          
          // Act
          final formatted = DateFormatter.toApiDate(date);

          // Assert
          expect(formatted, expected,
              reason: 'Date ${date.toIso8601String()} should format to $expected');
        }
      });

      test('should pad single-digit months and days with zero', () {
        // Arrange
        final date = DateTime(2024, 1, 5);

        // Act
        final formatted = DateFormatter.toApiDate(date);

        // Assert
        expect(formatted, '2024-01-05');
        expect(formatted.length, 10); // YYYY-MM-DD is always 10 characters
      });

      test('should handle leap years correctly', () {
        // Arrange
        final leapDay = DateTime(2024, 2, 29);

        // Act
        final formatted = DateFormatter.toApiDate(leapDay);

        // Assert
        expect(formatted, '2024-02-29');
      });

      test('should handle year boundaries', () {
        // Test first and last day of year
        final firstDay = DateTime(2024, 1, 1);
        final lastDay = DateTime(2024, 12, 31);

        expect(DateFormatter.toApiDate(firstDay), '2024-01-01');
        expect(DateFormatter.toApiDate(lastDay), '2024-12-31');
      });
    });

    group('DateFormatter.fromApiDate', () {
      test('should parse YYYY-MM-DD dates correctly', () {
        // Test cases
        final testCases = [
          ('2024-01-01', DateTime(2024, 1, 1)),
          ('2024-12-31', DateTime(2024, 12, 31)),
          ('2024-10-23', DateTime(2024, 10, 23)),
          ('2024-02-29', DateTime(2024, 2, 29)), // leap year
        ];

        for (final testCase in testCases) {
          final (dateStr, expected) = testCase;
          
          // Act
          final parsed = DateFormatter.fromApiDate(dateStr);

          // Assert
          expect(parsed.year, expected.year);
          expect(parsed.month, expected.month);
          expect(parsed.day, expected.day);
        }
      });

      test('should handle ISO 8601 timestamps', () {
        // Arrange
        const timestamp = '2024-10-23T10:00:00.000000Z';

        // Act
        final parsed = DateFormatter.fromApiTimestamp(timestamp);

        // Assert
        expect(parsed.year, 2024);
        expect(parsed.month, 10);
        expect(parsed.day, 23);
        expect(parsed.hour, 10);
        expect(parsed.minute, 0);
      });
    });

    group('Date format round-trip', () {
      test('should maintain date integrity through format and parse', () {
        // Arrange
        final originalDate = DateTime(2024, 10, 23);

        // Act
        final formatted = DateFormatter.toApiDate(originalDate);
        final parsed = DateFormatter.fromApiDate(formatted);

        // Assert
        expect(parsed.year, originalDate.year);
        expect(parsed.month, originalDate.month);
        expect(parsed.day, originalDate.day);
      });

      test('should handle multiple round-trips', () {
        // Arrange
        final originalDate = DateTime(2024, 5, 15);

        // Act - multiple round trips
        var current = originalDate;
        for (var i = 0; i < 5; i++) {
          final formatted = DateFormatter.toApiDate(current);
          current = DateFormatter.fromApiDate(formatted);
        }

        // Assert
        expect(current.year, originalDate.year);
        expect(current.month, originalDate.month);
        expect(current.day, originalDate.day);
      });
    });

    group('Date validation in DTOs', () {
      test('should accept valid date formats in ExpenseDto', () {
        // Arrange
        final dto = ExpenseDto(
          amount: 100.0,
          category: 'Test',
          date: '2024-10-23',
          paymentMethod: 'cash',
        );

        // Act & Assert
        expect(() => dto.validate(), returnsNormally);
      });

      test('should accept valid date formats in IncomingDto', () {
        // Arrange
        final dto = IncomingDto(
          amountUsd: 100.0,
          source: 'Test',
          date: '2024-10-23',
          paymentMethod: 'cash',
        );

        // Act & Assert
        expect(() => dto.validate(), returnsNormally);
      });

      test('should use DateFormatter for date conversion', () {
        // Arrange
        final date = DateTime(2024, 10, 23);
        final formattedDate = DateFormatter.toApiDate(date);

        // Act
        final expenseDto = ExpenseDto(
          amount: 100.0,
          category: 'Test',
          date: formattedDate,
          paymentMethod: 'cash',
        );

        // Assert
        expect(expenseDto.date, '2024-10-23');
      });
    });

    group('Date range validation', () {
      test('should handle date ranges correctly', () {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 12, 31);

        // Act
        final formattedStart = DateFormatter.toApiDate(startDate);
        final formattedEnd = DateFormatter.toApiDate(endDate);

        // Assert
        expect(formattedStart, '2024-01-01');
        expect(formattedEnd, '2024-12-31');
        
        // Verify start is before end
        final parsedStart = DateFormatter.fromApiDate(formattedStart);
        final parsedEnd = DateFormatter.fromApiDate(formattedEnd);
        expect(parsedStart.isBefore(parsedEnd), true);
      });

      test('should handle same-day date ranges', () {
        // Arrange
        final date = DateTime(2024, 10, 23);

        // Act
        final formatted = DateFormatter.toApiDate(date);

        // Assert
        expect(formatted, '2024-10-23');
      });
    });
  });

  group('Combined Validation', () {
    test('should validate both payment method and date format in ExpenseDto', () {
      // Arrange
      final dto = ExpenseDto(
        amount: 100.0,
        category: 'Test',
        date: DateFormatter.toApiDate(DateTime(2024, 10, 23)),
        paymentMethod: 'card',
      );

      // Act & Assert
      expect(() => dto.validate(), returnsNormally);
      expect(dto.date, '2024-10-23');
      expect(dto.paymentMethod, 'card');
    });

    test('should validate both payment method and date format in IncomingDto', () {
      // Arrange
      final dto = IncomingDto(
        amountUsd: 100.0,
        source: 'Test',
        date: DateFormatter.toApiDate(DateTime(2024, 10, 23)),
        paymentMethod: 'bank_transfer',
      );

      // Act & Assert
      expect(() => dto.validate(), returnsNormally);
      expect(dto.date, '2024-10-23');
      expect(dto.paymentMethod, 'bank_transfer');
    });

    test('should fail validation with invalid payment method even with valid date', () {
      // Arrange
      final dto = ExpenseDto(
        amount: 100.0,
        category: 'Test',
        date: DateFormatter.toApiDate(DateTime(2024, 10, 23)),
        paymentMethod: 'invalid',
      );

      // Act & Assert
      expect(() => dto.validate(), throwsArgumentError);
    });
  });
}
