import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin_group/data/models/group_info_dto.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_info.dart';

void main() {
  group('GroupInfoDto', () {
    group('fromJson', () {
      test('should correctly parse JSON response with all fields', () {
        // Arrange
        final json = {
          'group_code': 'ABC123',
          'group_name': 'Marketing Team',
          'admin_name': 'Admin User',
          'admin_email': 'admin@example.com',
          'members_count': 12,
          'joined_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = GroupInfoDto.fromJson(json);

        // Assert
        expect(dto.groupCode, 'ABC123');
        expect(dto.groupName, 'Marketing Team');
        expect(dto.adminName, 'Admin User');
        expect(dto.adminEmail, 'admin@example.com');
        expect(dto.membersCount, 12);
        expect(dto.joinedAt, '2024-10-23T10:00:00.000000Z');
      });

      test('should handle null group_name', () {
        // Arrange
        final json = {
          'group_code': 'ABC123',
          'admin_name': 'Admin User',
          'admin_email': 'admin@example.com',
          'members_count': 12,
          'joined_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = GroupInfoDto.fromJson(json);

        // Assert
        expect(dto.groupName, isNull);
      });

      test('should handle different member counts', () {
        // Arrange
        final json = {
          'group_code': 'ABC123',
          'admin_name': 'Admin User',
          'admin_email': 'admin@example.com',
          'members_count': 1,
          'joined_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = GroupInfoDto.fromJson(json);

        // Assert
        expect(dto.membersCount, 1);
      });
    });

    group('toJson', () {
      test('should correctly convert DTO to JSON with all fields', () {
        // Arrange
        final dto = GroupInfoDto(
          groupCode: 'ABC123',
          groupName: 'Marketing Team',
          adminName: 'Admin User',
          adminEmail: 'admin@example.com',
          membersCount: 12,
          joinedAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['group_code'], 'ABC123');
        expect(json['group_name'], 'Marketing Team');
        expect(json['admin_name'], 'Admin User');
        expect(json['admin_email'], 'admin@example.com');
        expect(json['members_count'], 12);
        expect(json['joined_at'], '2024-10-23T10:00:00.000000Z');
      });

      test('should exclude null group_name from JSON', () {
        // Arrange
        final dto = GroupInfoDto(
          groupCode: 'ABC123',
          adminName: 'Admin User',
          adminEmail: 'admin@example.com',
          membersCount: 12,
          joinedAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json.containsKey('group_name'), false);
      });
    });

    group('toEntity', () {
      test('should correctly convert DTO to domain entity', () {
        // Arrange
        final dto = GroupInfoDto(
          groupCode: 'ABC123',
          groupName: 'Marketing Team',
          adminName: 'Admin User',
          adminEmail: 'admin@example.com',
          membersCount: 12,
          joinedAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.groupCode, 'ABC123');
        expect(entity.groupName, 'Marketing Team');
        expect(entity.adminName, 'Admin User');
        expect(entity.adminEmail, 'admin@example.com');
        expect(entity.membersCount, 12);
        expect(entity.joinedAt, isA<DateTime>());
      });

      test('should parse ISO8601 date string correctly', () {
        // Arrange
        final dto = GroupInfoDto(
          groupCode: 'ABC123',
          adminName: 'Admin User',
          adminEmail: 'admin@example.com',
          membersCount: 12,
          joinedAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.joinedAt.year, 2024);
        expect(entity.joinedAt.month, 10);
        expect(entity.joinedAt.day, 23);
      });
    });

    group('fromEntity', () {
      test('should correctly convert domain entity to DTO', () {
        // Arrange
        final entity = GroupInfo(
          groupCode: 'ABC123',
          groupName: 'Marketing Team',
          adminName: 'Admin User',
          adminEmail: 'admin@example.com',
          membersCount: 12,
          joinedAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = GroupInfoDto.fromEntity(entity);

        // Assert
        expect(dto.groupCode, 'ABC123');
        expect(dto.groupName, 'Marketing Team');
        expect(dto.adminName, 'Admin User');
        expect(dto.adminEmail, 'admin@example.com');
        expect(dto.membersCount, 12);
        expect(dto.joinedAt, contains('2024-10-23'));
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        // Arrange
        final dto = GroupInfoDto(
          groupCode: 'ABC123',
          groupName: 'Marketing Team',
          adminName: 'Admin User',
          adminEmail: 'admin@example.com',
          membersCount: 12,
          joinedAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final updated = dto.copyWith(
          groupName: 'Sales Team',
          membersCount: 15,
        );

        // Assert
        expect(updated.groupCode, 'ABC123');
        expect(updated.groupName, 'Sales Team');
        expect(updated.membersCount, 15);
        expect(updated.adminName, 'Admin User');
      });
    });

    group('Round-trip conversion', () {
      test('should maintain data integrity through JSON serialization', () {
        // Arrange
        final originalJson = {
          'group_code': 'ABC123',
          'group_name': 'Marketing Team',
          'admin_name': 'Admin User',
          'admin_email': 'admin@example.com',
          'members_count': 12,
          'joined_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = GroupInfoDto.fromJson(originalJson);
        final json = dto.toJson();

        // Assert
        expect(json['group_code'], originalJson['group_code']);
        expect(json['group_name'], originalJson['group_name']);
        expect(json['admin_name'], originalJson['admin_name']);
        expect(json['admin_email'], originalJson['admin_email']);
        expect(json['members_count'], originalJson['members_count']);
        expect(json['joined_at'], originalJson['joined_at']);
      });
    });
  });
}
