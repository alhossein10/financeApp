import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin/data/models/admin_stats_dto.dart';

void main() {
  group('AdminStatsDto', () {
    test('should create AdminStatsDto from valid JSON', () {
      // Arrange
      final json = {
        'total_users': 150,
        'total_expenses': 5420,
        'total_income': 2100,
        'total_transfers': 890,
        'total_amount_expenses': 125000.50,
        'total_amount_income': 450000.00,
        'fund_box_balance': 10000.00,
      };

      // Act
      final result = AdminStatsDto.fromJson(json);

      // Assert
      expect(result.totalUsers, 150);
      expect(result.totalExpenses, 5420);
      expect(result.totalIncome, 2100);
      expect(result.totalTransfers, 890);
      expect(result.totalAmountExpenses, 125000.50);
      expect(result.totalAmountIncome, 450000.00);
      expect(result.fundBoxBalance, 10000.00);
    });

    test('should handle null values with defaults', () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final result = AdminStatsDto.fromJson(json);

      // Assert
      expect(result.totalUsers, 0);
      expect(result.totalExpenses, 0);
      expect(result.totalIncome, 0);
      expect(result.totalTransfers, 0);
      expect(result.totalAmountExpenses, 0.0);
      expect(result.totalAmountIncome, 0.0);
      expect(result.fundBoxBalance, 0.0);
    });

    test('should convert AdminStatsDto to JSON', () {
      // Arrange
      const dto = AdminStatsDto(
        totalUsers: 150,
        totalExpenses: 5420,
        totalIncome: 2100,
        totalTransfers: 890,
        totalAmountExpenses: 125000.50,
        totalAmountIncome: 450000.00,
        fundBoxBalance: 10000.00,
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['total_users'], 150);
      expect(json['total_expenses'], 5420);
      expect(json['total_income'], 2100);
      expect(json['total_transfers'], 890);
      expect(json['total_amount_expenses'], 125000.50);
      expect(json['total_amount_income'], 450000.00);
      expect(json['fund_box_balance'], 10000.00);
    });
  });
}
