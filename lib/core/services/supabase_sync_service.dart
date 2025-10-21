import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/expenses/domain/entities/expense.dart';
import '../../features/expenses/data/datasources/expense_local_datasource.dart';
import '../config/flavor_config.dart';
import '../config/supabase_config.dart';
import '../error/failures.dart';
import '../models/sync_status.dart';
import 'supabase_service.dart';
import 'sync_service.dart';
import 'connectivity_service.dart';

/// Supabase synchronization service implementation
/// Handles sync between local SQLite and Supabase PostgreSQL
class SupabaseSyncService implements SyncService {
  final SupabaseService _supabaseService;
  final ExpenseLocalDataSource _localDataSource;
  final FlavorConfig _flavorConfig;
  final ConnectivityService _connectivityService;

  Timer? _autoSyncTimer;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  final _syncStatusController = StreamController<Map<int, SyncStatus>>.broadcast();
  final Map<int, SyncStatus> _syncStatusMap = {};
  final _syncNotificationController = StreamController<String>.broadcast();
  bool _wasOffline = false;

  SupabaseSyncService({
    required SupabaseService supabaseService,
    required ExpenseLocalDataSource localDataSource,
    required FlavorConfig flavorConfig,
    required ConnectivityService connectivityService,
  })  : _supabaseService = supabaseService,
        _localDataSource = localDataSource,
        _flavorConfig = flavorConfig,
        _connectivityService = connectivityService {
    _initializeConnectivityMonitoring();
    _initializeRealtimeSubscription();
  }

