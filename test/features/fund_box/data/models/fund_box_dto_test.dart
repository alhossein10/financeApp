import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/fund_box/data/models/fund_box_dto.dart';
import 'package:finance_app/features/fund_box/domain/entities/fund_box.dart';

void main() {
  group('FundBoxDto', () {
    group('fromJson', () {
      test('should parse JSON with total_balance and last_updated fields', () {
        // Arrange
        final json = {
          'id': 1,
          'total_balance': 15000.0,
          'last_updated': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final result = FundBoxDto.fromJson(json);

        // Assert
        expect(result.id, 1);
        expect(result.totalBalance, 15000.0);
        expect(result.lastUpdated, DateTime.parse('2024-10-23T10:00:00.000000Z'));
      });

      test('should parse JSON with balance_usd fallback', () {
        // Arrange
        final json = {
          'id': 1,
          'balance_usd': 10000.0,
          'updated_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final result = FundBoxDto.fromJson(json);

        // Assert
        expect(result.id, 1);
        expect(result.totalBalance, 10000.0);
        expect(result.lastUpdated, DateTime.parse('2024-10-23T10:00:00.000000Z'));
      });

      test('should handle string amounts', () {
        // Arrange
        final json = {
          'id': 1,
          'total_balance': '15000.50',
          'last_updated': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final result = FundBoxDto.fromJson(json);

        // Assert
        expect(result.totalBalance, 15000.50);
      });

      test('should handle integer amounts', () {
        // Arrange
        final json = {
          'id': 1,
          'total_balance': 15000,
          'last_updated': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final result = FundBoxDto.fromJson(json);

        // Assert
        expect(result.totalBalance, 15000.0);
      });

      test('should use default values for missing fields', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final result = FundBoxDto.fromJson(json);

        // Assert
        expect(result.id, 1);
        expect(result.totalBalance, 0.0);
        expect(result.lastUpdated, isA<DateTime>());
      });
    });

    group('toJson', () {
      test('should convert to JSON with both total_balance and balance_usd', () {
        // Arrange
        final dto = FundBoxDto(
          id: 1,
          totalBalance: 15000.0,
          lastUpdated: DateTime.parse('2024-10-23T10:00:00.000000Z'),
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['id'], 1);
        expect(json['total_balance'], 15000.0);
        expect(json['balance_usd'], 15000.0);
        expect(json['last_updated'], '2024-10-23T10:00:00.000Z');
      });
    });

    group('toEntity', () {
      test('should convert to FundBox entity', () {
        // Arrange
        final dto = FundBoxDto(
          id: 1,
          totalBalance: 15000.0,
          lastUpdated: DateTime.parse('2024-10-23T10:00:00.000000Z'),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.userId, 0); // Global fund box
        expect(entity.balanceUsd, 15000.0);
        expect(entity.updatedAt, DateTime.parse('2024-10-23T10:00:00.000000Z'));
      });
    });

    group('fromEntity', () {
      test('should create DTO from entity', () {
        // Arrange
        final entity = FundBox(
          id: 1,
          userId: 0,
          balanceUsd: 15000.0,
          updatedAt: DateTime.parse('2024-10-23T10:00:00.000000Z'),
        );

        // Act
        final dto = FundBoxDto.fromEntity(entity);

        // Assert
        expect(dto.id, 1);
        expect(dto.totalBalance, 15000.0);
        expect(dto.lastUpdated, DateTime.parse('2024-10-23T10:00:00.000000Z'));
      });
    });
  });
}
