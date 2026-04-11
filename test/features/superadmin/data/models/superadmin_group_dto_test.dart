import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/superadmin/data/models/superadmin_group_dto.dart';
import 'package:finance_app/features/superadmin/data/models/admin_member_dto.dart';

void main() {
  group('SuperAdminGroupDto', () {
    test('should parse from JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'Test SuperAdmin Group',
        'group_code': '123456',
        'member_count': 5,
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = SuperAdminGroupDto.fromJson(json);

      // Assert
      expect(dto.id, 1);
      expect(dto.name, 'Test SuperAdmin Group');
      expect(dto.groupCode, '123456');
      expect(dto.memberCount, 5);
      expect(dto.createdAt, '2024-11-16T10:00:00Z');
    });

    test('should handle zero member count', () {
      // Arrange
      final json = {
        'id': 2,
        'name': 'Empty Group',
        'group_code': '654321',
        'member_count': 0,
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = SuperAdminGroupDto.fromJson(json);

      // Assert
      expect(dto.memberCount, 0);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = SuperAdminGroupDto(
        id: 3,
        name: 'Another Group',
        groupCode: '789012',
        memberCount: 10,
        createdAt: '2024-11-17T10:00:00Z',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['id'], 3);
      expect(json['name'], 'Another Group');
      expect(json['group_code'], '789012');
      expect(json['member_count'], 10);
      expect(json['created_at'], '2024-11-17T10:00:00Z');
    });

    test('should handle special characters in name', () {
      // Arrange
      final json = {
        'id': 4,
        'name': 'Group & Co. (Test)',
        'group_code': '111222',
        'member_count': 3,
        'created_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = SuperAdminGroupDto.fromJson(json);

      // Assert
      expect(dto.name, 'Group & Co. (Test)');
    });
  });

  group('AdminMemberDto', () {
    test('should parse from JSON with all fields', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'admin_group_id': 5,
        'joined_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = AdminMemberDto.fromJson(json);

      // Assert
      expect(dto.id, 1);
      expect(dto.name, 'John Doe');
      expect(dto.email, 'john@example.com');
      expect(dto.adminGroupId, 5);
      expect(dto.joinedAt, '2024-11-16T10:00:00Z');
    });

    test('should handle optional fields', () {
      // Arrange
      final json = {
        'id': 2,
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'joined_at': '2024-11-15T10:00:00Z',
      };

      // Act
      final dto = AdminMemberDto.fromJson(json);

      // Assert
      expect(dto.id, 2);
      expect(dto.name, 'Jane Smith');
      expect(dto.adminGroupId, isNull);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = AdminMemberDto(
        id: 3,
        name: 'Bob Johnson',
        email: 'bob@example.com',
        adminGroupId: 10,
        joinedAt: '2024-11-17T10:00:00Z',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['id'], 3);
      expect(json['name'], 'Bob Johnson');
      expect(json['email'], 'bob@example.com');
      expect(json['admin_group_id'], 10);
      expect(json['joined_at'], '2024-11-17T10:00:00Z');
    });

    test('should handle email with special characters', () {
      // Arrange
      final json = {
        'id': 4,
        'name': 'Test User',
        'email': 'test.user+tag@example.co.uk',
        'joined_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = AdminMemberDto.fromJson(json);

      // Assert
      expect(dto.email, 'test.user+tag@example.co.uk');
    });

    test('should handle long names', () {
      // Arrange
      final json = {
        'id': 5,
        'name': 'Very Long Name With Multiple Words And Spaces',
        'email': 'longname@example.com',
        'joined_at': '2024-11-16T10:00:00Z',
      };

      // Act
      final dto = AdminMemberDto.fromJson(json);

      // Assert
      expect(dto.name, 'Very Long Name With Multiple Words And Spaces');
    });
  });
}
