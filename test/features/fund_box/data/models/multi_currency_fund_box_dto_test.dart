import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/fund_box/data/models/fund_box_dto.dart';

void main() {
  group('FundBoxDto - Multi-Currency', () {
    test('should parse from JSON with all three currencies', () {
      // Arrange
      final json = {
        'id': 1,
        'user_id': 10,
        'balance_usd': 1000.0,
        'balance_syp': 15000000.0,
        'balance_try': 30000.0,
        'last_calculated_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = FundBoxDto.fromJson(json);

      // Assert
      expect(dto.id, 1);
      expect(dto.userId, 10);
      expect(dto.balanceUsd, 1000.0);
      expect(dto.balanceSyp, 15000000.0);
      expect(dto.balanceTry, 30000.0);
      expect(dto.lastCalculatedAt, '2024-11-16T10:00:00Z');
    });

    test('should handle zero balances', () {
      // Arrange
      final json = {
        'id': 2,
        'user_id': 20,
        'balance_usd': 0.0,
        'balance_syp': 0.0,
        'balance_try': 0.0,
        'last_calculated_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = FundBoxDto.fromJson(json);

      // Assert
      expect(dto.balanceUsd, 0.0);
      expect(dto.balanceSyp, 0.0);
      expect(dto.balanceTry, 0.0);
    });

    test('should handle null balances for currencies', () {
      // Arrange
      final json = {
        'id': 3,
        'user_id': 30,
        'balance_usd': 500.0,
        'balance_syp': null,
        'balance_try': null,
        'last_calculated_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = FundBoxDto.fromJson(json);

      // Assert
      expect(dto.balanceUsd, 500.0);
      expect(dto.balanceSyp, isNull);
      expect(dto.balanceTry, isNull);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = FundBoxDto(
        id: 4,
        userId: 40,
        balanceUsd: 2000.0,
        balanceSyp: 30000000.0,
        balanceTry: 60000.0,
        lastCalculatedAt: '2024-11-17T10:00:00Z',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['id'], 4);
      expect(json['user_id'], 40);
      expect(json['balance_usd'], 2000.0);
      expect(json['balance_syp'], 30000000.0);
      expect(json['balance_try'], 60000.0);
      expect(json['last_calculated_at'], '2024-11-17T10:00:00Z');
    });

    test('should handle large currency values', () {
      // Arrange
      final json = {
        'id': 5,
        'user_id': 50,
        'balance_usd': 999999.99,
        'balance_syp': 999999999999.99,
        'balance_try': 999999999.99,
        'last_calculated_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = FundBoxDto.fromJson(json);

      // Assert
      expect(dto.balanceUsd, 999999.99);
      expect(dto.balanceSyp, 999999999999.99);
      expect(dto.balanceTry, 999999999.99);
    });

    test('should handle negative balances (debt)', () {
      // Arrange
      final json = {
        'id': 6,
        'user_id': 60,
        'balance_usd': -100.0,
        'balance_syp': -1500000.0,
        'balance_try': -3000.0,
        'last_calculated_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = FundBoxDto.fromJson(json);

      // Assert
      expect(dto.balanceUsd, -100.0);
      expect(dto.balanceSyp, -1500000.0);
      expect(dto.balanceTry, -3000.0);
    });
  });
}
