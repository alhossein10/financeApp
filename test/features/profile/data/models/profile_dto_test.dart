import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/profile/data/models/profile_dto.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';

void main() {
  group('ProfileDto', () {
    group('fromJson', () {
      test('should parse JSON with all required fields', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'user',
          'created_at': '2024-01-01T00:00:00.000000Z',
        };

        // Act
        final result = ProfileDto.fromJson(json);

        // Assert
        expect(result.id, 1);
        expect(result.name, 'John Doe');
        expect(result.email, 'john@example.com');
        expect(result.role, 'user');
        expect(result.createdAt, DateTime.parse('2024-01-01T00:00:00.000000Z'));
        expect(result.updatedAt, null);
        expect(result.profilePicturePath, null);
        expect(result.lastLogin, null);
      });

      test('should parse JSON with optional fields', () {
        // Arrange
        final json = {
          'id': 1,
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'admin',
          'created_at': '2024-01-01T00:00:00.000000Z',
          'updated_at': '2024-01-02T00:00:00.000000Z',
          'profile_picture_path': '/path/to/picture.jpg',
          'last_login': '2024-01-03T00:00:00.000000Z',
        };

        // Act
        final result = ProfileDto.fromJson(json);

        // Assert
        expect(result.id, 1);
        expect(result.name, 'John Doe');
        expect(result.email, 'john@example.com');
        expect(result.role, 'admin');
        expect(result.createdAt, DateTime.parse('2024-01-01T00:00:00.000000Z'));
        expect(result.updatedAt, DateTime.parse('2024-01-02T00:00:00.000000Z'));
        expect(result.profilePicturePath, '/path/to/picture.jpg');
        expect(result.lastLogin, DateTime.parse('2024-01-03T00:00:00.000000Z'));
      });

      test('should identify admin role correctly', () {
        // Arrange
        final adminJson = {
          'id': 1,
          'name': 'Admin User',
          'email': 'admin@example.com',
          'role': 'admin',
          'created_at': '2024-01-01T00:00:00.000000Z',
        };

        final userJson = {
          'id': 2,
          'name': 'Regular User',
          'email': 'user@example.com',
          'role': 'user',
          'created_at': '2024-01-01T00:00:00.000000Z',
        };

        // Act
        final adminDto = ProfileDto.fromJson(adminJson);
        final userDto = ProfileDto.fromJson(userJson);

        // Assert
        expect(adminDto.isAdmin, true);
        expect(userDto.isAdmin, false);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        // Arrange
        final dto = ProfileDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000000Z'),
          updatedAt: DateTime.parse('2024-01-02T00:00:00.000000Z'),
          profilePicturePath: '/path/to/picture.jpg',
          lastLogin: DateTime.parse('2024-01-03T00:00:00.000000Z'),
        );

        // Act
        final json = dto.toJson();

        // Assert
        expect(json['id'], 1);
        expect(json['name'], 'John Doe');
        expect(json['email'], 'john@example.com');
        expect(json['role'], 'user');
        expect(json['created_at'], '2024-01-01T00:00:00.000Z');
        expect(json['updated_at'], '2024-01-02T00:00:00.000Z');
        expect(json['profile_picture_path'], '/path/to/picture.jpg');
        expect(json['last_login'], '2024-01-03T00:00:00.000Z');
      });
    });

    group('toEntity', () {
      test('should convert to User entity with user role', () {
        // Arrange
        final dto = ProfileDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000000Z'),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.username, 'John Doe');
        expect(entity.email, 'john@example.com');
        expect(entity.role, UserRole.user);
        expect(entity.createdAt, DateTime.parse('2024-01-01T00:00:00.000000Z'));
      });

      test('should convert to User entity with admin role', () {
        // Arrange
        final dto = ProfileDto(
          id: 1,
          name: 'Admin User',
          email: 'admin@example.com',
          role: 'admin',
          createdAt: DateTime.parse('2024-01-01T00:00:00.000000Z'),
        );

        // Act
        final entity = dto.toEntity();

        // Assert
        expect(entity.id, 1);
        expect(entity.username, 'Admin User');
        expect(entity.email, 'admin@example.com');
        expect(entity.role, UserRole.admin);
      });
    });

    group('fromEntity', () {
      test('should create DTO from User entity with user role', () {
        // Arrange
        final entity = User(
          id: 1,
          username: 'John Doe',
          email: 'john@example.com',
          role: UserRole.user,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000000Z'),
        );

        // Act
        final dto = ProfileDto.fromEntity(entity);

        // Assert
        expect(dto.id, 1);
        expect(dto.name, 'John Doe');
        expect(dto.email, 'john@example.com');
        expect(dto.role, 'user');
        expect(dto.createdAt, DateTime.parse('2024-01-01T00:00:00.000000Z'));
      });

      test('should create DTO from User entity with admin role', () {
        // Arrange
        final entity = User(
          id: 1,
          username: 'Admin User',
          email: 'admin@example.com',
          role: UserRole.admin,
          createdAt: DateTime.parse('2024-01-01T00:00:00.000000Z'),
        );

        // Act
        final dto = ProfileDto.fromEntity(entity);

        // Assert
        expect(dto.id, 1);
        expect(dto.name, 'Admin User');
        expect(dto.email, 'admin@example.com');
        expect(dto.role, 'admin');
      });
    });
  });
}
