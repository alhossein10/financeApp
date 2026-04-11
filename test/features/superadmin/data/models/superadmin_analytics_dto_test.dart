import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/superadmin/data/models/superadmin_analytics_dto.dart';

void main() {
  group('SuperAdminAnalyticsDto', () {
    test('should parse from JSON correctly', () {
      // Arrange
      final json = {
        'period': '15days',
        'admin_groups': [
          {
            'admin_group_id': 1,
            'admin_group_name': 'Group A',
            'total_transfers': 10,
            'total_transfer_amount': 5000.0,
            'total_expenses': 20,
            'total_expense_amount': 3000.0,
          },
        ],
      };

      // Act
      final dto = SuperAdminAnalyticsDto.fromJson(json);

      // Assert
      expect(dto.period, '15days');
      expect(dto.adminGroups.length, 1);
      expect(dto.adminGroups[0].adminGroupId, 1);
      expect(dto.adminGroups[0].adminGroupName, 'Group A');
      expect(dto.adminGroups[0].totalTransfers, 10);
      expect(dto.adminGroups[0].totalTransferAmount, 5000.0);
      expect(dto.adminGroups[0].totalExpenses, 20);
      expect(dto.adminGroups[0].totalExpenseAmount, 3000.0);
    });

    test('should handle empty admin groups', () {
      // Arrange
      final json = {
        'period': 'month',
        'admin_groups': [],
      };

      // Act
      final dto = SuperAdminAnalyticsDto.fromJson(json);

      // Assert
      expect(dto.period, 'month');
      expect(dto.adminGroups, isEmpty);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = SuperAdminAnalyticsDto(
        period: 'all',
        adminGroups: [
          AdminGroupAnalyticsDto(
            adminGroupId: 2,
            adminGroupName: 'Group B',
            totalTransfers: 5,
            totalTransferAmount: 2500.0,
            totalExpenses: 15,
            totalExpenseAmount: 1500.0,
          ),
        ],
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['period'], 'all');
      expect(json['admin_groups'].length, 1);
      expect(json['admin_groups'][0]['admin_group_id'], 2);
      expect(json['admin_groups'][0]['admin_group_name'], 'Group B');
    });
  });

  group('AdminGroupAnalyticsDto', () {
    test('should parse from JSON with all fields', () {
      // Arrange
      final json = {
        'admin_group_id': 3,
        'admin_group_name': 'Group C',
        'total_transfers': 8,
        'total_transfer_amount': 4000.0,
        'total_expenses': 12,
        'total_expense_amount': 2000.0,
      };

      // Act
      final dto = AdminGroupAnalyticsDto.fromJson(json);

      // Assert
      expect(dto.adminGroupId, 3);
      expect(dto.adminGroupName, 'Group C');
      expect(dto.totalTransfers, 8);
      expect(dto.totalTransferAmount, 4000.0);
      expect(dto.totalExpenses, 12);
      expect(dto.totalExpenseAmount, 2000.0);
    });

    test('should handle zero values', () {
      // Arrange
      final json = {
        'admin_group_id': 4,
        'admin_group_name': 'Empty Group',
        'total_transfers': 0,
        'total_transfer_amount': 0.0,
        'total_expenses': 0,
        'total_expense_amount': 0.0,
      };

      // Act
      final dto = AdminGroupAnalyticsDto.fromJson(json);

      // Assert
      expect(dto.totalTransfers, 0);
      expect(dto.totalTransferAmount, 0.0);
      expect(dto.totalExpenses, 0);
      expect(dto.totalExpenseAmount, 0.0);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = AdminGroupAnalyticsDto(
        adminGroupId: 5,
        adminGroupName: 'Group D',
        totalTransfers: 3,
        totalTransferAmount: 1500.0,
        totalExpenses: 7,
        totalExpenseAmount: 800.0,
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['admin_group_id'], 5);
      expect(json['admin_group_name'], 'Group D');
      expect(json['total_transfers'], 3);
      expect(json['total_transfer_amount'], 1500.0);
      expect(json['total_expenses'], 7);
      expect(json['total_expense_amount'], 800.0);
    });
  });
}
