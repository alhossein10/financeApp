import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/models/user_dto.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';

void main() {
  group('UserDto', () {
    group('fromJson', () {
      test('should correctly parse JSON with new admin group fields', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'organization_name': 'Tech Corp',
          'department_name': 'Engineering',
          'admin_group_id': 123,
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.name, 'John Doe');
        expect(dto.email, 'john@example.com');
        expect(dto.role, 'user');
        expect(dto.organizationName, 'Tech Corp');
        expect(dto.departmentName, 'Engineering');
        expect(dto.adminGroupId, 123);
      });

      test('should handle backward compatibility with old fields', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'organization_id': 5,
          'department_id': 10,
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.organizationId, 5);
        expect(dto.departmentId, 10);
      });

      test('should handle both new and old fields together', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'organization_name': 'Tech Corp',
          'department_name': 'Engineering',
          'admin_group_id': 123,
          'organization_id': 5,
          'department_id': 10,
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.organizationName, 'Tech Corp');
        expect(dto.departmentName, 'Engineering');
        expect(dto.adminGroupId, 123);
        expect(dto.organizationId, 5);
        expect(dto.departmentId, 10);
      });

      test('should handle nested data.user structure', () {
        // Arrange
        final json = {
          'data': {
            'user': {
              'id': 1,
              'name': 'John Doe',
              'email': 'john@example.com',
              'role': 'admin',
              'admin_group_id': 123,
              'created_at': '2024-10-23T10:00:00.000000Z',
            }
          }
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.name, 'John Doe');
        expect(dto.role, 'admin');
        expect(dto.adminGroupId, 123);
      });

      test('should handle data structure without nested user', () {
        // Arrange
        final json = {
          'data': {
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
            'role': 'user',
            'created_at': '2024-10-23T10:00:00.000000Z',
          }
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.name, 'John Doe');
      });

      test('should default role to user when null', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.role, 'user');
      });

      test('should handle admin role', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'Admin User',
          'email': 'admin@example.com',
          'role': 'admin',
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.role, 'admin');
        expect(dto.isAdmin, true);
      });

      test('should handle null updated_at', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.updatedAt, isNull);
      });

      test('should handle null optional new fields', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = UserDto.fromJson(json);

        // Assert
        expect(dto.organizationName, isNull);
        expect(dto.departmentName, isNull);
        expect(dto.adminGroupId, isNull);
      });
    });

    group('toJson', () {
      test('should correctly convert DTO to JSON with new fields', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationName: 'Tech Corp',
          departmentName: 'Engineering',
          adminGroupId: 123,
          createdAt: DateTime(2024, 10, 23, 10, 0),
          updatedAt: DateTime(2024, 10, 23, 11, 0),
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['id'], 1);
        expect(json['name'], 'John Doe');
        expect(json['email'], 'john@example.com');
        expect(json['role'], 'user');
        expect(json['organization_name'], 'Tech Corp');
        expect(json['department_name'], 'Engineering');
        expect(json['admin_group_id'], 123);
      });

      test('should include old fields for backward compatibility', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationId: 5,
          departmentId: 10,
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['organization_id'], 5);
        expect(json['department_id'], 10);
      });

      test('should exclude null optional fields from JSON', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json.containsKey('organization_name'), false);
        expect(json.containsKey('department_name'), false);
        expect(json.containsKey('admin_group_id'), false);
        expect(json.containsKey('organization_id'), false);
        expect(json.containsKey('department_id'), false);
        // updated_at is included but will be null
        expect(json['updated_at'], isNull);
      });
    });

    group('toEntity', () {
      test('should correctly convert DTO to domain entity with new fields', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationName: 'Tech Corp',
          departmentName: 'Engineering',
          adminGroupId: 123,
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.username, 'John Doe');
        expect(entity.email, 'john@example.com');
        expect(entity.role, UserRole.user);
        expect(entity.organizationName, 'Tech Corp');
        expect(entity.departmentName, 'Engineering');
        expect(entity.adminGroupId, 123);
      });

      test('should map admin role correctly', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'Admin User',
          email: 'admin@example.com',
          role: 'admin',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.role, UserRole.admin);
      });

      test('should default to organizationId 1 when not provided', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.organizationId, 1);
      });

      test('should prioritize new fields over old fields', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationName: 'Tech Corp',
          departmentName: 'Engineering',
          adminGroupId: 123,
          organizationId: 5,
          departmentId: 10,
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.organizationName, 'Tech Corp');
        expect(entity.departmentName, 'Engineering');
        expect(entity.adminGroupId, 123);
      });
    });

    group('fromEntity', () {
      test('should correctly convert domain entity to DTO', () {
        // Arrange
        final entity = User(
          id: 1,
          username: 'John Doe',
          email: 'john@example.com',
          role: UserRole.user,
          organizationId: 1,
          organizationName: 'Tech Corp',
          departmentName: 'Engineering',
          adminGroupId: 123,
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = UserDto.fromEntity(entity);

        // Assert
        expect(dto.id, 1);
        expect(dto.name, 'John Doe');
        expect(dto.email, 'john@example.com');
        expect(dto.role, 'user');
        expect(dto.organizationName, 'Tech Corp');
        expect(dto.departmentName, 'Engineering');
        expect(dto.adminGroupId, 123);
      });

      test('should map admin role correctly', () {
        // Arrange
        final entity = User(
          id: 1,
          username: 'Admin User',
          email: 'admin@example.com',
          role: UserRole.admin,
          organizationId: 1,
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = UserDto.fromEntity(entity);

        // Assert
        expect(dto.role, 'admin');
      });
    });

    group('isAdmin', () {
      test('should return true for admin role', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'Admin User',
          email: 'admin@example.com',
          role: 'admin',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Assert
        expect(dto.isAdmin, true);
      });

      test('should return false for user role', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Assert
        expect(dto.isAdmin, false);
      });

      test('should handle case-insensitive admin check', () {
        // Arrange
        final dto = UserDto(
          id: 1,
          name: 'Admin User',
          email: 'admin@example.com',
          role: 'ADMIN',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Assert
        expect(dto.isAdmin, true);
      });
    });

    group('Round-trip conversion', () {
      test('should maintain data integrity through JSON serialization', () {
        // Arrange
        final originalJson = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'organization_name': 'Tech Corp',
          'department_name': 'Engineering',
          'admin_group_id': 123,
          'created_at': '2024-10-23T10:00:00.000000Z',
          'updated_at': '2024-10-23T11:00:00.000000Z',
        };

        // Act
        final dto = UserDto.fromJson(originalJson);
        final json = dto.toJson();

        // Assert
        expect(json['id'], originalJson['id']);
        expect(json['name'], originalJson['name']);
        expect(json['email'], originalJson['email']);
        expect(json['role'], originalJson['role']);
        expect(json['organization_name'], originalJson['organization_name']);
        expect(json['department_name'], originalJson['department_name']);
        expect(json['admin_group_id'], originalJson['admin_group_id']);
      });
    });
  });
}
