import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:finance_app/core/services/cloud_sync_service.dart';
import 'package:finance_app/core/services/storage_service.dart';
import 'package:finance_app/core/services/connectivity_service.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:finance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';
import 'package:finance_app/features/expenses/domain/entities/expense.dart';
import 'package:finance_app/features/expenses/data/models/expense_model.dart';
import 'package:finance_app/core/config/flavor_config.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/core/models/sync_status.dart';

// Generate mocks
@GenerateMocks([
  PocketBase,
  RecordService,
  RecordModel,
  StorageService,
  ExpenseLocalDataSource,
  AuthRepository,
  ConnectivityService,
])
import 'cloud_sync_service_test.mocks.dart';

void main() {
  late CloudSyncService syncService;
  late MockPocketBase mockPocketBase;
  late MockStorageService mockStorageService;
  late MockExpenseLocalDataSource mockLocalDataSource;
  late MockAuthRepository mockAuthRepository;
  late MockConnectivityService mockConnectivityService;
  late MockRecordService mockRecordService;
  late StreamController<ConnectivityStatus> connectivityController;

  // Test data
  final testUser = User(
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    role: UserRole.user,
    createdAt: DateTime(2024, 1, 1),
  );

  final testExpense = ExpenseModel(
    id: 100,
    userId: 1,
    description: 'Test expense',
    priceUsd: 50.0,
    priceSyp: 125000.0,
    priceTry: 1500.0,
    invoiceStatus: InvoiceStatus.invoiceAvailable,
    invoiceFilePath: '/path/to/invoice.jpg',
    syncStatus: SyncStatus.pending,
    syncRetryCount: 0,
    expenseDate: DateTime(2024, 1, 15),
    createdAt: DateTime(2024, 1, 15),
  );

  final testExpenseWithoutImage = ExpenseModel(
    id: 101,
    userId: 1,
    description: 'Test expense without image',
    priceUsd: 30.0,
    invoiceStatus: InvoiceStatus.noInvoice,
    syncStatus: SyncStatus.pending,
    syncRetryCount: 0,
    expenseDate: DateTime(2024, 1, 16),
    createdAt: DateTime(2024, 1, 16),
  );

  setUp(() {
    mockPocketBase = MockPocketBase();
    mockStorageService = MockStorageService();
    mockLocalDataSource = MockExpenseLocalDataSource();
    mockAuthRepository = MockAuthRepository();
    mockConnectivityService = MockConnectivityService();
    mockRecordService = MockRecordService();
    connectivityController = StreamController<ConnectivityStatus>.broadcast();

    // Setup default PocketBase behavior
    when(mockPocketBase.collection(any)).thenReturn(mockRecordService);

    // Setup connectivity service
    when(mockConnectivityService.statusStream)
        .thenAnswer((_) => connectivityController.stream);
  });

  tearDown(() {
    connectivityController.close();
  });

  group('CloudSyncService - User Flavor', () {
    setUp(() {
      // Initialize with user flavor
      FlavorConfig.initialize(AppFlavor.user);

      syncService = CloudSyncService(
        pb: mockPocketBase,
        storageService: mockStorageService,
        localDataSource: mockLocalDataSource,
        authRepository: mockAuthRepository,
        flavorConfig: FlavorConfig.instance,
        connectivityService: mockConnectivityService,
      );
    });

    tearDown(() {
      syncService.dispose();
    });

    group('syncExpense', () {
      test('should successfully sync expense with image', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));
        when(mockLocalDataSource.updateSyncStatus(any, any))
            .thenAnswer((_) async => {});
        when(mockStorageService.uploadInvoiceImage(
          localPath: anyNamed('localPath'),
          userId: anyNamed('userId'),
          expenseId: anyNamed('expenseId'),
        )).thenAnswer((_) async => const Right('file123'));
        when(mockRecordService.create(body: anyNamed('body')))
            .thenAnswer((_) async => MockRecordModel());
        when(mockLocalDataSource.updateCloudFileId(any, any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.updateSyncErrorMessage(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await syncService.syncExpense(testExpense);

        // Assert
        expect(result.isRight(), isTrue);
        
        // Verify sync status progression: pending -> syncing -> synced
        verify(mockLocalDataSource.updateSyncStatus(100, SyncStatus.syncing)).called(1);
        verify(mockLocalDataSource.updateSyncStatus(100, SyncStatus.synced)).called(1);
        
        // Verify image upload
        verify(mockStorageService.uploadInvoiceImage(
          localPath: '/path/to/invoice.jpg',
          userId: 1,
          expenseId: 100,
        )).called(1);
        
        // Verify PocketBase record creation
        verify(mockRecordService.create(body: argThat(
          isA<Map>()
              .having((m) => m['user_id'], 'user_id', 1)
              .having((m) => m['username'], 'username', 'testuser')
              .having((m) => m['user_email'], 'user_email', 'test@example.com')
              .having((m) => m['local_expense_id'], 'local_expense_id', 100)
              .having((m) => m['description'], 'description', 'Test expense')
              .having((m) => m['price_usd'], 'price_usd', 50.0)
              .having((m) => m['invoice_file_id'], 'invoice_file_id', 'file123'),
          named: 'body',
        ))).called(1);
        
        // Verify cloud file ID update
        verify(mockLocalDataSource.updateCloudFileId(100, 'file123')).called(1);
        
        // Verify error message cleared
        verify(mockLocalDataSource.updateSyncErrorMessage(100, null)).called(1);
      });

      test('should successfully sync expense without image', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));
        when(mockLocalDataSource.updateSyncStatus(any, any))
            .thenAnswer((_) async => {});
        when(mockRecordService.create(body: anyNamed('body')))
            .thenAnswer((_) async => MockRecordModel());
        when(mockLocalDataSource.updateCloudFileId(any, any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.updateSyncErrorMessage(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await syncService.syncExpense(testExpenseWithoutImage);

        // Assert
        expect(result.isRight(), isTrue);
        
        // Verify no image upload attempted
        verifyNever(mockStorageService.uploadInvoiceImage(
          localPath: anyNamed('localPath'),
          userId: anyNamed('userId'),
          expenseId: anyNamed('expenseId'),
        ));
        
        // Verify PocketBase record creation with null file_id
        verify(mockRecordService.create(body: argThat(
          isA<Map>().having((m) => m['invoice_file_id'], 'invoice_file_id', null),
          named: 'body',
        ))).called(1);
      });

      test('should return ValidationFailure when expense has no ID', () async {
        // Arrange
        final expenseWithoutId = Expense(
          userId: 1,
          description: 'Test',
          invoiceStatus: InvoiceStatus.noInvoice,
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // Act
        final result = await syncService.syncExpense(expenseWithoutId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('must have an ID'));
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should return UnauthorizedFailure when user not authenticated', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => const Left(UnauthorizedFailure('Not authenticated')));

        // Act
        final result = await syncService.syncExpense(testExpense);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<UnauthorizedFailure>());
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should handle image upload failure and update sync status', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));
        when(mockLocalDataSource.updateSyncStatus(any, any))
            .thenAnswer((_) async => {});
        when(mockStorageService.uploadInvoiceImage(
          localPath: anyNamed('localPath'),
          userId: anyNamed('userId'),
          expenseId: anyNamed('expenseId'),
        )).thenAnswer((_) async => const Left(NetworkFailure('Upload failed')));
        when(mockLocalDataSource.incrementSyncRetryCount(any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.updateSyncErrorMessage(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await syncService.syncExpense(testExpense);

        // Assert
        expect(result.isLeft(), isTrue);
        
        // Verify sync status updated to failed
        verify(mockLocalDataSource.updateSyncStatus(100, SyncStatus.syncing)).called(1);
        verify(mockLocalDataSource.updateSyncStatus(100, SyncStatus.failed)).called(1);
        
        // Verify retry count incremented
        verify(mockLocalDataSource.incrementSyncRetryCount(100)).called(1);
        
        // Verify error message updated
        verify(mockLocalDataSource.updateSyncErrorMessage(
          100,
          argThat(contains('Image upload failed')),
        )).called(1);
      });

      test('should handle PocketBase sync failure and update status', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));
        when(mockLocalDataSource.updateSyncStatus(any, any))
            .thenAnswer((_) async => {});
        when(mockRecordService.create(body: anyNamed('body')))
            .thenThrow(ClientException(statusCode: 500));
        when(mockLocalDataSource.incrementSyncRetryCount(any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.updateSyncErrorMessage(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await syncService.syncExpense(testExpenseWithoutImage);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<SyncFailure>());
          },
          (_) => fail('Should return failure'),
        );
        
        // Verify status updated to failed
        verify(mockLocalDataSource.updateSyncStatus(101, SyncStatus.failed)).called(1);
        verify(mockLocalDataSource.incrementSyncRetryCount(101)).called(1);
      });
    });

    group('syncPendingExpenses', () {
      test('should sync all pending expenses in batch', () async {
        // Arrange
        final pendingExpenses = [testExpense, testExpenseWithoutImage];
        
        when(mockLocalDataSource.getExpensesBySyncStatus(SyncStatus.pending))
            .thenAnswer((_) async => pendingExpenses);
        when(mockLocalDataSource.getExpensesBySyncStatus(SyncStatus.failed))
            .thenAnswer((_) async => []);
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));
        when(mockLocalDataSource.updateSyncStatus(any, any))
            .thenAnswer((_) async => {});
        when(mockStorageService.uploadInvoiceImage(
          localPath: anyNamed('localPath'),
          userId: anyNamed('userId'),
          expenseId: anyNamed('expenseId'),
        )).thenAnswer((_) async => const Right('file123'));
        when(mockRecordService.create(body: anyNamed('body')))
            .thenAnswer((_) async => MockRecordModel());
        when(mockLocalDataSource.updateCloudFileId(any, any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.updateSyncErrorMessage(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await syncService.syncPendingExpenses();

        // Assert
        expect(result.isRight(), isTrue);
        
        // Verify both expenses were synced
        verify(mockRecordService.create(body: anyNamed('body'))).called(2);
      });

      test('should retry failed expenses that have not exceeded max retries', () async {
        // Arrange
        final failedExpense = ExpenseModel(
          id: 102,
          userId: 1,
          description: 'Failed expense',
          invoiceStatus: InvoiceStatus.noInvoice,
          syncStatus: SyncStatus.failed,
          syncRetryCount: 1, // Less than max retries (3)
          expenseDate: DateTime(2024, 1, 17),
          createdAt: DateTime(2024, 1, 17),
        );
        
        when(mockLocalDataSource.getExpensesBySyncStatus(SyncStatus.pending))
            .thenAnswer((_) async => []);
        when(mockLocalDataSource.getExpensesBySyncStatus(SyncStatus.failed))
            .thenAnswer((_) async => [failedExpense]);
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));
        when(mockLocalDataSource.updateSyncStatus(any, any))
            .thenAnswer((_) async => {});
        when(mockRecordService.create(body: anyNamed('body')))
            .thenAnswer((_) async => MockRecordModel());
        when(mockLocalDataSource.updateCloudFileId(any, any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.updateSyncErrorMessage(any, any))
            .thenAnswer((_) async => {});

        // Act
        final result = await syncService.syncPendingExpenses();

        // Assert
        expect(result.isRight(), isTrue);
        
        // Verify failed expense was retried
        verify(mockRecordService.create(body: anyNamed('body'))).called(1);
      });

      test('should not retry failed expenses that exceeded max retries', () async {
        // Arrange
        final failedExpense = ExpenseModel(
          id: 103,
          userId: 1,
          description: 'Failed expense',
          invoiceStatus: InvoiceStatus.noInvoice,
          syncStatus: SyncStatus.failed,
          syncRetryCount: 3, // Equals max retries
          expenseDate: DateTime(2024, 1, 17),
          createdAt: DateTime(2024, 1, 17),
        );
        
        when(mockLocalDataSource.getExpensesBySyncStatus(SyncStatus.pending))
            .thenAnswer((_) async => []);
        when(mockLocalDataSource.getExpensesBySyncStatus(SyncStatus.failed))
            .thenAnswer((_) async => [failedExpense]);

        // Act
        final result = await syncService.syncPendingExpenses();

        // Assert
        expect(result.isRight(), isTrue);
        
        // Verify no sync attempted
        verifyNever(mockRecordService.create(body: anyNamed('body')));
      });

      test('should return success when no pending expenses', () async {
        // Arrange
        when(mockLocalDataSource.getExpensesBySyncStatus(SyncStatus.pending))
            .thenAnswer((_) async => []);
        when(mockLocalDataSource.getExpensesBySyncStatus(SyncStatus.failed))
            .thenAnswer((_) async => []);

        // Act
        final result = await syncService.syncPendingExpenses();

        // Assert
        expect(result.isRight(), isTrue);
      });
    });

    group('watchSyncStatus', () {
      test('should emit sync status updates for specific expense', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(testUser));
        when(mockLocalDataSource.updateSyncStatus(any, any))
            .thenAnswer((_) async => {});
        when(mockRecordService.create(body: anyNamed('body')))
            .thenAnswer((_) async => MockRecordModel());
        when(mockLocalDataSource.updateCloudFileId(any, any))
            .thenAnswer((_) async => {});
        when(mockLocalDataSource.updateSyncErrorMessage(any, any))
            .thenAnswer((_) async => {});

        // Act
        final statusStream = syncService.watchSyncStatus(101);
        final statuses = <SyncStatus>[];
        
        // Listen to status updates
        final subscription = statusStream.listen(statuses.add);
        
        // Trigger sync
        await syncService.syncExpense(testExpenseWithoutImage);
        
        // Wait for stream to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(statuses, contains(SyncStatus.syncing));
        expect(statuses, contains(SyncStatus.synced));
        
        await subscription.cancel();
      });
    });

    group('autoSync', () {
      test('should start and stop auto sync', () async {
        // Act
        await syncService.startAutoSync();
        await syncService.stopAutoSync();

        // Assert - no exceptions thrown
        expect(true, isTrue);
      });
    });
  });

  group('CloudSyncService - Admin Flavor', () {
    setUp(() {
      // Initialize with admin flavor
      FlavorConfig.initialize(AppFlavor.admin);

      syncService = CloudSyncService(
        pb: mockPocketBase,
        storageService: mockStorageService,
        localDataSource: mockLocalDataSource,
        authRepository: mockAuthRepository,
        flavorConfig: FlavorConfig.instance,
        connectivityService: mockConnectivityService,
      );
    });

    tearDown(() {
      syncService.dispose();
    });

    group('syncExpense', () {
      test('should not sync expenses in admin flavor', () async {
        // Act
        final result = await syncService.syncExpense(testExpense);

        // Assert
        expect(result.isRight(), isTrue);
        
        // Verify no sync operations performed
        verifyNever(mockAuthRepository.getCurrentUser());
        verifyNever(mockStorageService.uploadInvoiceImage(
          localPath: anyNamed('localPath'),
          userId: anyNamed('userId'),
          expenseId: anyNamed('expenseId'),
        ));
        verifyNever(mockRecordService.create(body: anyNamed('body')));
      });
    });

    group('fetchAdminExpenses', () {
      test('should successfully fetch all expenses in admin flavor', () async {
        // Arrange
        final mockRecord1 = MockRecordModel();
        final mockRecord2 = MockRecordModel();
        
        when(mockRecord1.data).thenReturn({
          'local_expense_id': 100,
          'user_id': 1,
          'username': 'user1',
          'user_email': 'user1@example.com',
          'description': 'Expense 1',
          'price_usd': 50.0,
          'price_syp': 125000.0,
          'price_try': 1500.0,
          'invoice_status': 0,
          'invoice_file_id': 'file123',
          'expense_date': '2024-01-15T00:00:00.000',
          'created_at': '2024-01-15T10:00:00.000',
          'synced_at': '2024-01-15T10:05:00.000',
        });
        
        when(mockRecord2.data).thenReturn({
          'local_expense_id': 101,
          'user_id': 2,
          'username': 'user2',
          'user_email': 'user2@example.com',
          'description': 'Expense 2',
          'price_usd': 30.0,
          'price_syp': null,
          'price_try': null,
          'invoice_status': 1,
          'invoice_file_id': null,
          'expense_date': '2024-01-16T00:00:00.000',
          'created_at': '2024-01-16T10:00:00.000',
          'synced_at': '2024-01-16T10:05:00.000',
        });
        
        when(mockRecordService.getFullList(sort: anyNamed('sort')))
            .thenAnswer((_) async => [mockRecord1, mockRecord2]);

        // Act
        final result = await syncService.fetchAdminExpenses();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should return success'),
          (expenses) {
            expect(expenses.length, 2);
            
            // Verify first expense
            expect(expenses[0].id, 100);
            expect(expenses[0].userId, 1);
            expect(expenses[0].creatorUsername, 'user1');
            expect(expenses[0].creatorEmail, 'user1@example.com');
            expect(expenses[0].description, 'Expense 1');
            expect(expenses[0].priceUsd, 50.0);
            expect(expenses[0].invoiceCloudFileId, 'file123');
            expect(expenses[0].syncStatus, SyncStatus.synced);
            
            // Verify second expense
            expect(expenses[1].id, 101);
            expect(expenses[1].userId, 2);
            expect(expenses[1].creatorUsername, 'user2');
            expect(expenses[1].invoiceStatus, InvoiceStatus.noInvoice);
          },
        );
        
        // Verify PocketBase query
        verify(mockRecordService.getFullList(sort: '-created_at')).called(1);
      });

      test('should return SyncFailure when PocketBase fetch fails', () async {
        // Arrange
        when(mockRecordService.getFullList(sort: anyNamed('sort')))
            .thenThrow(ClientException(statusCode: 500));

        // Act
        final result = await syncService.fetchAdminExpenses();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<SyncFailure>());
            expect(failure.message, contains('Failed to fetch admin expenses'));
          },
          (_) => fail('Should return failure'),
        );
      });
    });

    group('fetchAdminExpenses - User Flavor', () {
      test('should return UnauthorizedFailure in user flavor', () async {
        // Arrange - reinitialize with user flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userSyncService = CloudSyncService(
          pb: mockPocketBase,
          storageService: mockStorageService,
          localDataSource: mockLocalDataSource,
          authRepository: mockAuthRepository,
          flavorConfig: FlavorConfig.instance,
          connectivityService: mockConnectivityService,
        );

        // Act
        final result = await userSyncService.fetchAdminExpenses();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<UnauthorizedFailure>());
            expect(failure.message, contains('Admin access required'));
          },
          (_) => fail('Should return failure'),
        );
        
        // Verify no PocketBase query attempted
        verifyNever(mockRecordService.getFullList(sort: anyNamed('sort')));
        
        userSyncService.dispose();
      });
    });
  });
}
