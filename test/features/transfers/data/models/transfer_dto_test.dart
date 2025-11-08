import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';
import 'package:finance_app/features/transfers/domain/entities/transfer.dart';

void main() {
  group('TransferDto', () {
    group('fromJson', () {
      test('should correctly parse JSON response from API', () {
        // Arrange
        final json = {
          'id': 1,
          'user_id': 123,
          'recipient_name': 'abo momen',
          'amount_usd': 500.0,
          'transfer_date': '2024-10-23',
          'notes': 'Monthly transfer',
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = TransferDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.userId, 123);
        expect(dto.recipientName, 'abo momen');
        expect(dto.amountUsd, 500.0);
        expect(dto.transferDate, '2024-10-23');
        expect(dto.notes, 'Monthly transfer');
        expect(dto.createdAt, isNotNull);
        expect(dto.updatedAt, isNotNull);
      });

      test('should handle missing optional fields', () {
        // Arrange
        final json = {
          'recipient_name': 'abo momen',
          'amount_usd': 500.0,
          'transfer_date': '2024-10-23',
        };

        // Act
        final dto = TransferDto.fromJson(json);

        // Assert
        expect(dto.id, isNull);
        expect(dto.userId, isNull);
        expect(dto.notes, isNull);
        expect(dto.createdAt, isNull);
        expect(dto.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should correctly convert DTO to JSON for API request', () {
        // Arrange
        final dto = TransferDto(
          userId: 123,
          recipientName: 'abo momen',
          amountUsd: 500.0,
          transferDate: '2024-10-23',
          notes: 'Monthly transfer',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['user_id'], 123);
        expect(json['recipient_name'], 'abo momen');
        expect(json['amount_usd'], 500.0);
        expect(json['transfer_date'], '2024-10-23');
        expect(json['notes'], 'Monthly transfer');
      });

      test('should exclude null optional fields from JSON', () {
        // Arrange
        final dto = TransferDto(
          recipientName: 'abo momen',
          amountUsd: 500.0,
          transferDate: '2024-10-23',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json.containsKey('id'), false);
        expect(json.containsKey('user_id'), false);
        expect(json.containsKey('notes'), false);
      });
    });

    group('toEntity', () {
      test('should correctly convert DTO to domain entity', () {
        // Arrange
        final dto = TransferDto(
          id: 1,
          userId: 123,
          recipientName: 'abo momen',
          amountUsd: 500.0,
          transferDate: '2024-10-23',
          notes: 'Monthly transfer',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.userId, 123);
        expect(entity.amountUsd, 500.0);
        expect(entity.recipientName, 'abo momen');
        expect(entity.transactionDate.year, 2024);
        expect(entity.transactionDate.month, 10);
        expect(entity.transactionDate.day, 23);
      });
    });

    group('fromEntity', () {
      test('should correctly convert domain entity to DTO', () {
        // Arrange
        final entity = Transfer(
          id: 1,
          userId: 123,
          recipientName: 'abo momen',
          amountUsd: 500.0,
          transactionDate: DateTime(2024, 10, 23),
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = TransferDto.fromEntity(entity);

        // Assert
        expect(dto.id, 1);
        expect(dto.userId, 123);
        expect(dto.amountUsd, 500.0);
        expect(dto.recipientName, 'abo momen');
        expect(dto.transferDate, '2024-10-23');
      });
    });

    group('Date formatting', () {
      test('should use YYYY-MM-DD format for date field', () {
        // Arrange
        final dto = TransferDto(
          recipientName: 'abo momen',
          amountUsd: 500.0,
          transferDate: DateFormatter.toApiDate(DateTime(2024, 1, 5)),
        );

        // Assert
        expect(dto.transferDate, '2024-01-05');
      });
    });
  });
}