  @override
  Future<Either<Failure, void>> syncExpense(Expense expense) async {
    try {
      // Both user and admin can sync expenses
      // Admin syncs to view all expenses, user syncs their own
      print('[SupabaseSyncService] Starting sync for expense ${expense.id}, flavor: ${_flavorConfig.flavor}');

      // Validate expense has an ID
      if (expense.id == null) {
        print('[SupabaseSyncService] Sync failed: Expense has no ID');
        return const Left(ValidationFailure('Expense must have an ID to sync'));
      }

      // Check authentication
      print('[SupabaseSyncService] Checking authentication...');
      print('[SupabaseSyncService] isAuthenticated: ${_supabaseService.isAuthenticated}');
      print('[SupabaseSyncService] currentUser: ${_supabaseService.currentUser}');
      print('[SupabaseSyncService] currentUserId: ${_supabaseService.currentUserId}');
      
      if (!_supabaseService.isAuthenticated) {
        print('[SupabaseSyncService] Sync failed: User not authenticated with Supabase');
        return const Left(UnauthorizedFailure('User not authenticated'));
      }

      final userId = _supabaseService.currentUserId!;
      final userEmail = _supabaseService.currentUserEmail;

      // Update local status to syncing
      await _localDataSource.updateSyncStatus(expense.id!, SyncStatus.syncing);
      _emitSyncStatus(expense.id!, SyncStatus.syncing);

      // Upload invoice image if exists
      String? fileId;
      if (expense.invoiceFilePath != null) {
        final uploadResult = await _uploadInvoiceImage(
          localPath: expense.invoiceFilePath!,
          userId: userId,
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

      // Get user profile for additional info
      final userProfile = await _supabaseService.getUserProfile(userId);
      final username = userProfile?['username'] ?? 'Unknown';

      // Sync expense to Supabase
      await _supabaseService.from(SupabaseConfig.expensesTable).insert({
        'user_id': userId,
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
        'creator_username': username,
        'creator_email': userEmail,
      });

      // Update local status to synced
      await _localDataSource.updateSyncStatus(expense.id!, SyncStatus.synced);
      await _localDataSource.updateCloudFileId(expense.id!, fileId);
      await _localDataSource.updateSyncErrorMessage(expense.id!, null);
      _emitSyncStatus(expense.id!, SyncStatus.synced);

      print('[SupabaseSyncService] Expense synced successfully: ${expense.id}');
      return const Right(null);
    } catch (e, stackTrace) {
      print('[SupabaseSyncService] Sync failed: $e');
      print('[SupabaseSyncService] Stack trace: $stackTrace');
      
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
      print('[SupabaseSyncService] Starting batch sync of pending expenses');
      
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
        print('[SupabaseSyncService] No expenses to sync');
        return const Right(null);
      }

      print('[SupabaseSyncService] Syncing ${expensesToSync.length} expenses');

      // Sync each expense with delay to avoid rate limiting
      for (final expense in expensesToSync) {
        // Check if we should retry based on retry count
        if (expense.syncRetryCount > 0) {
          final delay = SyncRetryStrategy.getRetryDelay(expense.syncRetryCount);
          await Future.delayed(delay);
        }

        await syncExpense(expense);
        
        // Add delay between syncs to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 300));
      }

      print('[SupabaseSyncService] Batch sync completed');
      return const Right(null);
    } catch (e) {
      print('[SupabaseSyncService] Batch sync failed: $e');
      return Left(SyncFailure('Batch sync failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> fetchAdminExpenses() async {
    try {
      // Only admin can fetch all expenses
      if (_flavorConfig.flavor != AppFlavor.admin) {
        print('[SupabaseSyncService] Fetch blocked: Not admin flavor');
        return const Left(UnauthorizedFailure('Admin access required'));
      }

      // Check authentication
      if (!_supabaseService.isAuthenticated) {
        print('[SupabaseSyncService] Not authenticated');
        return const Left(UnauthorizedFailure('Authentication required'));
      }

      // Check if user is admin
      final isAdmin = await _supabaseService.isAdmin;
      if (!isAdmin) {
        print('[SupabaseSyncService] User is not admin');
        return const Left(UnauthorizedFailure('Admin privileges required'));
      }

      print('[SupabaseSyncService] Fetching admin expenses from Supabase');

      // Fetch all expenses (RLS policies will handle permissions)
      final response = await _supabaseService
          .from(SupabaseConfig.expensesTable)
          .select()
          .order('created_at', ascending: false);
      
      print('[SupabaseSyncService] Fetched ${response.length} expense records');
      
      final expenses = <Expense>[];

      for (final record in response) {
        expenses.add(Expense(
          id: record['local_expense_id'] as int,
          userId: (record['user_id'] as String).hashCode, // Convert UUID to int
          description: record['description'] as String,
          priceUsd: (record['price_usd'] as num?)?.toDouble(),
          priceSyp: (record['price_syp'] as num?)?.toDouble(),
          priceTry: (record['price_try'] as num?)?.toDouble(),
          invoiceStatus: InvoiceStatus.values[record['invoice_status'] as int],
          invoiceCloudFileId: record['invoice_file_id'] as String?,
          expenseDate: DateTime.parse(record['expense_date'] as String),
          createdAt: DateTime.parse(record['created_at'] as String),
          syncStatus: SyncStatus.synced,
          syncedAt: DateTime.parse(record['synced_at'] as String),
          creatorUsername: record['creator_username'] as String?,
          creatorEmail: record['creator_email'] as String?,
        ));
      }

      print('[SupabaseSyncService] Successfully parsed ${expenses.length} expenses');
      return Right(expenses);
    } catch (e) {
      print('[SupabaseSyncService] Error fetching admin expenses: $e');
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
    print('[SupabaseSyncService] Starting auto sync');
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 3), // Frequent sync for real-time updates
      (_) => syncPendingExpenses(),
    );
  }

  @override
  Future<void> stopAutoSync() async {
    print('[SupabaseSyncService] Stopping auto sync');
    _autoSyncTimer?.cancel();
  }

  /// Upload invoice image to Supabase Storage
  Future<Either<Failure, String>> _uploadInvoiceImage({
    required String localPath,
    required String userId,
    required int expenseId,
  }) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        return const Left(ValidationFailure('File does not exist'));
      }

      // Create unique file path
      final fileName = '$userId/$expenseId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      print('[SupabaseSyncService] Uploading image: $fileName');
      
      await _supabaseService.uploadFile(
        bucket: SupabaseConfig.invoicesBucket,
        path: fileName,
        file: file,
      );

      print('[SupabaseSyncService] Image uploaded successfully');
      return Right(fileName);
    } catch (e) {
      print('[SupabaseSyncService] Image upload failed: $e');
      return Left(SyncFailure('Image upload failed: ${e.toString()}'));
    }
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = _connectivityService.statusStream.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('[SupabaseSyncService] Connectivity monitoring error: $error');
      },
    );
  }

  /// Initialize real-time subscription for admin users
  void _initializeRealtimeSubscription() {
    if (_flavorConfig.flavor == AppFlavor.admin) {
      print('[SupabaseSyncService] Setting up real-time subscription for admin');
      
      _realtimeSubscription = _supabaseService
          .from(SupabaseConfig.expensesTable)
          .stream(primaryKey: ['id'])
          .listen(
        (data) {
          print('[SupabaseSyncService] Real-time update received: ${data.length} records');
          _emitSyncNotification('New expense data received');
        },
        onError: (error) {
          print('[SupabaseSyncService] Real-time subscription error: $error');
        },
      );
    }
  }

  /// Handle connectivity status changes
  Future<void> _onConnectivityChanged(ConnectivityStatus status) async {
    print('[SupabaseSyncService] Connectivity changed to: $status');

    if (status.isOffline) {
      // Device went offline
      _wasOffline = true;
      print('[SupabaseSyncService] Device is offline - sync paused');
    } else if (status.isOnline && _wasOffline) {
      // Device came back online after being offline
      _wasOffline = false;
      print('[SupabaseSyncService] Device is back online - triggering sync');
      
      // Trigger automatic sync of pending expenses
      await _syncOnConnectivityRestore();
    }
  }

  /// Sync pending expenses when connectivity is restored
  Future<void> _syncOnConnectivityRestore() async {
    try {
      // Both user and admin can sync
      print('[SupabaseSyncService] Starting automatic sync after connectivity restore');
      
      final result = await syncPendingExpenses();
      
      result.fold(
        (failure) {
          // Sync failed
          final message = 'Sync failed after going online: ${failure.message}';
          print('[SupabaseSyncService] $message');
          _emitSyncNotification(message);
        },
        (_) {
          // Sync succeeded
          final message = 'Successfully synced pending expenses';
          print('[SupabaseSyncService] $message');
          _emitSyncNotification(message);
        },
      );
    } catch (e) {
      print('[SupabaseSyncService] Error during connectivity restore sync: $e');
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
    print('[SupabaseSyncService] Disposing resources');
    _autoSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _realtimeSubscription?.cancel();
    _syncStatusController.close();
    _syncNotificationController.close();
  }
}

/// Sync retry strategy for Supabase operations
class SyncRetryStrategy {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 5);

  static bool shouldRetry(int retryCount) {
    return retryCount < maxRetries;
  }

  static Duration getRetryDelay(int retryCount) {
    // Exponential backoff: 5s, 10s, 20s
    return Duration(seconds: baseDelay.inSeconds * (1 << retryCount));
  }
}