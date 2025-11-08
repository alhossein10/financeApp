import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/export/data/models/export_request_dto.dart';

void main() {
  group('ExportRequestDto', () {
    group('toJson', () {
      test('should convert to JSON with date_from and date_to in YYYY-MM-DD format', () {
        // Arrange
        final dto = ExportRequestDto(
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 12, 31),
          format: 'pdf',
        );

        // Act
        final result = dto.toJson();

        // Assert
        expect(result['format'], 'pdf');
        expect(result['date_from'], '2024-01-15');
        expect(result['date_to'], '2024-12-31');
      });

      test('should omit date_from when startDate is null', () {
        // Arrange
        final dto = ExportRequestDto(
          startDate: null,
          endDate: DateTime(2024, 12, 31),
          format: 'excel',
        );

        // Act
        final result = dto.toJson();

        // Assert
        expect(result.containsKey('date_from'), false);
        expect(result['date_to'], '2024-12-31');
        expect(result['format'], 'excel');
      });

      test('should omit date_to when endDate is null', () {
        // Arrange
        final dto = ExportRequestDto(
          startDate: DateTime(2024, 1, 1),
          endDate: null,
          format: 'pdf',
        );

        // Act
        final result = dto.toJson();

        // Assert
        expect(result['date_from'], '2024-01-01');
        expect(result.containsKey('date_to'), false);
        expect(result['format'], 'pdf');
      });

      test('should handle dates with single-digit months and days', () {
        // Arrange
        final dto = ExportRequestDto(
          startDate: DateTime(2024, 3, 5),
          endDate: DateTime(2024, 9, 8),
          format: 'pdf',
        );

        // Act
        final result = dto.toJson();

        // Assert
        expect(result['date_from'], '2024-03-05');
        expect(result['date_to'], '2024-09-08');
      });
    });
  });
}
