import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';

void main() {
  group('ExpenseDto - Multi-Currency', () {
    test('should parse from JSON with USD only', () {
      // Arrange
      final json = {
        'id': 1,
        'user_id': 10,
        'description': 'Test expense',
        'price_usd': 100.0,
        'price_syp': null,
        'price_try': null,
        'expense_date': '2024-11-16',
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = ExpenseDto.fromJson(json);

      // Assert
      expect(dto.priceUsd, 100.0);
      expect(dto.priceSyp, isNull);
      expect(dto.priceTry, isNull);
    });

    test('should parse from JSON with SYP only', () {
      // Arrange
      final json = {
        'id': 2,
        'user_id': 10,
        'description': 'SYP expense',
        'price_usd': null,
        'price_syp': 1500000.0,
        'price_try': null,
        'expense_date': '2024-11-16',
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = ExpenseDto.fromJson(json);

      // Assert
      expect(dto.priceUsd, isNull);
      expect(dto.priceSyp, 1500000.0);
      expect(dto.priceTry, isNull);
    });

    test('should parse from JSON with TRY only', () {
      // Arrange
      final json = {
        'id': 3,
        'user_id': 10,
        'description': 'TRY expense',
        'price_usd': null,
        'price_syp': null,
        'price_try': 3000.0,
        'expense_date': '2024-11-16',
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = ExpenseDto.fromJson(json);

      // Assert
      expect(dto.priceUsd, isNull);
      expect(dto.priceSyp, isNull);
      expect(dto.priceTry, 3000.0);
    });

    test('should parse from JSON with multiple currencies', () {
      // Arrange
      final json = {
        'id': 4,
        'user_id': 10,
        'description': 'Multi-currency expense',
        'price_usd': 50.0,
        'price_syp': 750000.0,
        'price_try': 1500.0,
        'expense_date': '2024-11-16',
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = ExpenseDto.fromJson(json);

      // Assert
      expect(dto.priceUsd, 50.0);
      expect(dto.priceSyp, 750000.0);
      expect(dto.priceTry, 1500.0);
    });

    test('should serialize to JSON with USD only', () {
      // Arrange
      final dto = ExpenseDto(
        id: 5,
        userId: 20,
        description: 'USD expense',
        priceUsd: 200.0,
        expenseDate: '2024-11-17',
        createdAt: '2024-11-17T10:00:00Z',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['price_usd'], 200.0);
      expect(json.containsKey('price_syp'), true);
      expect(json['price_syp'], isNull);
      expect(json.containsKey('price_try'), true);
      expect(json['price_try'], isNull);
    });

    test('should serialize to JSON with all currencies', () {
      // Arrange
      final dto = ExpenseDto(
        id: 6,
        userId: 30,
        description: 'All currencies',
        priceUsd: 100.0,
        priceSyp: 1500000.0,
        priceTry: 3000.0,
        expenseDate: '2024-11-17',
        createdAt: '2024-11-17T10:00:00Z',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['price_usd'], 100.0);
      expect(json['price_syp'], 1500000.0);
      expect(json['price_try'], 3000.0);
    });

    test('should handle zero values', () {
      // Arrange
      final json = {
        'id': 7,
        'user_id': 40,
        'description': 'Zero expense',
        'price_usd': 0.0,
        'price_syp': 0.0,
        'price_try': 0.0,
        'expense_date': '2024-11-16',
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = ExpenseDto.fromJson(json);

      // Assert
      expect(dto.priceUsd, 0.0);
      expect(dto.priceSyp, 0.0);
      expect(dto.priceTry, 0.0);
    });

    test('should handle decimal values correctly', () {
      // Arrange
      final json = {
        'id': 8,
        'user_id': 50,
        'description': 'Decimal expense',
        'price_usd': 99.99,
        'price_syp': 1499999.99,
        'price_try': 2999.99,
        'expense_date': '2024-11-16',
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = ExpenseDto.fromJson(json);

      // Assert
      expect(dto.priceUsd, 99.99);
      expect(dto.priceSyp, 1499999.99);
      expect(dto.priceTry, 2999.99);
    });
  });
}
