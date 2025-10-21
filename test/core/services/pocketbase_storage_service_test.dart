import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finance_app/core/services/pocketbase_storage_service.dart';
import 'package:finance_app/core/error/failures.dart';

// Generate mocks
@GenerateMocks([
  PocketBase,
  RecordService,
  RecordModel,
  Connectivity,
  FileService,
])
import 'pocketbase_storage_service_test.mocks.dart';

void main() {
  late PocketBaseStorageService storageService;
  late MockPocketBase mockPocketBase;
  late MockConnectivity mockConnectivity;
  late MockRecordService mockRecordService;
  late MockFileService mockFileService;

  setUp(() {
    mockPocketBase = MockPocketBase();
    mockConnectivity = MockConnectivity();
    mockRecordService = MockRecordService();
    mockFileService = MockFileService();
    
    // Setup default PocketBase behavior
    when(mockPocketBase.collection(any)).thenReturn(mockRecordService);
    when(mockPocketBase.files).thenReturn(mockFileService);

    storageService = PocketBaseStorageService(
      pb: mockPocketBase,
      connectivity: mockConnectivity,
    );
  });

  group('PocketBaseStorageService', () {
    group('isOnline', () {
      test('should return true when connectivity is available', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        // Act
        final result = await storageService.isOnline();

        // Assert
        expect(result, isTrue);
        verify(mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return true when mobile connectivity is available', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);

        // Act
        final result = await storageService.isOnline();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when no connectivity is available', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await storageService.isOnline();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when connectivity check throws exception', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Connectivity check failed'));

        // Act
        final result = await storageService.isOnline();

        // Assert
        expect(result, isFalse);
      });
    });

    group('uploadInvoiceImage', () {
      test('should return NetworkFailure when offline', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await storageService.uploadInvoiceImage(
          localPath: '/path/to/image.jpg',
          userId: 1,
          expenseId: 100,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, contains('No internet connection'));
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should return StorageFailure when file does not exist', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        // Act
        final result = await storageService.uploadInvoiceImage(
          localPath: '/nonexistent/path/image.jpg',
          userId: 1,
          expenseId: 100,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<StorageFailure>());
            expect(failure.message, contains('File not found'));
          },
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getInvoiceImageUrl', () {
      test('should return NetworkFailure when offline', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await storageService.getInvoiceImageUrl('file123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, contains('No internet connection'));
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should return NotFoundFailure when file record does not exist', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRecordService.getOne('file123'))
            .thenThrow(ClientException(statusCode: 404));

        // Act
        final result = await storageService.getInvoiceImageUrl('file123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<NotFoundFailure>());
            expect(failure.message, contains('File not found'));
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should return StorageFailure when file field is empty', () async {
        // Arrange
        final mockRecord = MockRecordModel();
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRecordService.getOne('file123'))
            .thenAnswer((_) async => mockRecord);
        when(mockRecord.data).thenReturn({'file': ''});

        // Act
        final result = await storageService.getInvoiceImageUrl('file123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<StorageFailure>());
            expect(failure.message, contains('File not found in record'));
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should return URL when file exists', () async {
        // Arrange
        final mockRecord = MockRecordModel();
        const expectedUrl = 'https://pocketbase.io/api/files/collection/record/file.jpg';
        final expectedUri = Uri.parse(expectedUrl);
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRecordService.getOne('file123'))
            .thenAnswer((_) async => mockRecord);
        when(mockRecord.data).thenReturn({'file': 'invoice_100_123456.jpg'});
        when(mockFileService.getUrl(mockRecord, 'invoice_100_123456.jpg'))
            .thenReturn(expectedUri);

        // Act
        final result = await storageService.getInvoiceImageUrl('file123');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should return success'),
          (url) => expect(url, equals(expectedUrl)),
        );
      });
    });

    group('downloadInvoiceImage', () {
      test('should return NetworkFailure when offline', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await storageService.downloadInvoiceImage('file123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, contains('No internet connection'));
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should return failure when getInvoiceImageUrl fails', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRecordService.getOne('file123'))
            .thenThrow(ClientException(statusCode: 404));

        // Act
        final result = await storageService.downloadInvoiceImage('file123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('deleteInvoiceImage', () {
      test('should return NetworkFailure when offline', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await storageService.deleteInvoiceImage('file123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, contains('No internet connection'));
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should return success when file is deleted', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRecordService.delete('file123'))
            .thenAnswer((_) async => {});

        // Act
        final result = await storageService.deleteInvoiceImage('file123');

        // Assert
        expect(result.isRight(), isTrue);
        verify(mockRecordService.delete('file123')).called(1);
      });

      test('should return success when file does not exist (404)', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRecordService.delete('file123'))
            .thenThrow(ClientException(statusCode: 404));

        // Act
        final result = await storageService.deleteInvoiceImage('file123');

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should return NetworkFailure when delete fails with network error', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(mockRecordService.delete('file123'))
            .thenThrow(ClientException(statusCode: 500));

        // Act
        final result = await storageService.deleteInvoiceImage('file123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, contains('Network error'));
          },
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
