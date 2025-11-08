import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:finance_app/features/incoming/data/models/incoming_dto.dart';
import 'package:finance_app/features/incoming/domain/entities/incoming.dart';

void main() {
  group('IncomingDto', () {
    group('fromJson', () {
      test('should correctly parse JSON response from API', () {
        // Arrange
        final json = {
          'id': 1,
          'user_id': 123,
          'amount_usd': 5000.0,
          'source': 'Salary',
          'description': 'Monthly salary',
          'date': '2024-10-23',
          'payment_method': 'bank_transfer',
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = IncomingDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.userId, 123);
        expect(dto.amountUsd, 5000.0);
        expect(dto.source, 'Salary');
        expect(dto.description, 'Monthly salary');
        expect(dto.date, '2024-10-23');
        expect(dto.paymentMethod, 'bank_transfer');
        expect(dto.createdAt, isNotNull);
        expect(dto.updatedAt, isNotNull);
      });

      test('should handle missing optional fields', () {
        // Arrange
        final json = {
          'amount_usd': 5000.0,
          'source': 'Salary',
          'date': '2024-10-23',
          'payment_method': 'cash',
        };

        // Act
        final dto = IncomingDto.fromJson(json);

        // Assert
        expect(dto.id, isNull);
        expect(dto.userId, isNull);
        expect(dto.description, isNull);
        expect(dto.createdAt, isNull);
        expect(dto.updatedAt, isNull);
      });

      test('should default to cash payment method if missing', () {
        // Arrange
        final json = {
          'amount_usd': 5000.0,
          'source': 'Salary',
          'date': '2024-10-23',
        };

        // Act
        final dto = IncomingDto.fromJson(json);

        // Assert
        expect(dto.paymentMethod, 'cash');
      });
    });

    group('toJson', () {
      test('should correctly convert DTO to JSON for API request', () {
        // Arrange
        final dto = IncomingDto(
          userId: 123,
          amountUsd: 5000.0,
          source: 'Salary',
          description: 'Monthly salary',
          date: '2024-10-23',
          paymentMethod: 'bank_transfer',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['amount_usd'], 5000.0);
        expect(json['source'], 'Salary');
        expect(json['description'], 'Monthly salary');
        expect(json['date'], '2024-10-23');
        expect(json['payment_method'], 'bank_transfer');
        // user_id should not be in request body
        expect(json.containsKey('user_id'), false);
        expect(json.containsKey('id'), false);
      });

      test('should exclude null description from JSON', () {
        // Arrange
        final dto = IncomingDto(
          amountUsd: 5000.0,
          source: 'Salary',
          date: '2024-10-23',
          paymentMethod: 'cash',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json.containsKey('description'), false);
      });
    });

    group('validate', () {
      test('should not throw for valid payment methods', () {
        // Arrange
        final validMethods = ['cash', 'card', 'bank_transfer'];

        for (final method in validMethods) {
          final dto = IncomingDto(
            amountUsd: 5000.0,
            source: 'Salary',
            date: '2024-10-23',
            paymentMethod: method,
          );

          // Act & Assert
          expect(() => dto.validate(), returnsNormally);
        }
      });

      test('should throw for invalid payment method', () {
        // Arrange
        final dto = IncomingDto(
          amountUsd: 5000.0,
          source: 'Salary',
          date: '2024-10-23',
          paymentMethod: 'invalid_method',
        );

        // Act & Assert
        expect(() => dto.validate(), throwsArgumentError);
      });
    });

    group('toEntity', () {
      test('should correctly convert DTO to domain entity', () {
        // Arrange
        final dto = IncomingDto(
          id: 1,
          userId: 123,
          amountUsd: 5000.0,
          source: 'Salary',
          description: 'Monthly salary',
          date: '2024-10-23',
          paymentMethod: 'bank_transfer',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.userId, 123);
        expect(entity.amountUsd, 5000.0);
        expect(entity.description, 'Monthly salary');
        expect(entity.transactionDate.year, 2024);
        expect(entity.transactionDate.month, 10);
        expect(entity.transactionDate.day, 23);
      });

      test('should handle null description', () {
        // Arrange
        final dto = IncomingDto(
          id: 1,
          userId: 123,
          amountUsd: 5000.0,
          source: 'Salary',
          date: '2024-10-23',
          paymentMethod: 'cash',
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.description, '');
      });
    });

    group('fromEntity', () {
      test('should correctly convert domain entity to DTO', () {
        // Arrange
        final entity = Incoming(
          id: 1,
          userId: 123,
          description: 'Monthly salary',
          amountUsd: 5000.0,
          transactionDate: DateTime(2024, 10, 23),
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = IncomingDto.fromEntity(entity, paymentMethod: 'bank_transfer');

        // Assert
        expect(dto.id, 1);
        expect(dto.userId, 123);
        expect(dto.amountUsd, 5000.0);
        expect(dto.source, 'Monthly salary');
        expect(dto.description, 'Monthly salary');
        expect(dto.date, '2024-10-23');
        expect(dto.paymentMethod, 'bank_transfer');
      });

      test('should default to cash payment method if not provided', () {
        // Arrange
        final entity = Incoming(
          id: 1,
          userId: 123,
          description: 'Monthly salary',
          amountUsd: 5000.0,
          transactionDate: DateTime(2024, 10, 23),
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = IncomingDto.fromEntity(entity);

        // Assert
        expect(dto.paymentMethod, 'cash');
      });
    });

    group('Date formatting', () {
      test('should use YYYY-MM-DD format for date field', () {
        // Arrange
        final dto = IncomingDto(
          amountUsd: 5000.0,
          source: 'Salary',
          date: DateFormatter.toApiDate(DateTime(2024, 1, 5)),
          paymentMethod: 'cash',
        );

        // Assert
        expect(dto.date, '2024-01-05');
      });
    });

    group('IncomingListResponse', () {
      test('should correctly parse paginated response', () {
        // Arrange
        final json = {
          'data': [
            {
              'id': 1,
              'amount_usd': 5000.0,
              'source': 'Salary',
              'date': '2024-10-23',
              'payment_method': 'bank_transfer',
            },
            {
              'id': 2,
              'amount_usd': 1000.0,
              'source': 'Freelance',
              'date': '2024-10-24',
              'payment_method': 'cash',
            },
          ],
          'current_page': 1,
          'last_page': 3,
          'per_page': 15,
          'total': 45,
        };

        // Act
        final response = IncomingListResponse.fromJson(json);

        // Assert
        expect(response.data.length, 2);
        expect(response.currentPage, 1);
        expect(response.lastPage, 3);
        expect(response.perPage, 15);
        expect(response.total, 45);
        expect(response.hasMorePages, true);
      });

      test('should indicate no more pages when on last page', () {
        // Arrange
        final json = {
          'data': [],
          'current_page': 3,
          'last_page': 3,
          'per_page': 15,
          'total': 45,
        };

        // Act
        final response = IncomingListResponse.fromJson(json);

        // Assert
        expect(response.hasMorePages, false);
      });
    });
  });
}
