import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/organizations/data/models/organization_dto.dart';
import 'package:finance_app/features/organizations/data/models/department_dto.dart';

void main() {
  group('OrganizationDto', () {
    test('should parse from JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'name': 'Test Organization',
        'code': 'TEST_ORG',
      };

      // Act
      final dto = OrganizationDto.fromJson(json);

      // Assert
      expect(dto.id, 1);
      expect(dto.name, 'Test Organization');
      expect(dto.code, 'TEST_ORG');
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = OrganizationDto(
        id: 2,
        name: 'Another Organization',
        code: 'ANOTHER_ORG',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['id'], 2);
      expect(json['name'], 'Another Organization');
      expect(json['code'], 'ANOTHER_ORG');
    });

    test('should handle special characters in name', () {
      // Arrange
      final json = {
        'id': 3,
        'name': 'Org & Co.',
        'code': 'ORG_CO',
      };

      // Act
      final dto = OrganizationDto.fromJson(json);

      // Assert
      expect(dto.name, 'Org & Co.');
    });
  });

  group('DepartmentDto', () {
    test('should parse from JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'organization_id': 5,
        'name': 'Engineering',
        'code': 'ENG',
      };

      // Act
      final dto = DepartmentDto.fromJson(json);

      // Assert
      expect(dto.id, 1);
      expect(dto.organizationId, 5);
      expect(dto.name, 'Engineering');
      expect(dto.code, 'ENG');
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final dto = DepartmentDto(
        id: 2,
        organizationId: 10,
        name: 'Marketing',
        code: 'MKT',
      );

      // Act
      final json = dto.toJson();

      // Assert
      expect(json['id'], 2);
      expect(json['organization_id'], 10);
      expect(json['name'], 'Marketing');
      expect(json['code'], 'MKT');
    });

    test('should handle long department names', () {
      // Arrange
      final json = {
        'id': 3,
        'organization_id': 1,
        'name': 'Human Resources and Employee Relations Department',
        'code': 'HR_ER',
      };

      // Act
      final dto = DepartmentDto.fromJson(json);

      // Assert
      expect(dto.name, 'Human Resources and Employee Relations Department');
      expect(dto.code, 'HR_ER');
    });
  });
}
