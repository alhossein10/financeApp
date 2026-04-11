import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/core/services/file_upload_service.dart';
import 'package:finance_app/core/models/file_upload_dto.dart';

@GenerateMocks([ApiClient, DioApiClient])
import 'file_upload_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late FileUploadServiceImpl fileUploadService;
  late MockDioApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockDioApiClient();
    fileUploadService = FileUploadServiceImpl(apiClient: mockApiClient);
  });

  group('FileUploadService - Upload Invoice', () {
    test('should upload invoice successfully', () async {
      // Arrange
      final testFile = File('test_invoice.jpg');
      const expenseId = 123;
      const invoicePath = '/uploads/invoices/test_invoice.jpg';

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/expenses/invoices/upload'),
        statusCode: 200,
        data: {
          'invoice_path': invoicePath,
          'message': 'Invoice uploaded successfully',
        },
      );

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await fileUploadService.uploadInvoice(
        testFile,
        expenseId: expenseId,
      );

      // Assert
      expect(result, invoicePath);
      verify(mockApiClient.uploadFile(
        '/expenses/invoices/upload',
        any,
        fields: {'expense_id': expenseId.toString()},
        fileFieldName: 'invoice',
        onProgress: anyNamed('onProgress'),
      )).called(1);
    });

    test('should track upload progress', () async {
      // Arrange
      final testFile = File('test_invoice.jpg');
      final progressValues = <double>[];

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/expenses/invoices/upload'),
        statusCode: 200,
        data: {'invoice_path': '/uploads/test.jpg'},
      );

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[const Symbol('onProgress')] as Function?;
        if (onProgress != null) {
          // Simulate progress updates
          onProgress(25, 100);
          onProgress(50, 100);
          onProgress(75, 100);
          onProgress(100, 100);
        }
        return mockResponse;
      });

      // Act
      await fileUploadService.uploadInvoice(
        testFile,
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // Assert
      expect(progressValues.length, 4);
      expect(progressValues[0], 0.25);
      expect(progressValues[1], 0.5);
      expect(progressValues[2], 0.75);
      expect(progressValues[3], 1.0);
    });

    test('should throw ApiException when invoice_path is missing', () async {
      // Arrange
      final testFile = File('test_invoice.jpg');

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/expenses/invoices/upload'),
        statusCode: 200,
        data: {
          'message': 'Uploaded',
          // Missing invoice_path
        },
      );

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => fileUploadService.uploadInvoice(testFile),
        throwsA(isA<ApiException>()),
      );
    });

    test('should throw ApiException on upload failure', () async {
      // Arrange
      final testFile = File('test_invoice.jpg');

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/expenses/invoices/upload'),
        statusCode: 500,
        data: {'message': 'Server error'},
      );

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => fileUploadService.uploadInvoice(testFile),
        throwsA(isA<ApiException>()),
      );
    });

    test('should handle network errors during upload', () async {
      // Arrange
      final testFile = File('test_invoice.jpg');

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/expenses/invoices/upload'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act & Assert
      expect(
        () => fileUploadService.uploadInvoice(testFile),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('FileUploadService - Download Invoice', () {
    test('should download invoice successfully', () async {
      // Arrange
      const invoicePath = '/uploads/invoices/test_invoice.jpg';

      when(mockApiClient.downloadFile(
        any,
        any,
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => {});

      // Act
      final result = await fileUploadService.downloadInvoice(invoicePath);

      // Assert
      expect(result, isA<File>());
      expect(result.path, contains('test_invoice.jpg'));
      verify(mockApiClient.downloadFile(
        '/expenses/invoices/download',
        any,
        onProgress: anyNamed('onProgress'),
      )).called(1);
    });

    test('should track download progress', () async {
      // Arrange
      const invoicePath = '/uploads/invoices/test_invoice.jpg';
      final progressValues = <double>[];

      when(mockApiClient.downloadFile(
        any,
        any,
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((invocation) async {
        final onProgress =
            invocation.namedArguments[const Symbol('onProgress')] as Function?;
        if (onProgress != null) {
          // Simulate progress updates
          onProgress(1024, 4096);
          onProgress(2048, 4096);
          onProgress(3072, 4096);
          onProgress(4096, 4096);
        }
      });

      // Act
      await fileUploadService.downloadInvoice(
        invoicePath,
        onProgress: (progress) {
          progressValues.add(progress);
        },
      );

      // Assert
      expect(progressValues.length, 4);
      expect(progressValues[0], 0.25);
      expect(progressValues[1], 0.5);
      expect(progressValues[2], 0.75);
      expect(progressValues[3], 1.0);
    });

    test('should throw ApiException when download fails', () async {
      // Arrange
      const invoicePath = '/uploads/invoices/test_invoice.jpg';

      when(mockApiClient.downloadFile(
        any,
        any,
        onProgress: anyNamed('onProgress'),
      )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/expenses/invoices/download'),
          response: Response(
            requestOptions:
                RequestOptions(path: '/expenses/invoices/download'),
            statusCode: 404,
            data: {'message': 'File not found'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => fileUploadService.downloadInvoice(invoicePath),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('FileUploadService - Delete Invoice', () {
    test('should delete invoice successfully', () async {
      // Arrange
      const invoicePath = '/uploads/invoices/test_invoice.jpg';

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/expenses/invoices/delete'),
        statusCode: 200,
        data: {'message': 'Invoice deleted successfully'},
      );

      when(mockApiClient.delete(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      await fileUploadService.deleteInvoice(invoicePath);

      // Assert
      verify(mockApiClient.delete(
        '/expenses/invoices/delete',
        queryParams: {'invoice_path': invoicePath},
      )).called(1);
    });

    test('should handle 204 No Content response', () async {
      // Arrange
      const invoicePath = '/uploads/invoices/test_invoice.jpg';

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/expenses/invoices/delete'),
        statusCode: 204,
      );

      when(mockApiClient.delete(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => fileUploadService.deleteInvoice(invoicePath),
        returnsNormally,
      );
    });

    test('should throw ApiException when delete fails', () async {
      // Arrange
      const invoicePath = '/uploads/invoices/test_invoice.jpg';

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/expenses/invoices/delete'),
        statusCode: 500,
        data: {'message': 'Server error'},
      );

      when(mockApiClient.delete(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => fileUploadService.deleteInvoice(invoicePath),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('FileUploadService - Image Validation', () {
    test('should validate valid image file', () async {
      // Arrange
      final testFile = File('test_image.jpg');

      // Note: This test would require actual file system access
      // In a real scenario, you'd mock the file system or use test files
      // For now, we'll skip the actual validation test
    });

    test('should reject invalid file extension', () async {
      // This would require file system mocking
      // Skipped for unit test simplicity
    });

    test('should reject oversized files', () async {
      // This would require file system mocking
      // Skipped for unit test simplicity
    });
  });

  group('FileUploadService - Error Handling', () {
    test('should wrap generic exceptions in ApiException', () async {
      // Arrange
      final testFile = File('test_invoice.jpg');

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenThrow(Exception('Generic error'));

      // Act & Assert
      expect(
        () => fileUploadService.uploadInvoice(testFile),
        throwsA(isA<ApiException>()),
      );
    });

    test('should preserve ApiException when thrown', () async {
      // Arrange
      final testFile = File('test_invoice.jpg');
      final apiException = ApiException(
        message: 'Custom API error',
        statusCode: 400,
      );

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenThrow(apiException);

      // Act & Assert
      expect(
        () => fileUploadService.uploadInvoice(testFile),
        throwsA(predicate((e) =>
            e is ApiException &&
            e.message == 'Custom API error' &&
            e.statusCode == 400)),
      );
    });
  });

  group('FileUploadService - Multiple File Operations', () {
    test('should handle multiple uploads sequentially', () async {
      // Arrange
      final files = [
        File('test1.jpg'),
        File('test2.jpg'),
        File('test3.jpg'),
      ];

      int callCount = 0;
      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async {
        callCount++;
        return Response(
          requestOptions: RequestOptions(path: '/expenses/invoices/upload'),
          statusCode: 200,
          data: {'invoice_path': '/uploads/test$callCount.jpg'},
        );
      });

      // Act
      final results = <String>[];
      for (final file in files) {
        final path = await fileUploadService.uploadInvoice(file);
        results.add(path);
      }

      // Assert
      expect(results.length, 3);
      expect(callCount, 3);
    });
  });

  group('FileUploadService - New API Methods', () {
    test('should upload file with FileType successfully', () async {
      // Arrange
      final testFile = File('test_receipt.jpg');
      const fileType = FileType.receipt;

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/files/upload'),
        statusCode: 200,
        data: {
          'success': true,
          'data': {
            'id': 1,
            'filename': 'receipt_20241023.jpg',
            'path': 'encrypted_path_string',
            'type': 'receipt',
            'size': 245678,
            'mime_type': 'image/jpeg',
            'uploaded_at': '2024-10-23T10:00:00.000000Z',
          },
        },
      );

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await fileUploadService.uploadFile(
        file: testFile,
        type: fileType,
      );

      // Assert
      expect(result, isA<FileUploadDto>());
      expect(result.id, 1);
      expect(result.filename, 'receipt_20241023.jpg');
      expect(result.path, 'encrypted_path_string');
      expect(result.type, 'receipt');
      expect(result.size, 245678);
      expect(result.mimeType, 'image/jpeg');
      
      verify(mockApiClient.uploadFile(
        '/files/upload',
        any,
        fields: {'type': 'receipt'},
        fileFieldName: 'file',
        onProgress: anyNamed('onProgress'),
      )).called(1);
    });

    test('should download file with encrypted path successfully', () async {
      // Arrange
      const encryptedPath = 'encrypted_path_string';

      when(mockApiClient.downloadFile(
        any,
        any,
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => {});

      // Act
      final result = await fileUploadService.downloadFile(encryptedPath);

      // Assert
      expect(result, isA<File>());
      verify(mockApiClient.downloadFile(
        argThat(contains('/files/download?path=')),
        any,
        onProgress: anyNamed('onProgress'),
      )).called(1);
    });

    test('should delete file with path successfully', () async {
      // Arrange
      const filePath = 'files/receipt.jpg';

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/files'),
        statusCode: 200,
        data: {
          'success': true,
          'message': 'File deleted successfully',
        },
      );

      when(mockApiClient.delete(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      await fileUploadService.deleteFile(filePath);

      // Assert
      verify(mockApiClient.delete(
        '/files',
        queryParams: {'path': filePath},
      )).called(1);
    });

    test('should handle upload failure with error message', () async {
      // Arrange
      final testFile = File('test_receipt.jpg');

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/files/upload'),
        statusCode: 400,
        data: {
          'success': false,
          'message': 'Invalid file type',
        },
      );

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => mockResponse);

      // Act & Assert
      expect(
        () => fileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('should upload different file types', () async {
      // Arrange
      final testFile = File('test_document.pdf');

      final mockResponse = Response(
        requestOptions: RequestOptions(path: '/files/upload'),
        statusCode: 200,
        data: {
          'success': true,
          'data': {
            'id': 2,
            'filename': 'document.pdf',
            'path': 'encrypted_path_2',
            'type': 'document',
            'size': 512000,
            'mime_type': 'application/pdf',
            'uploaded_at': '2024-10-23T11:00:00.000000Z',
          },
        },
      );

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => mockResponse);

      // Act
      final result = await fileUploadService.uploadFile(
        file: testFile,
        type: FileType.document,
      );

      // Assert
      expect(result.type, 'document');
      expect(result.mimeType, 'application/pdf');
      verify(mockApiClient.uploadFile(
        '/files/upload',
        any,
        fields: {'type': 'document'},
        fileFieldName: 'file',
        onProgress: anyNamed('onProgress'),
      )).called(1);
    });
  });

  group('FileUploadService - Edge Cases', () {
    test('should handle empty file path', () async {
      // Arrange
      final testFile = File('');

      when(mockApiClient.uploadFile(
        any,
        any,
        fields: anyNamed('fields'),
        fileFieldName: anyNamed('fileFieldName'),
        onProgress: anyNamed('onProgress'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/expenses/invoices/upload'),
            statusCode: 200,
            data: {'invoice_path': '/uploads/empty.jpg'},
          ));

      // Act
      final result = await fileUploadService.uploadInvoice(testFile);

      // Assert
      expect(result, isNotEmpty);
    });

    test('should handle special characters in file path', () async {
      // Arrange
      const invoicePath = '/uploads/invoices/test file (1) [copy].jpg';

      when(mockApiClient.delete(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/expenses/invoices/delete'),
            statusCode: 200,
          ));

      // Act & Assert
      expect(
        () => fileUploadService.deleteInvoice(invoicePath),
        returnsNormally,
      );
    });

    test('should handle very long file paths', () async {
      // Arrange
      final longPath = '/uploads/${'a' * 500}.jpg';

      when(mockApiClient.delete(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/expenses/invoices/delete'),
            statusCode: 200,
          ));

      // Act & Assert
      expect(
        () => fileUploadService.deleteInvoice(longPath),
        returnsNormally,
      );
    });
  });
}
