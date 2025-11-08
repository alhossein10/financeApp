import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    group('toApiDate', () {
      test('should format date to YYYY-MM-DD', () {
        final date = DateTime(2024, 10, 23);
        expect(DateFormatter.toApiDate(date), '2024-10-23');
      });

      test('should pad single digit month and day with zeros', () {
        final date = DateTime(2024, 1, 5);
        expect(DateFormatter.toApiDate(date), '2024-01-05');
      });

      test('should ignore time component', () {
        final date = DateTime(2024, 10, 23, 14, 30, 45);
        expect(DateFormatter.toApiDate(date), '2024-10-23');
      });

      test('should handle leap year dates', () {
        final date = DateTime(2024, 2, 29);
        expect(DateFormatter.toApiDate(date), '2024-02-29');
      });

      test('should handle year boundaries', () {
        final date = DateTime(2024, 12, 31);
        expect(DateFormatter.toApiDate(date), '2024-12-31');
      });
    });

    group('toApiTimestamp', () {
      test('should format timestamp to ISO 8601 with UTC', () {
        final dateTime = DateTime.utc(2024, 10, 23, 10, 30, 0);
        final result = DateFormatter.toApiTimestamp(dateTime);
        expect(result, '2024-10-23T10:30:00.000Z');
      });

      test('should convert local time to UTC', () {
        final localTime = DateTime(2024, 10, 23, 10, 30, 0);
        final result = DateFormatter.toApiTimestamp(localTime);
        // Result should be in UTC (Z suffix)
        expect(result.endsWith('Z'), true);
        expect(result.contains('T'), true);
      });

      test('should include milliseconds', () {
        final dateTime = DateTime.utc(2024, 10, 23, 10, 30, 0, 500);
        final result = DateFormatter.toApiTimestamp(dateTime);
        expect(result.contains('.'), true);
      });
    });

    group('fromApiDate', () {
      test('should parse YYYY-MM-DD format', () {
        final result = DateFormatter.fromApiDate('2024-10-23');
        expect(result.year, 2024);
        expect(result.month, 10);
        expect(result.day, 23);
      });

      test('should set time to midnight', () {
        final result = DateFormatter.fromApiDate('2024-10-23');
        expect(result.hour, 0);
        expect(result.minute, 0);
        expect(result.second, 0);
      });

      test('should throw FormatException for invalid format', () {
        expect(
          () => DateFormatter.fromApiDate('23-10-2024'),
          throwsFormatException,
        );
      });

      test('should throw FormatException for empty string', () {
        expect(
          () => DateFormatter.fromApiDate(''),
          throwsFormatException,
        );
      });

      test('should throw FormatException for invalid date', () {
        expect(
          () => DateFormatter.fromApiDate('2024-13-01'),
          throwsFormatException,
        );
      });
    });

    group('fromApiTimestamp', () {
      test('should parse ISO 8601 timestamp', () {
        final result = DateFormatter.fromApiTimestamp('2024-10-23T10:30:00.000Z');
        expect(result.year, 2024);
        expect(result.month, 10);
        expect(result.day, 23);
      });

      test('should convert UTC to local time', () {
        final result = DateFormatter.fromApiTimestamp('2024-10-23T10:30:00.000Z');
        // Result should be in local timezone
        expect(result.isUtc, false);
      });

      test('should handle timestamp without milliseconds', () {
        final result = DateFormatter.fromApiTimestamp('2024-10-23T10:30:00Z');
        expect(result.year, 2024);
        expect(result.month, 10);
        expect(result.day, 23);
      });

      test('should throw FormatException for invalid format', () {
        expect(
          () => DateFormatter.fromApiTimestamp('invalid'),
          throwsFormatException,
        );
      });

      test('should throw FormatException for empty string', () {
        expect(
          () => DateFormatter.fromApiTimestamp(''),
          throwsFormatException,
        );
      });
    });

    group('isValidApiDate', () {
      test('should return true for valid YYYY-MM-DD format', () {
        expect(DateFormatter.isValidApiDate('2024-10-23'), true);
      });

      test('should return false for invalid format', () {
        expect(DateFormatter.isValidApiDate('23-10-2024'), false);
        expect(DateFormatter.isValidApiDate('2024/10/23'), false);
        expect(DateFormatter.isValidApiDate('10-23-2024'), false);
      });

      test('should return false for invalid date', () {
        expect(DateFormatter.isValidApiDate('2024-13-01'), false);
        expect(DateFormatter.isValidApiDate('2024-02-30'), false);
      });

      test('should return false for empty string', () {
        expect(DateFormatter.isValidApiDate(''), false);
      });
    });

    group('isValidApiTimestamp', () {
      test('should return true for valid ISO 8601 timestamp', () {
        expect(DateFormatter.isValidApiTimestamp('2024-10-23T10:30:00.000Z'), true);
        expect(DateFormatter.isValidApiTimestamp('2024-10-23T10:30:00Z'), true);
      });

      test('should return true for date-only ISO 8601', () {
        expect(DateFormatter.isValidApiTimestamp('2024-10-23'), true);
      });

      test('should return false for invalid format', () {
        expect(DateFormatter.isValidApiTimestamp('invalid'), false);
        expect(DateFormatter.isValidApiTimestamp(''), false);
      });
    });

    group('nullable conversions', () {
      test('fromApiDateNullable should return null for null input', () {
        expect(DateFormatter.fromApiDateNullable(null), null);
      });

      test('fromApiDateNullable should return null for empty string', () {
        expect(DateFormatter.fromApiDateNullable(''), null);
      });

      test('fromApiDateNullable should parse valid date', () {
        final result = DateFormatter.fromApiDateNullable('2024-10-23');
        expect(result, isNotNull);
        expect(result!.year, 2024);
      });

      test('fromApiTimestampNullable should return null for null input', () {
        expect(DateFormatter.fromApiTimestampNullable(null), null);
      });

      test('fromApiTimestampNullable should parse valid timestamp', () {
        final result = DateFormatter.fromApiTimestampNullable('2024-10-23T10:30:00Z');
        expect(result, isNotNull);
        expect(result!.year, 2024);
      });

      test('toApiDateNullable should return null for null input', () {
        expect(DateFormatter.toApiDateNullable(null), null);
      });

      test('toApiDateNullable should format valid date', () {
        final date = DateTime(2024, 10, 23);
        expect(DateFormatter.toApiDateNullable(date), '2024-10-23');
      });

      test('toApiTimestampNullable should return null for null input', () {
        expect(DateFormatter.toApiTimestampNullable(null), null);
      });

      test('toApiTimestampNullable should format valid timestamp', () {
        final dateTime = DateTime.utc(2024, 10, 23, 10, 30);
        final result = DateFormatter.toApiTimestampNullable(dateTime);
        expect(result, isNotNull);
        expect(result!.contains('2024-10-23'), true);
      });
    });

    group('convenience methods', () {
      test('todayApiDate should return current date in YYYY-MM-DD', () {
        final result = DateFormatter.todayApiDate();
        expect(DateFormatter.isValidApiDate(result), true);
      });

      test('nowApiTimestamp should return current timestamp in ISO 8601', () {
        final result = DateFormatter.nowApiTimestamp();
        expect(DateFormatter.isValidApiTimestamp(result), true);
      });

      test('formatDateRange should return map with date_from and date_to', () {
        final from = DateTime(2024, 10, 1);
        final to = DateTime(2024, 10, 31);
        final result = DateFormatter.formatDateRange(from, to);
        
        expect(result['date_from'], '2024-10-01');
        expect(result['date_to'], '2024-10-31');
      });
    });

    group('timezone handling', () {
      test('should handle different timezones consistently', () {
        // Create same moment in different timezones
        final utcTime = DateTime.utc(2024, 10, 23, 12, 0, 0);
        final localTime = utcTime.toLocal();
        
        // Both should produce same UTC timestamp
        final utcResult = DateFormatter.toApiTimestamp(utcTime);
        final localResult = DateFormatter.toApiTimestamp(localTime);
        
        expect(utcResult, localResult);
      });

      test('should preserve date when converting timezones', () {
        final date = DateTime(2024, 10, 23, 23, 59, 59);
        final apiDate = DateFormatter.toApiDate(date);
        
        expect(apiDate, '2024-10-23');
      });

      test('round trip conversion should preserve date', () {
        final original = DateTime(2024, 10, 23);
        final apiDate = DateFormatter.toApiDate(original);
        final parsed = DateFormatter.fromApiDate(apiDate);
        
        expect(parsed.year, original.year);
        expect(parsed.month, original.month);
        expect(parsed.day, original.day);
      });

      test('round trip timestamp conversion should preserve time', () {
        final original = DateTime.utc(2024, 10, 23, 10, 30, 0);
        final apiTimestamp = DateFormatter.toApiTimestamp(original);
        final parsed = DateFormatter.fromApiTimestamp(apiTimestamp);
        
        // Convert back to UTC for comparison
        final parsedUtc = parsed.toUtc();
        
        expect(parsedUtc.year, original.year);
        expect(parsedUtc.month, original.month);
        expect(parsedUtc.day, original.day);
        expect(parsedUtc.hour, original.hour);
        expect(parsedUtc.minute, original.minute);
      });
    });
  });
}
