import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/export/data/models/export_dto.dart';

void main() {
  group('ExportDto', () {
    group('fromJson', () {
      test('should parse JSON with nested data structure', () {
        // Arrange
        final json = {
          'success': true,
          'data': {
            'id': 1,
            'format': 'pdf',
            'status': 'processing',
            'download_url': null,
          },
        };

        // Act
        final result = ExportDto.fromJson(json);

        // Assert
        expect(result.id, 1);
        expect(result.format, 'pdf');
        expect(result.status, 'processing');
        expect(result.downloadUrl, null);
      });

      test('should parse JSON with direct data structure', () {
        // Arrange
        final json = {
          'id': 2,
          'format': 'excel',
          'status': 'completed',
          'download_url': 'https://example.com/download/2',
        };

        // Act
        final result = ExportDto.fromJson(json);

        // Assert
        expect(result.id, 2);
        expect(result.format, 'excel');
        expect(result.status, 'completed');
        expect(result.downloadUrl, 'https://example.com/download/2');
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        // Arrange
        final dto = ExportDto(
          id: 1,
          format: 'pdf',
          status: 'processing',
          downloadUrl: null,
        );

        // Act
        final result = dto.toJson();

        // Assert
        expect(result['id'], 1);
        expect(result['format'], 'pdf');
        expect(result['status'], 'processing');
        expect(result.containsKey('download_url'), false);
      });

      test('should include download_url when present', () {
        // Arrange
        final dto = ExportDto(
          id: 2,
          format: 'excel',
          status: 'completed',
          downloadUrl: 'https://example.com/download/2',
        );

        // Act
        final result = dto.toJson();

        // Assert
        expect(result['download_url'], 'https://example.com/download/2');
      });
    });

    group('status helpers', () {
      test('isProcessing should return true for processing status', () {
        final dto = ExportDto(id: 1, format: 'pdf', status: 'processing');
        expect(dto.isProcessing, true);
      });

      test('isProcessing should return true for queued status', () {
        final dto = ExportDto(id: 1, format: 'pdf', status: 'queued');
        expect(dto.isProcessing, true);
      });

      test('isCompleted should return true for completed status', () {
        final dto = ExportDto(id: 1, format: 'pdf', status: 'completed');
        expect(dto.isCompleted, true);
      });

      test('isFailed should return true for failed status', () {
        final dto = ExportDto(id: 1, format: 'pdf', status: 'failed');
        expect(dto.isFailed, true);
      });
    });

    group('exportId getter', () {
      test('should return id as string', () {
        final dto = ExportDto(id: 123, format: 'pdf', status: 'processing');
        expect(dto.exportId, '123');
      });
    });
  });
}
