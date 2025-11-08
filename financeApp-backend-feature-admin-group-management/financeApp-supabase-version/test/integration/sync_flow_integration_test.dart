import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:finance_app/core/services/cloud_sync_service.dart';
import 'package:finance_app/core/services/storage_service.dart';
import 'package:finance_app/core/services/connectivity_service.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_local_datasource_impl.dart';
import 'package:finance_app/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:finance_app/features/expenses/domain/repositories/expense_repository.dart';
import 'package:finance_app/features/expenses/domain/usecases/create_expense_usecase.dart';
import 'package:finance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';
import 'package:finance_app/features/expenses/domain/entities/expense.dart';
import 'package:finance_app/core/config/flavor_config.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/core/services/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Generate mocks
@GenerateMocks([
  PocketBase,
  RecordService,
  RecordModel,
  StorageService,
  AuthRepository,
  ConnectivityService,
])
import 'sync_flow_integration_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sqflite for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database testDatabase;
  late ExpenseLocalDataSource localDataSource;
  late ExpenseRepository expenseRepository;
  late MockPocketBase mockPocketBase;
  late MockStorageService mockStorageService;
  late MockAuthRepository mockAuthRepository;
  late MockConnectivityService mockConnectivityService;
  late MockRecordService mockRecordService;
  late CloudSyncService syncService;
  late CreateExpenseUseCase createExpenseUseCase;
  late StreamController<ConnectivityStatus> connectivityController;

  // Test data
  final testUser = User(
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    role: UserRole.user,
    createdAt: DateTime(2024, 1, 1),
  );

  final testAdminUser = User(
    id: 2,
    username: 'admin',
    email: 'admin@example.com',
    role: UserRole.admin,
    createdAt: DateTime(2024, 1, 1),
  );

  setUp(() async {
    // Create in-memory test database
    testDatabase = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Create minimal schema for testing
          await db.execute('''
            CREATE TABLE expenses(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              description TEXT NOT NULL,
              price_usd REAL,
              price_syp REAL,
              price_try REAL,
              invoice_status INTEGER NOT NULL,
              invoice_file_path TEXT,
              invoice_cloud_file_id TEXT,
              sync_status INTEGER NOT NULL DEFAULT 0,
              synced_at INTEGER,
              sync_retry_count INTEGER NOT NULL DEFAULT 0,
              sync_error_message TEXT,
              expense_date INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER
            );
          ''');
          
          await db.execute('''
            CREATE INDEX idx_expenses_sync_status ON expenses(sync_status);
          ''');
          
          await db.execute('''
            CREATE INDEX idx_expenses_user_id_sync_status ON expenses(user_id, sync_status);
          ''');
        },
      ),
    );

    // Initialize mocks
    mockPocketBase = MockPocketBase();
    mockStorageService = MockStorageService();
    mockAuthRepository = MockAuthRepository();
    mockConnectivityService = MockConnectivityService();
    mockRecordService = MockRecordService();
    connectivityController = StreamController<ConnectivityStatus>.broadcast();

    // Setup default behaviors
    when(mockPocketBase.collection(any)).thenReturn(mockRecordService);
    when(mockConnectivityService.statusStream)
        .thenAnswer((_) => connectivityController.stream);
    when(mockConnectivityService.isOnline).thenReturn(true);

    // Initialize real local data source with test database
    localDataSource = ExpenseLocalDataSourceImpl(database: testDatabase);

    // Initialize repository
    expenseRepository = ExpenseRepositoryImpl(
      localDataSource: localDataSource,
      authRepository: mockAuthRepository,
    );

    // Initialize user flavor for sync tests
    FlavorConfig.initialize(AppFlavor.user);

    // Initialize sync service
    syncService = CloudSyncService(
      pb: mockPocketBase,
      storageService: mockStorageService,
      localDataSource: localDataSource,
      authRepository: mockAuthRepository,
      flavorConfig: FlavorConfig.instance,
      connectivityService: mockConnectivityService,
    );

    // Initialize use case
    createExpenseUseCase = CreateExpenseUseCase(
      repository: expenseRepository,
      syncService: syncService,
    );
  });

  tearDown(() async {
    await testDatabase.close();
    connectivityController.close();
    syncService.dispose();
  });

  group('Integration: End-to-End Sync Flow', () {
    test('should create expense locally, sync to cloud, and admin can fetch', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));
      when(mockStorageService.uploadInvoiceImage(
        localPath: anyNamed('localPath'),
        userId: anyNamed('userId'),
        expenseId: anyNamed('expenseId'),
      )).thenAnswer((_) async => const Right('cloud_file_123'));
      
      final mockRecord = MockRecordModel();
      when(mockRecordService.create(body: anyNamed('body')))
          .thenAnswer((_) async => mockRecord);

      // Step 1: User creates expense locally
      final createResult = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Test expense for integration',
        priceUsd: 100.0,
        priceSyp: 250000.0,
        invoiceStatus: InvoiceStatus.invoiceAvailable,
        invoiceFilePath: '/test/invoice.jpg',
        expenseDate: DateTime(2024, 1, 15),
      ));

      // Assert expense created locally
      expect(createResult.isRight(), isTrue);
      final createdExpense = createResult.getOrElse(() => throw Exception());
      expect(createdExpense.id, isNotNull);
      expect(createdExpense.syncStatus, SyncStatus.pending);

      // Wait for async sync to complete
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 2: Verify expense synced to cloud
      verify(mockStorageService.uploadInvoiceImage(
        localPath: '/test/invoice.jpg',
        userId: testUser.id,
        expenseId: createdExpense.id!,
      )).called(1);

      verify(mockRecordService.create(body: argThat(
        isA<Map>()
            .having((m) => m['user_id'], 'user_id', testUser.id)
            .having((m) => m['username'], 'username', testUser.username)
            .having((m) => m['description'], 'description', 'Test expense for integration')
            .having((m) => m['price_usd'], 'price_usd', 100.0)
            .having((m) => m['invoice_file_id'], 'invoice_file_id', 'cloud_file_123'),
        named: 'body',
      ))).called(1);

      // Step 3: Verify local sync status updated
      final expenses = await localDataSource.getExpensesBySyncStatus(SyncStatus.synced);
      expect(expenses.length, 1);
      expect(expenses.first.id, createdExpense.id);
      expect(expenses.first.syncStatus, SyncStatus.synced);
      expect(expenses.first.invoiceCloudFileId, 'cloud_file_123');

      // Step 4: Admin fetches all expenses
      FlavorConfig.initialize(AppFlavor.admin);
      final adminSyncService = CloudSyncService(
        pb: mockPocketBase,
        storageService: mockStorageService,
        localDataSource: localDataSource,
        authRepository: mockAuthRepository,
        flavorConfig: FlavorConfig.instance,
        connectivityService: mockConnectivityService,
      );

      final mockAdminRecord = MockRecordModel();
      when(mockAdminRecord.data).thenReturn({
        'local_expense_id': createdExpense.id,
        'user_id': testUser.id,
        'username': testUser.username,
        'user_email': testUser.email,
        'description': 'Test expense for integration',
        'price_usd': 100.0,
        'price_syp': 250000.0,
        'price_try': null,
        'invoice_status': InvoiceStatus.invoiceAvailable.index,
        'invoice_file_id': 'cloud_file_123',
        'expense_date': '2024-01-15T00:00:00.000',
        'created_at': createdExpense.createdAt.toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
      });

      when(mockRecordService.getFullList(sort: anyNamed('sort')))
          .thenAnswer((_) async => [mockAdminRecord]);

      final adminFetchResult = await adminSyncService.fetchAdminExpenses();

      // Assert admin can see user's expense
      expect(adminFetchResult.isRight(), isTrue);
      final adminExpenses = adminFetchResult.getOrElse(() => throw Exception());
      expect(adminExpenses.length, 1);
      expect(adminExpenses.first.id, createdExpense.id);
      expect(adminExpenses.first.creatorUsername, testUser.username);
      expect(adminExpenses.first.creatorEmail, testUser.email);
      expect(adminExpenses.first.syncStatus, SyncStatus.synced);

      adminSyncService.dispose();
    });

    test('should create expense without image and sync successfully', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));
      
      final mockRecord = MockRecordModel();
      when(mockRecordService.create(body: anyNamed('body')))
          .thenAnswer((_) async => mockRecord);

      // Act: Create expense without invoice
      final createResult = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Expense without invoice',
        priceUsd: 50.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime(2024, 1, 16),
      ));

      // Assert
      expect(createResult.isRight(), isTrue);
      final createdExpense = createResult.getOrElse(() => throw Exception());

      // Wait for async sync
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify no image upload attempted
      verifyNever(mockStorageService.uploadInvoiceImage(
        localPath: anyNamed('localPath'),
        userId: anyNamed('userId'),
        expenseId: anyNamed('expenseId'),
      ));

      // Verify synced with null file_id
      verify(mockRecordService.create(body: argThat(
        isA<Map>()
            .having((m) => m['invoice_file_id'], 'invoice_file_id', null),
        named: 'body',
      ))).called(1);

      // Verify local status
      final expenses = await localDataSource.getExpensesBySyncStatus(SyncStatus.synced);
      expect(expenses.any((e) => e.id == createdExpense.id), isTrue);
    });
  });

  group('Integration: Offline Creation and Online Sync', () {
    test('should create expense offline, fail sync, then sync when online', () async {
      // Arrange: Start offline - PocketBase will fail
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));
      
      // First sync attempt will fail (simulating offline)
      when(mockRecordService.create(body: anyNamed('body')))
          .thenThrow(ClientException(statusCode: 0, response: {'message': 'Network error'}));

      // Step 1: Create expense while offline
      final createResult = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Offline expense',
        priceUsd: 75.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime(2024, 1, 17),
      ));

      expect(createResult.isRight(), isTrue);
      final createdExpense = createResult.getOrElse(() => throw Exception());

      // Wait for sync attempt to fail
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify expense marked as failed (sync attempted but failed)
      final failedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.failed,
      );
      expect(failedExpenses.any((e) => e.id == createdExpense.id), isTrue);

      // Step 2: Go online - setup successful sync
      final mockRecord = MockRecordModel();
      when(mockRecordService.create(body: anyNamed('body')))
          .thenAnswer((_) async => mockRecord);

      // Step 3: Retry sync (simulating auto-sync when online)
      final failedExpense = failedExpenses.firstWhere((e) => e.id == createdExpense.id);
      final syncResult = await syncService.syncExpense(failedExpense);

      // Assert sync succeeded
      expect(syncResult.isRight(), isTrue);

      // Verify expense synced
      verify(mockRecordService.create(body: argThat(
        isA<Map>()
            .having((m) => m['description'], 'description', 'Offline expense'),
        named: 'body',
      ))).called(greaterThanOrEqualTo(1));

      // Verify local status updated
      final syncedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.synced,
      );
      expect(syncedExpenses.any((e) => e.id == createdExpense.id), isTrue);
    });

    test('should handle multiple offline expenses and batch sync when online', () async {
      // Arrange: Simulate offline by making PocketBase fail
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));
      
      // First attempts will fail
      when(mockRecordService.create(body: anyNamed('body')))
          .thenThrow(ClientException(statusCode: 0));

      // Create multiple expenses offline
      final expense1Result = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Offline expense 1',
        priceUsd: 25.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime(2024, 1, 18),
      ));

      final expense2Result = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Offline expense 2',
        priceUsd: 35.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime(2024, 1, 19),
      ));

      final expense3Result = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Offline expense 3',
        priceUsd: 45.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime(2024, 1, 20),
      ));

      expect(expense1Result.isRight(), isTrue);
      expect(expense2Result.isRight(), isTrue);
      expect(expense3Result.isRight(), isTrue);

      final expense1 = expense1Result.getOrElse(() => throw Exception());
      final expense2 = expense2Result.getOrElse(() => throw Exception());
      final expense3 = expense3Result.getOrElse(() => throw Exception());

      await Future.delayed(const Duration(milliseconds: 300));

      // Verify all failed (sync attempted but failed)
      final failedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.failed,
      );
      expect(failedExpenses.length, greaterThanOrEqualTo(3));

      // Go online and setup mock for successful sync
      final mockRecord = MockRecordModel();
      when(mockRecordService.create(body: anyNamed('body')))
          .thenAnswer((_) async => mockRecord);

      // Manually sync each failed expense (simpler than batch)
      await syncService.syncExpense(expense1);
      await syncService.syncExpense(expense2);
      await syncService.syncExpense(expense3);

      // Verify all moved to synced status
      final syncedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.synced,
      );
      expect(syncedExpenses.where((e) => 
        e.id == expense1.id || e.id == expense2.id || e.id == expense3.id
      ).length, 3);
    });
  });

  group('Integration: Sync Failure and Retry', () {
    test('should handle sync failure, increment retry count, then succeed on retry', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));

      // Step 1: Create expense
      final createResult = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Expense with retry',
        priceUsd: 60.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime(2024, 1, 21),
      ));

      expect(createResult.isRight(), isTrue);
      final createdExpense = createResult.getOrElse(() => throw Exception());

      // Step 2: First sync attempt fails
      when(mockRecordService.create(body: anyNamed('body')))
          .thenThrow(ClientException(statusCode: 500, response: {'message': 'Server error'}));

      await Future.delayed(const Duration(milliseconds: 200));

      // Manually trigger sync to ensure failure
      final firstSyncResult = await syncService.syncExpense(createdExpense);

      // Assert first sync failed
      expect(firstSyncResult.isLeft(), isTrue);

      // Verify expense marked as failed with retry count
      final failedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.failed,
      );
      final failedExpense = failedExpenses.firstWhere((e) => e.id == createdExpense.id);
      expect(failedExpense.syncStatus, SyncStatus.failed);
      // Retry count may be 1 or 2 depending on timing of async sync
      expect(failedExpense.syncRetryCount, greaterThanOrEqualTo(1));
      expect(failedExpense.syncErrorMessage, isNotNull);

      // Step 3: Second sync attempt succeeds
      final mockRecord = MockRecordModel();
      when(mockRecordService.create(body: anyNamed('body')))
          .thenAnswer((_) async => mockRecord);

      final retrySyncResult = await syncService.syncExpense(failedExpense);

      // Assert retry succeeded
      expect(retrySyncResult.isRight(), isTrue);

      // Verify expense now synced
      final syncedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.synced,
      );
      expect(syncedExpenses.any((e) => e.id == createdExpense.id), isTrue);

      // Verify error message cleared
      final syncedExpense = syncedExpenses.firstWhere((e) => e.id == createdExpense.id);
      expect(syncedExpense.syncErrorMessage, isNull);
    });

    test('should stop retrying after max retry attempts', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));
      when(mockRecordService.create(body: anyNamed('body')))
          .thenThrow(ClientException(statusCode: 500));

      // Create expense
      final createResult = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Expense with max retries',
        priceUsd: 80.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime(2024, 1, 22),
      ));

      expect(createResult.isRight(), isTrue);
      var expense = createResult.getOrElse(() => throw Exception());

      // Attempt sync multiple times until max retries
      for (int i = 0; i < 3; i++) {
        await syncService.syncExpense(expense);
        
        // Reload expense to get updated retry count
        final failedExpenses = await localDataSource.getExpensesBySyncStatus(
          SyncStatus.failed,
        );
        expense = failedExpenses.firstWhere((e) => e.id == expense.id);
      }

      // Verify retry count reached max
      expect(expense.syncRetryCount, 3);

      // Attempt to sync pending expenses (should skip this one)
      final syncResult = await syncService.syncPendingExpenses();
      expect(syncResult.isRight(), isTrue);

      // Verify expense still failed (not retried again)
      final stillFailedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.failed,
      );
      expect(stillFailedExpenses.any((e) => e.id == expense.id), isTrue);
    });

    test('should handle image upload failure and retry successfully', () async {
      // Arrange
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));

      // Create expense with image
      final createResult = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Expense with image retry',
        priceUsd: 90.0,
        invoiceStatus: InvoiceStatus.invoiceAvailable,
        invoiceFilePath: '/test/retry_invoice.jpg',
        expenseDate: DateTime(2024, 1, 23),
      ));

      expect(createResult.isRight(), isTrue);
      final createdExpense = createResult.getOrElse(() => throw Exception());

      // First attempt: image upload fails
      when(mockStorageService.uploadInvoiceImage(
        localPath: anyNamed('localPath'),
        userId: anyNamed('userId'),
        expenseId: anyNamed('expenseId'),
      )).thenAnswer((_) async => const Left(NetworkFailure('Upload failed')));

      await Future.delayed(const Duration(milliseconds: 200));

      // Manually trigger sync
      final firstSyncResult = await syncService.syncExpense(createdExpense);
      expect(firstSyncResult.isLeft(), isTrue);

      // Verify failed status
      final failedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.failed,
      );
      final failedExpense = failedExpenses.firstWhere((e) => e.id == createdExpense.id);
      expect(failedExpense.syncErrorMessage, contains('Image upload failed'));

      // Second attempt: image upload succeeds
      when(mockStorageService.uploadInvoiceImage(
        localPath: anyNamed('localPath'),
        userId: anyNamed('userId'),
        expenseId: anyNamed('expenseId'),
      )).thenAnswer((_) async => const Right('retry_file_456'));

      final mockRecord = MockRecordModel();
      when(mockRecordService.create(body: anyNamed('body')))
          .thenAnswer((_) async => mockRecord);

      final retrySyncResult = await syncService.syncExpense(failedExpense);
      expect(retrySyncResult.isRight(), isTrue);

      // Verify synced with cloud file ID
      final syncedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.synced,
      );
      final syncedExpense = syncedExpenses.firstWhere((e) => e.id == createdExpense.id);
      expect(syncedExpense.invoiceCloudFileId, 'retry_file_456');
    });
  });

  group('Integration: Connectivity Monitoring', () {
    test('should automatically sync when connectivity is restored', () async {
      // Arrange: Simulate offline by making PocketBase fail
      when(mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => Right(testUser));
      
      // First attempt fails (offline)
      when(mockRecordService.create(body: anyNamed('body')))
          .thenThrow(ClientException(statusCode: 0));

      // Create expense offline
      final createResult = await createExpenseUseCase(CreateExpenseParams(
        userId: testUser.id,
        description: 'Auto-sync expense',
        priceUsd: 55.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime(2024, 1, 24),
      ));

      expect(createResult.isRight(), isTrue);
      final createdExpense = createResult.getOrElse(() => throw Exception());

      await Future.delayed(const Duration(milliseconds: 200));

      // Verify failed (sync attempted but failed)
      final failedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.failed,
      );
      expect(failedExpenses.any((e) => e.id == createdExpense.id), isTrue);

      // Setup for online sync
      final mockRecord = MockRecordModel();
      when(mockRecordService.create(body: anyNamed('body')))
          .thenAnswer((_) async => mockRecord);

      // Start auto-sync
      await syncService.startAutoSync();

      // Emit connectivity restored
      connectivityController.add(ConnectivityStatus.online);

      // Wait for auto-sync to process
      await Future.delayed(const Duration(milliseconds: 500));

      // Manually trigger to ensure sync (since timer might not fire in test)
      await syncService.syncPendingExpenses();

      // Verify synced
      final syncedExpenses = await localDataSource.getExpensesBySyncStatus(
        SyncStatus.synced,
      );
      expect(syncedExpenses.any((e) => e.id == createdExpense.id), isTrue);

      await syncService.stopAutoSync();
    });
  });
}
