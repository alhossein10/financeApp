import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin/data/models/expense_summary_dto.dart';

void main() {
  group('ExpenseSummaryDto', () {
    test('should create ExpenseSummaryDto from valid JSON', () {
      // Arrange
      final json = {
        'by_category': [
          {
            'category': 'Food',
            'total': 45000.00,
            'count': 320,
          },
          {
            'category': 'Transport',
            'total': 25000.00,
            'count': 180,
          },
        ],
        'by_payment_method': [
          {
            'payment_method': 'cash',
            'total': 35000.00,
          },
          {
            'payment_method': 'card',
            'total': 90000.50,
          },
        ],
      };

      // Act
      final result = ExpenseSummaryDto.fromJson(json);

      // Assert
      expect(result.byCategory.length, 2);
      expect(result.byCategory[0].category, 'Food');
      expect(result.byCategory[0].total, 45000.00);
      expect(result.byCategory[0].count, 320);
      
      expect(result.byPaymentMethod.length, 2);
      expect(result.byPaymentMethod[0].paymentMethod, 'cash');
      expect(result.byPaymentMethod[0].total, 35000.00);
    });

    test('should handle empty arrays', () {
      // Arrange
      final json = {
        'by_category': [],
        'by_payment_method': [],
      };

      // Act
      final result = ExpenseSummaryDto.fromJson(json);

      // Assert
      expect(result.byCategory, isEmpty);
      expect(result.byPaymentMethod, isEmpty);
    });

    test('should convert ExpenseSummaryDto to JSON', () {
      // Arrange
      const dto = ExpenseSummaryDto(
        byCategory: [
          CategorySummary(category: 'Food', total: 45000.00, count: 320),
        ],
        byPaymentMethod: [
          PaymentMethodSummary(paymentMethod: 'cash', total: 35000.00),
        ],
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['by_category'], isA<List>());
      expect(json['by_category'][0]['category'], 'Food');
      expect(json['by_payment_method'], isA<List>());
      expect(json['by_payment_method'][0]['payment_method'], 'cash');
    });
  });

  group('CategorySummary', () {
    test('should create CategorySummary from valid JSON', () {
      // Arrange
      final json = {
        'category': 'Food',
        'total': 45000.00,
        'count': 320,
      };

      // Act
      final result = CategorySummary.fromJson(json);

      // Assert
      expect(result.category, 'Food');
      expect(result.total, 45000.00);
      expect(result.count, 320);
    });
  });

  group('PaymentMethodSummary', () {
    test('should create PaymentMethodSummary from valid JSON', () {
      // Arrange
      final json = {
        'payment_method': 'cash',
        'total': 35000.00,
      };

      // Act
      final result = PaymentMethodSummary.fromJson(json);

      // Assert
      expect(result.paymentMethod, 'cash');
      expect(result.total, 35000.00);
    });
  });
}
