import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../../features/expenses/data/datasources/expense_local_datasource.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../config/flavor_config.dart';
import '../error/failures.dart';
import '../models/sync_status.dart';
import 'sync_service.dart';
import 'storage_service.dart';
import 'connectivity_service.dart';

/// Cloud synchronization service implementation using PocketBase
/// Handles one-way sync from User version to Admin version
class CloudSyncService implements SyncService {
  final PocketBase _pb;
  final StorageService _storageService;
  final ExpenseLocalDataSource _localDataSource;
  final AuthRepository _authRepository;
  final FlavorConfig _flavorConfig;
  final ConnectivityService _connectivityService;

  Timer? _autoSyncTimer;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  final _syncStatusController = StreamController<Map<int, SyncStatus>>.broadcast();
  final Map<int, SyncStatus> _syncStatusMap = {};
  final _syncNotificationController = StreamController<String>.broadcast();
  bool _wasOffline = false;

  CloudSyncService({
    required PocketBase pb,
    required StorageService storageService,
    required ExpenseLocalDataSource localDataSource,
    required AuthRepository authRepository,
    required FlavorConfig flavorConfig,
    required ConnectivityService connectivityService,
  })  : _pb = pb,
        _storageService = storageService,
        _localDataSource = localDataSource,
        _authRepository = authRepository,
        _flavorConfig = flavorConfig,
        _connectivityService = connectivityService {
    _initializeConnectivityMonitoring();
  }

