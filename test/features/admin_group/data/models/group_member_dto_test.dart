import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin_group/data/models/group_member_dto.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_member.dart';

void main() {
  group('GroupMemberDto', () {
    group('fromJson', () {
      test('should correctly parse JSON response with all fields', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'organization_name': 'Tech Corp',
          'department_name': 'Engineering',
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = GroupMemberDto.fromJson(json);

        // Assert
        expect(dto.id, 1);
        expect(dto.name, 'John Doe');
        expect(dto.email, 'john@example.com');
        expect(dto.role, 'user');
        expect(dto.organizationName, 'Tech Corp');
        expect(dto.departmentName, 'Engineering');
        expect(dto.createdAt, '2024-10-23T10:00:00.000000Z');
      });

      test('should handle null optional fields', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = GroupMemberDto.fromJson(json);

        // Assert
        expect(dto.organizationName, isNull);
        expect(dto.departmentName, isNull);
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
        final dto = GroupMemberDto.fromJson(json);

        // Assert
        expect(dto.role, 'admin');
      });
    });

    group('toJson', () {
      test('should correctly convert DTO to JSON with all fields', () {
        // Arrange
        final dto = GroupMemberDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationName: 'Tech Corp',
          departmentName: 'Engineering',
          createdAt: '2024-10-23T10:00:00.000000Z',
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
        expect(json['created_at'], '2024-10-23T10:00:00.000000Z');
      });

      test('should exclude null optional fields from JSON', () {
        // Arrange
        final dto = GroupMemberDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          createdAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json.containsKey('organization_name'), false);
        expect(json.containsKey('department_name'), false);
      });
    });

    group('toEntity', () {
      test('should correctly convert DTO to domain entity', () {
        // Arrange
        final dto = GroupMemberDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationName: 'Tech Corp',
          departmentName: 'Engineering',
          createdAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.name, 'John Doe');
        expect(entity.email, 'john@example.com');
        expect(entity.role, 'user');
        expect(entity.organizationName, 'Tech Corp');
        expect(entity.departmentName, 'Engineering');
        expect(entity.createdAt, isA<DateTime>());
      });

      test('should parse ISO8601 date string correctly', () {
        // Arrange
        final dto = GroupMemberDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          createdAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.createdAt.year, 2024);
        expect(entity.createdAt.month, 10);
        expect(entity.createdAt.day, 23);
      });
    });

    group('fromEntity', () {
      test('should correctly convert domain entity to DTO', () {
        // Arrange
        final entity = GroupMember(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationName: 'Tech Corp',
          departmentName: 'Engineering',
          createdAt: DateTime(2024, 10, 23, 10, 0),
        );

        // Act
        final dto = GroupMemberDto.fromEntity(entity);

        // Assert
        expect(dto.id, 1);
        expect(dto.name, 'John Doe');
        expect(dto.email, 'john@example.com');
        expect(dto.role, 'user');
        expect(dto.organizationName, 'Tech Corp');
        expect(dto.departmentName, 'Engineering');
        expect(dto.createdAt, contains('2024-10-23'));
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        // Arrange
        final dto = GroupMemberDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationName: 'Tech Corp',
          departmentName: 'Engineering',
          createdAt: '2024-10-23T10:00:00.000000Z',
        );

        // Act
        final updated = dto.copyWith(
          name: 'Jane Doe',
          departmentName: 'Marketing',
        );

        // Assert
        expect(updated.id, 1);
        expect(updated.name, 'Jane Doe');
        expect(updated.email, 'john@example.com');
        expect(updated.departmentName, 'Marketing');
        expect(updated.organizationName, 'Tech Corp');
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
          'created_at': '2024-10-23T10:00:00.000000Z',
        };

        // Act
        final dto = GroupMemberDto.fromJson(originalJson);
        final json = dto.toJson();

        // Assert
        expect(json['id'], originalJson['id']);
        expect(json['name'], originalJson['name']);
        expect(json['email'], originalJson['email']);
        expect(json['role'], originalJson['role']);
        expect(json['organization_name'], originalJson['organization_name']);
        expect(json['department_name'], originalJson['department_name']);
        expect(json['created_at'], originalJson['created_at']);
      });
    });
  });
}
