import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/services/file_upload_service.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/core/models/file_upload_dto.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Integration tests for file upload and download
/// Tests Requirements: 29.5, 29.6, 29.7
void main() {
  group('File Upload Integration Tests', () {
    late FileUploadService fileUploadService;
    late ExpenseApiDataSource expenseDataSource;
    late ApiClient apiClient;
    late LaravelAuthService authService;

    setUpAll(() async {
      // Initialize services
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      apiClient = ApiClient(dio);
      final secureStorage = const FlutterSecureStorage();
      final tokenManager = TokenManager(secureStorage);
      authService = LaravelAuthService(apiClient, tokenManager);

      // Register and login a test user
      try {
        final testEmail = 'upload_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register('Upload Test User', testEmail, 'TestPassword123!');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping tests - API not available');
          return;
        }
      }

      fileUploadService = FileUploadService(apiClient);
      expenseDataSource = ExpenseApiDataSource(apiClient);
    });

    tearDownAll(() async {
      await authService.logout();
    });

    test('Upload invoice image to expense', () async {
      try {
        // First create an expense
        final expense = ExpenseDto(
          id: null,
          description: 'Upload Test Expense',
          priceUsd: 100.0,
          priceSyp: null,
          priceTry: null,
          hasInvoice: false,
          invoicePath: null,
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await expenseDataSource.createExpense(expense);
        expect(created.id, isNotNull);

        // Create a test image file
        final testFile = await _createTestImageFile();
        expect(testFile.existsSync(), isTrue);

        // Upload invoice
        final invoicePath = await expenseDataSource.uploadInvoice(
          created.id!,
          testFile,
        );

        expect(invoicePath, isNotNull);
        expect(invoicePath, isNotEmpty);

        // Verify expense has invoice
        final expenses = await expenseDataSource.getExpenses(page: 1, perPage: 100);
        final updated = expenses.firstWhere((e) => e.id == created.id);
        expect(updated.hasInvoice, isTrue);
        expect(updated.invoicePath, isNotNull);

        // Clean up
        await testFile.delete();
        await expenseDataSource.deleteExpense(created.id!);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Download invoice from expense', () async {
      try {
        // Create expense with invoice
        final expense = ExpenseDto(
          id: null,
          description: 'Download Test Expense',
          priceUsd: 150.0,
          priceSyp: null,
          priceTry: null,
          hasInvoice: false,
          invoicePath: null,
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await expenseDataSource.createExpense(expense);
        final testFile = await _createTestImageFile();

        // Upload invoice
        await expenseDataSource.uploadInvoice(created.id!, testFile);

        // Download invoice
        final downloaded = await expenseDataSource.downloadInvoice(created.id!);
        expect(downloaded.existsSync(), isTrue);
        expect(downloaded.lengthSync(), greaterThan(0));

        // Clean up
        await testFile.delete();
        await downloaded.delete();
        await expenseDataSource.deleteExpense(created.id!);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Delete invoice from expense', () async {
      try {
        // Create expense with invoice
        final expense = ExpenseDto(
          id: null,
          description: 'Delete Invoice Test',
          priceUsd: 200.0,
          priceSyp: null,
          priceTry: null,
          hasInvoice: false,
          invoicePath: null,
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await expenseDataSource.createExpense(expense);
        final testFile = await _createTestImageFile();

        // Upload invoice
        await expenseDataSource.uploadInvoice(created.id!, testFile);

        // Delete invoice
        await expenseDataSource.deleteInvoice(created.id!);

        // Verify invoice is deleted
        final expenses = await expenseDataSource.getExpenses(page: 1, perPage: 100);
        final updated = expenses.firstWhere((e) => e.id == created.id);
        expect(updated.hasInvoice, isFalse);
        expect(updated.invoicePath, isNull);

        // Clean up
        await testFile.delete();
        await expenseDataSource.deleteExpense(created.id!);
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
        final expense = ExpenseDto(
          id: null,
          description: 'Progress Test Expense',
          priceUsd: 100.0,
          priceSyp: null,
          priceTry: null,
          hasInvoice: false,
          invoicePath: null,
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await expenseDataSource.createExpense(expense);
        final testFile = await _createTestImageFile();

        int progressCallbacks = 0;
        
        // Upload with progress tracking
        await fileUploadService.uploadFile(
          '/api/v1/expenses/${created.id}/invoice',
          testFile,
          onProgress: (sent, total) {
            progressCallbacks++;
            expect(sent, lessThanOrEqualTo(total));
          },
        );

        // Should have received progress callbacks
        expect(progressCallbacks, greaterThan(0));

        // Clean up
        await testFile.delete();
        await expenseDataSource.deleteExpense(created.id!);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload handles large files', () async {
      try {
        final expense = ExpenseDto(
          id: null,
          description: 'Large File Test',
          priceUsd: 100.0,
          priceSyp: null,
          priceTry: null,
          hasInvoice: false,
          invoicePath: null,
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await expenseDataSource.createExpense(expense);
        
        // Create a larger test file (1MB)
        final testFile = await _createTestImageFile(sizeKb: 1024);
        expect(testFile.lengthSync(), greaterThan(1000000));

        // Upload should succeed
        final invoicePath = await expenseDataSource.uploadInvoice(
          created.id!,
          testFile,
        );

        expect(invoicePath, isNotNull);

        // Clean up
        await testFile.delete();
        await expenseDataSource.deleteExpense(created.id!);
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

  group('New File Upload API Integration Tests', () {
    late FileUploadServiceImpl newFileUploadService;
    late ApiClient apiClient;
    late LaravelAuthService authService;

    setUpAll(() async {
      // Initialize services
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      apiClient = ApiClient(dio);
      final secureStorage = const FlutterSecureStorage();
      final tokenManager = TokenManager(secureStorage);
      authService = LaravelAuthService(apiClient, tokenManager);

      // Register and login a test user
      try {
        final testEmail = 'file_api_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register('File API Test User', testEmail, 'TestPassword123!');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping tests - API not available');
          return;
        }
      }

      newFileUploadService = FileUploadServiceImpl(apiClient: apiClient);
    });

    tearDownAll(() async {
      await authService.logout();
    });

    test('Upload file with FileType.receipt', () async {
      try {
        final testFile = await _createTestImageFile();
        
        final result = await newFileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        expect(result, isA<FileUploadDto>());
        expect(result.id, isNotNull);
        expect(result.filename, isNotEmpty);
        expect(result.path, isNotEmpty);
        expect(result.type, 'receipt');
        expect(result.size, greaterThan(0));
        expect(result.mimeType, isNotEmpty);

        // Clean up
        await testFile.delete();
        await newFileUploadService.deleteFile(result.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload file with FileType.invoice', () async {
      try {
        final testFile = await _createTestImageFile();
        
        final result = await newFileUploadService.uploadFile(
          file: testFile,
          type: FileType.invoice,
        );

        expect(result.type, 'invoice');

        // Clean up
        await testFile.delete();
        await newFileUploadService.deleteFile(result.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Upload file with FileType.document', () async {
      try {
        final testFile = await _createTestImageFile();
        
        final result = await newFileUploadService.uploadFile(
          file: testFile,
          type: FileType.document,
        );

        expect(result.type, 'document');

        // Clean up
        await testFile.delete();
        await newFileUploadService.deleteFile(result.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Download file with encrypted path', () async {
      try {
        // First upload a file
        final testFile = await _createTestImageFile();
        final uploaded = await newFileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        // Download the file
        final downloaded = await newFileUploadService.downloadFile(
          uploaded.path,
        );

        expect(downloaded.existsSync(), isTrue);
        expect(downloaded.lengthSync(), greaterThan(0));

        // Clean up
        await testFile.delete();
        await downloaded.delete();
        await newFileUploadService.deleteFile(uploaded.path);
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Delete file successfully', () async {
      try {
        // Upload a file
        final testFile = await _createTestImageFile();
        final uploaded = await newFileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
        );

        // Delete the file
        await newFileUploadService.deleteFile(uploaded.path);

        // Verify deletion by trying to download (should fail)
        expect(
          () => newFileUploadService.downloadFile(uploaded.path),
          throwsA(isA<Exception>()),
        );

        // Clean up
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

    test('Track upload progress', () async {
      try {
        final testFile = await _createTestImageFile(sizeKb: 100);
        final progressValues = <double>[];

        await newFileUploadService.uploadFile(
          file: testFile,
          type: FileType.receipt,
          onProgress: (progress) {
            progressValues.add(progress);
          },
        );

        expect(progressValues, isNotEmpty);
        expect(progressValues.last, lessThanOrEqualTo(1.0));

        // Clean up
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
  });
}

/// Helper function to create a test image file
Future<File> _createTestImageFile({int sizeKb = 10}) async {
  final tempDir = await getTemporaryDirectory();
  final fileName = 'test_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
  final filePath = path.join(tempDir.path, fileName);
  final file = File(filePath);

  // Create a simple test file with random bytes
  final bytes = List<int>.generate(sizeKb * 1024, (i) => i % 256);
  await file.writeAsBytes(bytes);

  return file;
}
