import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/exchanges/data/models/exchange_dto.dart';

void main() {
  group('ExchangeDto', () {
    test('should parse from JSON with all fields', () {
      // Arrange
      final json = {
        'id': 1,
        'transfer_id': 5,
        'target_currency': 'SYP',
        'amount_usd': 100.0,
        'exchange_rate': 15000.0,
        'converted_amount': 1500000.0,
        'exchange_date': '2024-11-16',
        'notes': 'Test exchange',
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = ExchangeDto.fromJson(json);

      // Assert
      expect(dto.id, 1);
      expect(dto.transferId, 5);
      expect(dto.targetCurrency, 'SYP');
      expect(dto.amountUsd, 100.0);
      expect(dto.exchangeRate, 15000.0);
      expect(dto.convertedAmount, 1500000.0);
      expect(dto.exchangeDate, '2024-11-16');
      expect(dto.notes, 'Test exchange');
      expect(dto.createdAt, '2024-11-16T10:00:00Z');
    });

    test('should parse from JSON without optional fields', () {
      // Arrange
      final json = {
        'id': 2,
        'target_currency': 'TRY',
        'amount_usd': 200.0,
        'exchange_rate': 30.0,
        'converted_amount': 6000.0,
        'exchange_date': '2024-11-16',
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = ExchangeDto.fromJson(json);

      // Assert
      expect(dto.id, 2);
      expect(dto.transferId, isNull);
      expect(dto.notes, isNull);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = ExchangeDto(
        id: 3,
        transferId: 10,
        targetCurrency: 'SYP',
        amountUsd: 150.0,
        exchangeRate: 15500.0,
        convertedAmount: 2325000.0,
        exchangeDate: '2024-11-17',
        notes: 'Another test',
        createdAt: '2024-11-17T10:00:00Z',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['id'], 3);
      expect(json['transfer_id'], 10);
      expect(json['target_currency'], 'SYP');
      expect(json['amount_usd'], 150.0);
      expect(json['exchange_rate'], 15500.0);
      expect(json['converted_amount'], 2325000.0);
      expect(json['exchange_date'], '2024-11-17');
      expect(json['notes'], 'Another test');
      expect(json['created_at'], '2024-11-17T10:00:00Z');
    });

    test('should handle null optional fields in toJson', () {
      // Arrange
      final dto = ExchangeDto(
        id: 4,
        targetCurrency: 'TRY',
        amountUsd: 100.0,
        exchangeRate: 30.0,
        convertedAmount: 3000.0,
        exchangeDate: '2024-11-16',
        createdAt: '2024-11-16T10:00:00Z',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json.containsKey('transfer_id'), true);
      expect(json['transfer_id'], isNull);
      expect(json.containsKey('notes'), true);
      expect(json['notes'], isNull);
    });
  });

  group('TransferBalanceInfoDto', () {
    test('should parse from JSON correctly', () {
      // Arrange
      final json = {
        'transfer_id': 5,
        'original_amount': 1000.0,
        'exchanged_amount': 300.0,
        'remaining_amount': 700.0,
      };

      // Act
      final dto = TransferBalanceInfoDto.fromJson(json);

      // Assert
      expect(dto.transferId, 5);
      expect(dto.originalAmount, 1000.0);
      expect(dto.exchangedAmount, 300.0);
      expect(dto.remainingAmount, 700.0);
    });

    test('should handle zero exchanged amount', () {
      // Arrange
      final json = {
        'transfer_id': 6,
        'original_amount': 500.0,
        'exchanged_amount': 0.0,
        'remaining_amount': 500.0,
      };

      // Act
      final dto = TransferBalanceInfoDto.fromJson(json);

      // Assert
      expect(dto.exchangedAmount, 0.0);
      expect(dto.remainingAmount, 500.0);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = TransferBalanceInfoDto(
        transferId: 7,
        originalAmount: 2000.0,
        exchangedAmount: 1500.0,
        remainingAmount: 500.0,
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['transfer_id'], 7);
      expect(json['original_amount'], 2000.0);
      expect(json['exchanged_amount'], 1500.0);
      expect(json['remaining_amount'], 500.0);
    });
  });
}