  @override
  Future<Either<Failure, void>> syncExpense(Expense expense) async {
    try {
      // Only sync from user version
      if (_flavorConfig.flavor != AppFlavor.user) {
        return const Right(null);
      }

      // Validate expense has an ID
      if (expense.id == null) {
        return const Left(ValidationFailure('Expense must have an ID to sync'));
      }

      // Get current user
      final userResult = await _authRepository.getCurrentUser();
      if (userResult.isLeft()) {
        return const Left(UnauthorizedFailure('User not authenticated'));
      }
      final user = userResult.getOrElse(() => throw Exception());

      // Update local status to syncing
      await _localDataSource.updateSyncStatus(expense.id!, SyncStatus.syncing);
      _emitSyncStatus(expense.id!, SyncStatus.syncing);

      // Upload invoice image if exists
      String? fileId;
      if (expense.invoiceFilePath != null) {
        final uploadResult = await _storageService.uploadInvoiceImage(
          localPath: expense.invoiceFilePath!,
          userId: user.id,
          expenseId: expense.id!,
        );

        if (uploadResult.isLeft()) {
          // Upload failed - mark as failed and update error message
          await _localDataSource.updateSyncStatus(expense.id!, SyncStatus.failed);
          await _localDataSource.incrementSyncRetryCount(expense.id!);
          
          final failure = uploadResult.fold((l) => l, (r) => throw Exception());
          await _localDataSource.updateSyncErrorMessage(
            expense.id!,
            'Image upload failed: ${failure.message}',
          );
          
          _emitSyncStatus(expense.id!, SyncStatus.failed);
          return Left(failure);
        }

        fileId = uploadResult.getOrElse(() => throw Exception());
      }

      // Sync expense to PocketBase 'expenses' collection
      await _pb.collection('expenses').create(body: {
        'user_id': user.id,
        'username': user.username,
        'user_email': user.email,
        'local_expense_id': expense.id,
        'description': expense.description,
        'price_usd': expense.priceUsd,
        'price_syp': expense.priceSyp,
        'price_try': expense.priceTry,
        'invoice_status': expense.invoiceStatus.index,
        'invoice_file_id': fileId,
        'expense_date': expense.expenseDate.toIso8601String(),
        'created_at': expense.createdAt.toIso8601String(),
        'synced_at': DateTime.now().toIso8601String(),
      });

      // Update local status to synced
      await _localDataSource.updateSyncStatus(expense.id!, SyncStatus.synced);
      await _localDataSource.updateCloudFileId(expense.id!, fileId);
      await _localDataSource.updateSyncErrorMessage(expense.id!, null);
      _emitSyncStatus(expense.id!, SyncStatus.synced);

      return const Right(null);
    } catch (e) {
      // Handle sync failure
      if (expense.id != null) {
        await _localDataSource.updateSyncStatus(expense.id!, SyncStatus.failed);
        await _localDataSource.incrementSyncRetryCount(expense.id!);
        await _localDataSource.updateSyncErrorMessage(
          expense.id!,
          'Sync failed: ${e.toString()}',
        );
        _emitSyncStatus(expense.id!, SyncStatus.failed);
      }
      return Left(SyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncPendingExpenses() async {
    try {
      final pendingExpenses = await _localDataSource.getExpensesBySyncStatus(
        SyncStatus.pending,
      );

      // Also retry failed expenses that haven't exceeded max retries
      final failedExpenses = await _localDataSource.getExpensesBySyncStatus(
        SyncStatus.failed,
      );
      
      final expensesToSync = [
        ...pendingExpenses,
        ...failedExpenses.where(
          (e) => SyncRetryStrategy.shouldRetry(e.syncRetryCount),
        ),
      ];

      if (expensesToSync.isEmpty) {
        return const Right(null);
      }

      // Sync each expense with delay to avoid rate limiting
      for (final expense in expensesToSync) {
        // Check if we should retry based on retry count
        if (expense.syncRetryCount > 0) {
          final delay = SyncRetryStrategy.getRetryDelay(expense.syncRetryCount);
          await Future.delayed(delay);
        }

        await syncExpense(expense);
        
        // Add delay between syncs to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return const Right(null);
    } catch (e) {
      return Left(SyncFailure('Batch sync failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> fetchAdminExpenses() async {
    try {
      // Only admin can fetch all expenses
      if (_flavorConfig.flavor != AppFlavor.admin) {
        print('[CloudSync] Fetch blocked: Not admin flavor');
        return const Left(UnauthorizedFailure('Admin access required'));
      }

      // Check if PocketBase is authenticated
      if (!_pb.authStore.isValid) {
        print('[CloudSync] PocketBase not authenticated');
        return const Left(UnauthorizedFailure('PocketBase authentication required'));
      }

      print('[CloudSync] Fetching expenses from PocketBase...');
      print('[CloudSync] PocketBase URL: ${_pb.baseUrl}');
      print('[CloudSync] Auth token valid: ${_pb.authStore.isValid}');
      
      final records = await _pb.collection('expenses').getFullList(
        sort: '-created_at',
      );
      
      print('[CloudSync] Fetched ${records.length} expense records');
      
      final expenses = <Expense>[];

      for (final record in records) {
        expenses.add(Expense(
          id: record.data['local_expense_id'] as int,
          userId: record.data['user_id'] as int,
          description: record.data['description'] as String,
          priceUsd: (record.data['price_usd'] as num?)?.toDouble(),
          priceSyp: (record.data['price_syp'] as num?)?.toDouble(),
          priceTry: (record.data['price_try'] as num?)?.toDouble(),
          invoiceStatus: InvoiceStatus.values[record.data['invoice_status'] as int],
          invoiceCloudFileId: record.data['invoice_file_id'] as String?,
          expenseDate: DateTime.parse(record.data['expense_date'] as String),
          createdAt: DateTime.parse(record.data['created_at'] as String),
          syncStatus: SyncStatus.synced,
          syncedAt: DateTime.parse(record.data['synced_at'] as String),
          creatorUsername: record.data['username'] as String?,
          creatorEmail: record.data['user_email'] as String?,
        ));
      }

      print('[CloudSync] Successfully parsed ${expenses.length} expenses');
      return Right(expenses);
    } catch (e) {
      print('[CloudSync] Error fetching admin expenses: $e');
      print('[CloudSync] Error type: ${e.runtimeType}');
      return Left(SyncFailure('Failed to fetch admin expenses: ${e.toString()}'));
    }
  }

  @override
  Stream<SyncStatus> watchSyncStatus(int expenseId) {
    return _syncStatusController.stream
        .map((statusMap) => statusMap[expenseId] ?? SyncStatus.pending);
  }

  @override
  Future<void> startAutoSync() async {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncPendingExpenses(),
    );
  }

  @override
  Future<void> stopAutoSync() async {
    _autoSyncTimer?.cancel();
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = _connectivityService.statusStream.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('[CloudSyncService] Connectivity monitoring error: $error');
      },
    );
  }

  /// Handle connectivity status changes
  Future<void> _onConnectivityChanged(ConnectivityStatus status) async {
    print('[CloudSyncService] Connectivity changed to: $status');

    if (status.isOffline) {
      // Device went offline
      _wasOffline = true;
      print('[CloudSyncService] Device is offline - sync paused');
    } else if (status.isOnline && _wasOffline) {
      // Device came back online after being offline
      _wasOffline = false;
      print('[CloudSyncService] Device is back online - triggering sync');
      
      // Trigger automatic sync of pending expenses
      await _syncOnConnectivityRestore();
    }
  }

  /// Sync pending expenses when connectivity is restored
  Future<void> _syncOnConnectivityRestore() async {
    try {
      // Only sync in user version
      if (_flavorConfig.flavor != AppFlavor.user) {
        return;
      }

      print('[CloudSyncService] Starting automatic sync after connectivity restore');
      
      final result = await syncPendingExpenses();
      
      result.fold(
        (failure) {
          // Sync failed
          final message = 'Sync failed after going online: ${failure.message}';
          print('[CloudSyncService] $message');
          _emitSyncNotification(message);
        },
        (_) {
          // Sync succeeded
          final message = 'Successfully synced pending expenses';
          print('[CloudSyncService] $message');
          _emitSyncNotification(message);
        },
      );
    } catch (e) {
      print('[CloudSyncService] Error during connectivity restore sync: $e');
      _emitSyncNotification('Error syncing after going online');
    }
  }

  /// Stream of sync notifications (for UI to display)
  Stream<String> get syncNotifications => _syncNotificationController.stream;

  /// Emit sync notification
  void _emitSyncNotification(String message) {
    _syncNotificationController.add(message);
  }

  /// Emit sync status update for a specific expense
  void _emitSyncStatus(int expenseId, SyncStatus status) {
    _syncStatusMap[expenseId] = status;
    _syncStatusController.add(Map.from(_syncStatusMap));
  }

  /// Dispose resources
  void dispose() {
    _autoSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    _syncNotificationController.close();
  }
}
