import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/models/file_upload_dto.dart';

void main() {
  group('FileUploadDto', () {
    final testDateTime = DateTime.parse('2024-10-23T10:00:00.000000Z');

    final testJson = {
      'id': 1,
      'filename': 'receipt_20241023.jpg',
      'path': 'encrypted_path_string',
      'type': 'receipt',
      'size': 245678,
      'mime_type': 'image/jpeg',
      'uploaded_at': '2024-10-23T10:00:00.000000Z',
    };

    final testDto = FileUploadDto(
      id: 1,
      filename: 'receipt_20241023.jpg',
      path: 'encrypted_path_string',
      type: 'receipt',
      size: 245678,
      mimeType: 'image/jpeg',
      uploadedAt: testDateTime,
    );

    test('fromJson creates correct FileUploadDto', () {
      final dto = FileUploadDto.fromJson(testJson);

      expect(dto.id, 1);
      expect(dto.filename, 'receipt_20241023.jpg');
      expect(dto.path, 'encrypted_path_string');
      expect(dto.type, 'receipt');
      expect(dto.size, 245678);
      expect(dto.mimeType, 'image/jpeg');
      expect(dto.uploadedAt, testDateTime);
    });

    test('toJson creates correct JSON', () {
      final json = testDto.toJson();

      expect(json['id'], 1);
      expect(json['filename'], 'receipt_20241023.jpg');
      expect(json['path'], 'encrypted_path_string');
      expect(json['type'], 'receipt');
      expect(json['size'], 245678);
      expect(json['mime_type'], 'image/jpeg');
      expect(json['uploaded_at'], '2024-10-23T10:00:00.000Z');
    });

    test('toString returns correct format', () {
      final str = testDto.toString();

      expect(str, contains('FileUploadDto'));
      expect(str, contains('id: 1'));
      expect(str, contains('filename: receipt_20241023.jpg'));
      expect(str, contains('type: receipt'));
      expect(str, contains('size: 245678'));
    });

    test('equality works correctly', () {
      final dto1 = FileUploadDto.fromJson(testJson);
      final dto2 = FileUploadDto.fromJson(testJson);
      final dto3 = FileUploadDto.fromJson({
        ...testJson,
        'id': 2,
      });

      expect(dto1, equals(dto2));
      expect(dto1, isNot(equals(dto3)));
    });

    test('hashCode works correctly', () {
      final dto1 = FileUploadDto.fromJson(testJson);
      final dto2 = FileUploadDto.fromJson(testJson);

      expect(dto1.hashCode, equals(dto2.hashCode));
    });
  });

  group('FileType', () {
    test('fromString returns correct FileType', () {
      expect(FileType.fromString('receipt'), FileType.receipt);
      expect(FileType.fromString('invoice'), FileType.invoice);
      expect(FileType.fromString('document'), FileType.document);
    });

    test('fromString throws on invalid type', () {
      expect(
        () => FileType.fromString('invalid'),
        throwsArgumentError,
      );
    });

    test('value returns correct string', () {
      expect(FileType.receipt.value, 'receipt');
      expect(FileType.invoice.value, 'invoice');
      expect(FileType.document.value, 'document');
    });
  });
}
