import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin/data/models/analytics_dto.dart';

void main() {
  group('AnalyticsDto', () {
    test('should create AnalyticsDto from valid JSON', () {
      // Arrange
      final json = {
        'period': {
          'from': '2024-01-01',
          'to': '2024-12-31',
        },
        'expenses': {
          'total': 125000.50,
          'count': 5420,
          'average': 23.06,
        },
        'income': {
          'total': 450000.00,
          'count': 2100,
          'average': 214.29,
        },
        'net_balance': 325000.50,
        'trends': {
          'monthly': [
            {
              'month': '2024-01',
              'expenses': 10500.00,
              'income': 38000.00,
            },
          ],
        },
      };

      // Act
      final result = AnalyticsDto.fromJson(json);

      // Assert
      expect(result.period.from, '2024-01-01');
      expect(result.period.to, '2024-12-31');
      expect(result.expenses.total, 125000.50);
      expect(result.expenses.count, 5420);
      expect(result.expenses.average, 23.06);
      expect(result.income.total, 450000.00);
      expect(result.income.count, 2100);
      expect(result.income.average, 214.29);
      expect(result.netBalance, 325000.50);
      expect(result.trends.monthly.length, 1);
      expect(result.trends.monthly[0].month, '2024-01');
    });

    test('should convert AnalyticsDto to JSON', () {
      // Arrange
      const dto = AnalyticsDto(
        period: DatePeriod(from: '2024-01-01', to: '2024-12-31'),
        expenses: ExpenseAnalytics(total: 125000.50, count: 5420, average: 23.06),
        income: IncomeAnalytics(total: 450000.00, count: 2100, average: 214.29),
        netBalance: 325000.50,
        trends: TrendsData(
          monthly: [
            MonthlyTrend(month: '2024-01', expenses: 10500.00, income: 38000.00),
          ],
        ),
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['period']['from'], '2024-01-01');
      expect(json['expenses']['total'], 125000.50);
      expect(json['income']['total'], 450000.00);
      expect(json['net_balance'], 325000.50);
      expect(json['trends']['monthly'], isA<List>());
    });
  });

  group('DatePeriod', () {
    test('should create DatePeriod from valid JSON', () {
      // Arrange
      final json = {
        'from': '2024-01-01',
        'to': '2024-12-31',
      };

      // Act
      final result = DatePeriod.fromJson(json);

      // Assert
      expect(result.from, '2024-01-01');
      expect(result.to, '2024-12-31');
    });
  });

  group('ExpenseAnalytics', () {
    test('should create ExpenseAnalytics from valid JSON', () {
      // Arrange
      final json = {
        'total': 125000.50,
        'count': 5420,
        'average': 23.06,
      };

      // Act
      final result = ExpenseAnalytics.fromJson(json);

      // Assert
      expect(result.total, 125000.50);
      expect(result.count, 5420);
      expect(result.average, 23.06);
    });
  });

  group('IncomeAnalytics', () {
    test('should create IncomeAnalytics from valid JSON', () {
      // Arrange
      final json = {
        'total': 450000.00,
        'count': 2100,
        'average': 214.29,
      };

      // Act
      final result = IncomeAnalytics.fromJson(json);

      // Assert
      expect(result.total, 450000.00);
      expect(result.count, 2100);
      expect(result.average, 214.29);
    });
  });

  group('MonthlyTrend', () {
    test('should create MonthlyTrend from valid JSON', () {
      // Arrange
      final json = {
        'month': '2024-01',
        'expenses': 10500.00,
        'income': 38000.00,
      };

      // Act
      final result = MonthlyTrend.fromJson(json);

      // Assert
      expect(result.month, '2024-01');
      expect(result.expenses, 10500.00);
      expect(result.income, 38000.00);
    });
  });
}
