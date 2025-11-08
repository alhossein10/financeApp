import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';
import 'package:finance_app/features/expenses/domain/entities/expense.dart';

void main() {

  group('ExpenseDto', () {
    test('should convert DTO to entity correctly', () {
      // Arrange
      final dto = ExpenseDto(
        id: 1,
        userId: 1,
        amount: 150.5,
        category: 'Food',
        description: 'Test expense',
        date: '2024-01-15',
        paymentMethod: 'cash',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      // Act
      final entity = dto.toEntity();

      // Assert
      expect(entity.id, 1);
      expect(entity.userId, 1);
      expect(entity.description, 'Test expense');
      expect(entity.priceUsd, 150.5); // Amount mapped to USD
      expect(entity.expenseDate.year, 2024);
      expect(entity.expenseDate.month, 1);
      expect(entity.expenseDate.day, 15);
    });

    test('should convert entity to DTO correctly', () {
      // Arrange
      final entity = Expense(
        id: 1,
        userId: 1,
        description: 'Test expense',
        priceUsd: 50.0,
        priceSyp: null,
        priceTry: null,
        invoiceStatus: InvoiceStatus.noInvoice,
        invoiceFilePath: null,
        expenseDate: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 15, 10, 0),
      );

      // Act
      final dto = ExpenseDto.fromEntity(entity);

      // Assert
      expect(dto.id, 1);
      expect(dto.userId, 1);
      expect(dto.amount, 50.0);
      expect(dto.category, 'USD');
      expect(dto.description, 'Test expense');
      expect(dto.date, '2024-01-15');
      expect(dto.paymentMethod, 'card'); // USD maps to card
    });

    test('should handle JSON serialization correctly', () {
      // Arrange
      final dto = ExpenseDto(
        id: 1,
        userId: 1,
        amount: 150.5,
        category: 'Food',
        description: 'Test expense',
        date: '2024-01-15',
        paymentMethod: 'cash',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      // Act
      final json = dto.toJson();

      // Assert - toJson only includes fields for API requests
      expect(json['amount'], 150.5);
      expect(json['category'], 'Food');
      expect(json['description'], 'Test expense');
      expect(json['date'], '2024-01-15');
      expect(json['payment_method'], 'cash');
    });

    test('should validate payment method', () {
      // Arrange
      final validDto = ExpenseDto(
        amount: 100.0,
        category: 'Food',
        date: '2024-01-15',
        paymentMethod: 'cash',
      );

      final invalidDto = ExpenseDto(
        amount: 100.0,
        category: 'Food',
        date: '2024-01-15',
        paymentMethod: 'invalid_method',
      );

      // Act & Assert
      expect(() => validDto.validate(), returnsNormally);
      expect(() => invalidDto.validate(), throwsArgumentError);
    });
  });

  group('ExpenseListResponse', () {
    test('should parse JSON response correctly', () {
      // Arrange
      final json = {
        'data': [
          {
            'id': 1,
            'user_id': 1,
            'amount': 150.5,
            'category': 'Food',
            'description': 'Expense 1',
            'date': '2024-01-15',
            'payment_method': 'cash',
            'created_at': '2024-01-15T10:00:00.000Z',
            'updated_at': '2024-01-15T10:00:00.000Z',
          },
          {
            'id': 2,
            'user_id': 1,
            'amount': 75.0,
            'category': 'Transport',
            'description': 'Expense 2',
            'date': '2024-01-16',
            'payment_method': 'card',
            'created_at': '2024-01-16T10:00:00.000Z',
            'updated_at': '2024-01-16T10:00:00.000Z',
          },
        ],
        'current_page': 1,
        'last_page': 1,
        'per_page': 10,
        'total': 2,
      };

      // Act
      final response = ExpenseListResponse.fromJson(json);

      // Assert
      expect(response.data.length, 2);
      expect(response.currentPage, 1);
      expect(response.lastPage, 1);
      expect(response.perPage, 10);
      expect(response.total, 2);
      expect(response.data[0].id, 1);
      expect(response.data[0].amount, 150.5);
      expect(response.data[0].category, 'Food');
      expect(response.data[1].id, 2);
      expect(response.data[1].amount, 75.0);
      expect(response.data[1].category, 'Transport');
    });

    test('should handle empty data list', () {
      // Arrange
      final json = {
        'data': [],
        'current_page': 1,
        'last_page': 1,
        'per_page': 10,
        'total': 0,
      };

      // Act
      final response = ExpenseListResponse.fromJson(json);

      // Assert
      expect(response.data.isEmpty, isTrue);
      expect(response.total, 0);
    });
  });
}
