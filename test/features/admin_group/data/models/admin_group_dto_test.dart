import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin_group/data/models/admin_group_dto.dart';
import 'package:finance_app/features/admin_group/domain/entities/admin_group.dart';

void main() {
  group('AdminGroupDto', () {
    group('fromJson', () {
      test('should correctly parse JSON response with all fields', () {
        // Arrange
        final json = {
          'id': 1,
          'admin_user_id': 123,
          'group_code': 'ABC123',
          'group_name': 'Marketing Team',
          'is_active': 1,
          'members_count': 12,
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = AdminGroupDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.adminUserId, 123);
        expect(dto.groupCode, 'ABC123');
        expect(dto.groupName, 'Marketing Team');
        expect(dto.isActive, true);
        expect(dto.membersCount, 12);
        expect(dto.createdAt, '2024-10-23T10:00:00.000000Z');
        expect(dto.updatedAt, '2024-10-23T11:00:00.000000Z');
      });

      test('should handle is_active as boolean true', () {
        // Arrange
        final json = {
          'id': 1,
          'admin_user_id': 123,
          'group_code': 'ABC123',
          'is_active': true,
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = AdminGroupDto.fromJson(json);

        // Assert
        expect(dto.isActive, true);
      });

      test('should handle is_active as integer 0', () {
        // Arrange
        final json = {
          'id': 1,
          'admin_user_id': 123,
          'group_code': 'ABC123',
          'is_active': 0,
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = AdminGroupDto.fromJson(json);

        // Assert
        expect(dto.isActive, false);
      });

      test('should handle is_active as boolean false', () {
        // Arrange
        final json = {
          'id': 1,
          'admin_user_id': 123,
          'group_code': 'ABC123',
          'is_active': false,
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = AdminGroupDto.fromJson(json);

        // Assert
        expect(dto.isActive, false);
      });

      test('should handle null optional fields', () {
        // Arrange
        final json = {
          'id': 1,
          'admin_user_id': 123,
          'group_code': 'ABC123',
          'is_active': 1,
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = AdminGroupDto.fromJson(json);

        // Assert
        expect(dto.groupName, isNull);
        expect(dto.membersCount, isNull);
      });
    });

    group('toJson', () {
      test('should correctly convert DTO to JSON with all fields', () {
        // Arrange
        final dto = AdminGroupDto(
          id: 1,
          adminUserId: 123,
          groupCode: 'ABC123',
          groupName: 'Marketing Team',
          isActive: true,
          membersCount: 12,
          createdAt: '2024-10-23T10:00:00.000000Z',
          updatedAt: '2024-10-23T11:00:00.000000Z',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['id'], 1);
        expect(json['admin_user_id'], 123);
        expect(json['group_code'], 'ABC123');
        expect(json['group_name'], 'Marketing Team');
        expect(json['is_active'], 1);
        expect(json['members_count'], 12);
        expect(json['created_at'], '2024-10-23T10:00:00.000000Z');
        expect(json['updated_at'], '2024-10-23T11:00:00.000000Z');
      });

      test('should convert isActive false to 0', () {
        // Arrange
        final dto = AdminGroupDto(
          id: 1,
          adminUserId: 123,
          groupCode: 'ABC123',
          isActive: false,
          createdAt: '2024-10-23T10:00:00.000000Z',
          updatedAt: '2024-10-23T11:00:00.000000Z',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['is_active'], 0);
      });

      test('should exclude null optional fields from JSON', () {
        // Arrange
        final dto = AdminGroupDto(
          id: 1,
          adminUserId: 123,
          groupCode: 'ABC123',
          isActive: true,
          createdAt: '2024-10-23T10:00:00.000000Z',
          updatedAt: '2024-10-23T11:00:00.000000Z',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json.containsKey('group_name'), false);
        expect(json.containsKey('members_count'), false);
      });
    });

    group('toEntity', () {
      test('should correctly convert DTO to domain entity', () {
        // Arrange
        final dto = AdminGroupDto(
          id: 1,
          adminUserId: 123,
          groupCode: 'ABC123',
          groupName: 'Marketing Team',
          isActive: true,
          membersCount: 12,
          createdAt: '2024-10-23T10:00:00.000000Z',
          updatedAt: '2024-10-23T11:00:00.000000Z',
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.adminUserId, 123);
        expect(entity.groupCode, 'ABC123');
        expect(entity.groupName, 'Marketing Team');
        expect(entity.isActive, true);
        expect(entity.membersCount, 12);
        expect(entity.createdAt, isA<DateTime>());
        expect(entity.updatedAt, isA<DateTime>());
      });

      test('should parse ISO8601 date strings correctly', () {
        // Arrange
        final dto = AdminGroupDto(
          id: 1,
          adminUserId: 123,
          groupCode: 'ABC123',
          isActive: true,
          createdAt: '2024-10-23T10:00:00.000000Z',
          updatedAt: '2024-10-23T11:00:00.000000Z',
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.createdAt.year, 2024);
        expect(entity.createdAt.month, 10);
        expect(entity.createdAt.day, 23);
        expect(entity.updatedAt.year, 2024);
        expect(entity.updatedAt.month, 10);
        expect(entity.updatedAt.day, 23);
      });
    });

    group('fromEntity', () {
      test('should correctly convert domain entity to DTO', () {
        // Arrange
        final entity = AdminGroup(
          id: 1,
          adminUserId: 123,
          groupCode: 'ABC123',
          groupName: 'Marketing Team',
          isActive: true,
          membersCount: 12,
          createdAt: DateTime(2024, 10, 23, 10, 0),
          updatedAt: DateTime(2024, 10, 23, 11, 0),
        );

        // Act
        final dto = AdminGroupDto.fromEntity(entity);

        // Assert
        expect(dto.id, 1);
        expect(dto.adminUserId, 123);
        expect(dto.groupCode, 'ABC123');
        expect(dto.groupName, 'Marketing Team');
        expect(dto.isActive, true);
        expect(dto.membersCount, 12);
        expect(dto.createdAt, contains('2024-10-23'));
        expect(dto.updatedAt, contains('2024-10-23'));
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        // Arrange
        final dto = AdminGroupDto(
          id: 1,
          adminUserId: 123,
          groupCode: 'ABC123',
          groupName: 'Marketing Team',
          isActive: true,
          membersCount: 12,
          createdAt: '2024-10-23T10:00:00.000000Z',
          updatedAt: '2024-10-23T11:00:00.000000Z',
        );

        // Act
        final updated = dto.copyWith(
          groupName: 'Sales Team',
          membersCount: 15,
        );

        // Assert
        expect(updated.id, 1);
        expect(updated.groupCode, 'ABC123');
        expect(updated.groupName, 'Sales Team');
        expect(updated.membersCount, 15);
      });
    });

    group('Round-trip conversion', () {
      test('should maintain data integrity through JSON serialization', () {
        // Arrange
        final originalJson = {
          'id': 1,
          'admin_user_id': 123,
          'group_code': 'ABC123',
          'group_name': 'Marketing Team',
          'is_active': 1,
          'members_count': 12,
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = AdminGroupDto.fromJson(originalJson);
        final json = dto.toJson();

        // Assert
        expect(json['id'], originalJson['id']);
        expect(json['admin_user_id'], originalJson['admin_user_id']);
        expect(json['group_code'], originalJson['group_code']);
        expect(json['group_name'], originalJson['group_name']);
        expect(json['is_active'], originalJson['is_active']);
        expect(json['members_count'], originalJson['members_count']);
      });
    });
  });
}
