import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/core/services/file_upload_service.dart';
import 'package:finance_app/core/models/file_upload_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Integration tests for File Upload/Download with Laravel API
/// Tests Requirements: 9.1, 9.2, 9.3, 9.4, 9.5
void main() {
  group('File Upload/Download Laravel Integration Tests', () {
    late ApiClient apiClient;
    late LaravelAuthService authService;
    late FileUploadService fileUploadService;

    setUpAll(() async {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      apiClient = DioApiClient(dio: dio);
      final secureStorage = const FlutterSecureStorage();
      final tokenManager = TokenManager(secureStorage: secureStorage);
      authService = LaravelAuthService(
        apiClient: apiClient,
        tokenManager: tokenManager,
      );

      try {
        final testEmail = 'file_upload_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'File Upload User',
          email: testEmail,
          password: 'TestPassword123!',
        );
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping tests - API not available');
          return;
        }
      }

      fileUploadService = FileUploadServiceImpl(apiClient: apiClient);
    });

    tearDownAll() async {
      await authService.logout();
    });

    test('Upload file with multipart/form-data content type', () async {
      try {
        final testFile = await _createTestFile('test_upload.txt', 'Test content');
        
        final result = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        expect(result, isA<FileUploadDto>());
        expect(result.id, isNotNull);
        expect(result.filename, isNotEmpty);
        expect(result.path, isNotEmpty);
        expect(result.type, equals('receipt'));
        expect(result.size, greaterThan(0));
        expect(result.mimeType, isNotEmpty);
        expect(result.uploadedAt, isNotNull);

        await testFile.delete();
        await fileUploadService.deleteFile(result.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload file with type: receipt', () async {
      try {
        final testFile = await _createTestFile('receipt.jpg', 'Receipt image data');
        
        final result = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        expect(result.type, equals('receipt'));

        await testFile.delete();
        await fileUploadService.deleteFile(result.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload file with type: invoice', () async {
      try {
        final testFile = await _createTestFile('invoice.pdf', 'Invoice PDF data');
        
        final result = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.invoice,
        );

        expect(result.type, equals('invoice'));

        await testFile.delete();
        await fileUploadService.deleteFile(result.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload file with type: document', () async {
      try {
        final testFile = await _createTestFile('document.docx', 'Document data');
        
        final result = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.document,
        );

        expect(result.type, equals('document'));

        await testFile.delete();
        await fileUploadService.deleteFile(result.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload response includes all required fields', () async {
      try {
        final testFile = await _createTestFile('complete_test.txt', 'Complete test data');
        
        final result = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        expect(result.id, isA<int>());
        expect(result.filename, isA<String>());
        expect(result.filename, isNotEmpty);
        expect(result.path, isA<String>());
        expect(result.path, isNotEmpty);
        expect(result.type, isA<String>());
        expect(result.size, isA<int>());
        expect(result.size, greaterThan(0));
        expect(result.mimeType, isA<String>());
        expect(result.mimeType, isNotEmpty);
        expect(result.uploadedAt, isA<DateTime>());

        await testFile.delete();
        await fileUploadService.deleteFile(result.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Download file with encrypted path parameter', () async {
      try {
        final testFile = await _createTestFile('download_test.txt', 'Download test content');
        
        final uploaded = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        final downloaded = await fileUploadService.downloadFile(uploaded.path);

        expect(downloaded.existsSync(), isTrue);
        expect(downloaded.lengthSync(), greaterThan(0));

        final content = await downloaded.readAsString();
        expect(content, equals('Download test content'));

        await testFile.delete();
        await downloaded.delete();
        await fileUploadService.deleteFile(uploaded.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Delete file with path in request body', () async {
      try {
        final testFile = await _createTestFile('delete_test.txt', 'Delete test content');
        
        final uploaded = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        await fileUploadService.deleteFile(uploaded.path);

        // Verify deletion by trying to download (should fail)
        expect(
          () => fileUploadService.downloadFile(uploaded.path),
          throwsA(isA<Exception>()),
        );

        await testFile.delete();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload progress tracking works', () async {
      try {
        final testFile = await _createTestFile('progress_test.txt', 'Progress test content' * 100);
        final progressValues = <double>[];

        await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
          onProgress: (progress) {
            progressValues.add(progress);
          },
        );

        expect(progressValues, isNotEmpty);
        expect(progressValues.first, greaterThanOrEqualTo(0.0));
        expect(progressValues.last, lessThanOrEqualTo(1.0));

        await testFile.delete();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload handles various file sizes', () async {
      try {
        final sizes = [1, 10, 100, 1000]; // KB
        final uploadedPaths = <String>[];

        for (final sizeKb in sizes) {
          final content = 'x' * (sizeKb * 1024);
          final testFile = await _createTestFile('size_test_${sizeKb}kb.txt', content);
          
          final result = await fileUploadService.uploadFile(
            file: testFile,
            type: FileType.document,
          );

          expect(result.size, greaterThanOrEqualTo(sizeKb * 1024));
          uploadedPaths.add(result.path);

          await testFile.delete();
        }

        // Clean up
        for (final path in uploadedPaths) {
          await fileUploadService.deleteFile(path);
        }
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload handles different file extensions', () async {
      try {
        final extensions = ['txt', 'jpg', 'png', 'pdf', 'docx'];
        final uploadedPaths = <String>[];

        for (final ext in extensions) {
          final testFile = await _createTestFile('test.$ext', 'Test content for $ext');
          
          final result = await fileUploadService.uploadFile(
            file: testFile,
            type: FileType.document,
          );

          expect(result.filename, contains(ext));
          uploadedPaths.add(result.path);

          await testFile.delete();
        }

        // Clean up
        for (final path in uploadedPaths) {
          await fileUploadService.deleteFile(path);
        }
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Download preserves file content integrity', () async {
      try {
        final originalContent = 'This is a test file with special characters: !@#\$%^&*()_+-=[]{}|;:,.<>?';
        final testFile = await _createTestFile('integrity_test.txt', originalContent);
        
        final uploaded = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.document,
        );

        final downloaded = await fileUploadService.downloadFile(uploaded.path);
        final downloadedContent = await downloaded.readAsString();

        expect(downloadedContent, equals(originalContent));

        await testFile.delete();
        await downloaded.delete();
        await fileUploadService.deleteFile(uploaded.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Multiple files can be uploaded and managed independently', () async {
      try {
        final file1 = await _createTestFile('multi_1.txt', 'File 1 content');
        final file2 = await _createTestFile('multi_2.txt', 'File 2 content');
        final file3 = await _createTestFile('multi_3.txt', 'File 3 content');

        final result1 = await fileUploadService.uploadFile(file: file1, type: FileType.receipt);
        final result2 = await fileUploadService.uploadFile(file: file2, type: FileType.invoice);
        final result3 = await fileUploadService.uploadFile(file: file3, type: FileType.document);

        expect(result1.path, isNot(equals(result2.path)));
        expect(result2.path, isNot(equals(result3.path)));
        expect(result1.path, isNot(equals(result3.path)));

        // Download all files
        final downloaded1 = await fileUploadService.downloadFile(result1.path);
        final downloaded2 = await fileUploadService.downloadFile(result2.path);
        final downloaded3 = await fileUploadService.downloadFile(result3.path);

        expect(await downloaded1.readAsString(), equals('File 1 content'));
        expect(await downloaded2.readAsString(), equals('File 2 content'));
        expect(await downloaded3.readAsString(), equals('File 3 content'));

        // Clean up
        await file1.delete();
        await file2.delete();
        await file3.delete();
        await downloaded1.delete();
        await downloaded2.delete();
        await downloaded3.delete();
        await fileUploadService.deleteFile(result1.path);
        await fileUploadService.deleteFile(result2.path);
        await fileUploadService.deleteFile(result3.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Encrypted path parameter is properly handled', () async {
      try {
        final testFile = await _createTestFile('encrypted_path_test.txt', 'Encrypted path test');
        
        final uploaded = await fileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        // Path should be encrypted (not a simple file path)
        expect(uploaded.path, isNotEmpty);
        expect(uploaded.path, isNot(contains(uploaded.filename)));

        // Should still be able to download with encrypted path
        final downloaded = await fileUploadService.downloadFile(uploaded.path);
        expect(downloaded.existsSync(), isTrue);

        await testFile.delete();
        await downloaded.delete();
        await fileUploadService.deleteFile(uploaded.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });
  });
}

/// Helper function to create a test file
Future<File> _createTestFile(String filename, String content) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = path.join(tempDir.path, filename);
  final file = File(filePath);
  await file.writeAsString(content);
  return file;
}
