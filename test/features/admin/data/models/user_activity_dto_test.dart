import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin/data/models/user_activity_dto.dart';

void main() {
  group('UserActivityDto', () {
    test('should create UserActivityDto from valid JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'user',
        'created_at': '2024-01-01T00:00:00.000000Z',
        'last_login': '2024-10-23T10:00:00.000000Z',
      };

      // Act
      final result = UserActivityDto.fromJson(json);

      // Assert
      expect(result.id, 1);
      expect(result.name, 'John Doe');
      expect(result.email, 'john@example.com');
      expect(result.role, 'user');
      expect(result.createdAt, DateTime.parse('2024-01-01T00:00:00.000000Z'));
      expect(result.lastLogin, DateTime.parse('2024-10-23T10:00:00.000000Z'));
    });

    test('should handle null last_login', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'user',
        'created_at': '2024-01-01T00:00:00.000000Z',
      };

      // Act
      final result = UserActivityDto.fromJson(json);

      // Assert
      expect(result.id, 1);
      expect(result.name, 'John Doe');
      expect(result.lastLogin, isNull);
    });

    test('should convert UserActivityDto to JSON', () {
      // Arrange
      final dto = UserActivityDto(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000000Z'),
        lastLogin: DateTime.parse('2024-10-23T10:00:00.000000Z'),
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['id'], 1);
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['role'], 'user');
      expect(json['created_at'], isA<String>());
      expect(json['last_login'], isA<String>());
    });

    test('should handle admin role', () {
      // Arrange
      final json = {
        'id': 2,
        'name': 'Admin User',
        'email': 'admin@example.com',
        'role': 'admin',
        'created_at': '2024-01-01T00:00:00.000000Z',
      };

      // Act
      final result = UserActivityDto.fromJson(json);

      // Assert
      expect(result.role, 'admin');
    });
  });
}
