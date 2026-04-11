import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/queue_item.dart';
import '../../../../core/services/auth_logger.dart';
import '../../../../core/services/connectivity_monitor.dart';
import '../../../../core/services/queue_manager.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/file_upload_service.dart';
import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_api_datasource.dart';
import '../datasources/expense_cache_datasource.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_dto.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource? localDataSource;
  final ExpenseApiDataSource apiDataSource;
  final ExpenseCacheDataSource cacheDataSource;
  final AuthRepository authRepository;
  final ConnectivityMonitor connectivityMonitor;
  final QueueManager queueManager;
  final SyncService? syncService;
  final FileUploadService? fileUploadService;

  ExpenseRepositoryImpl({
    this.localDataSource,
    required this.apiDataSource,
    required this.cacheDataSource,
    required this.authRepository,
    required this.connectivityMonitor,
    required this.queueManager,
    this.syncService,
    this.fileUploadService,
  });

  @override
  Future<Either<Failure, Expense>> createExpense({
    required int userId,
    required String description,
    double? priceUsd,
    double? priceSyp,
    double? priceTry,
    required InvoiceStatus invoiceStatus,
    String? invoiceFilePath,
    required DateTime expenseDate,
  }) async {
    try {
      print('[ExpenseRepository] Creating expense for user $userId');
      print('[ExpenseRepository] Description: $description');
      
      // Create DTO for API request
      // Only include fields that the backend expects
      final dto = ExpenseDto(
        userId: userId,
        description: description,
        priceUsd: priceUsd,
        priceSyp: priceSyp,
        priceTry: priceTry,
        expenseDate: expenseDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
      );

      // Try to create via API if online
      final isOnline = await connectivityMonitor.isOnline;
      print('[ExpenseRepository] Online status: $isOnline');
      
      if (isOnline) {
        try {
          print('[ExpenseRepository] Attempting to create via API...');
          print('[ExpenseRepository] Request body: ${dto.toJson()}');
          
          // Prepare photo file if path is provided
          File? photoFile;
          if (invoiceFilePath != null && invoiceFilePath.isNotEmpty) {
            photoFile = File(invoiceFilePath);
            if (!await photoFile.exists()) {
              print('[ExpenseRepository] ⚠️ Photo file not found: $invoiceFilePath');
              photoFile = null;
            } else {
              print('[ExpenseRepository] 📷 Photo file found, will compress and upload with expense');
              
              // Compress image before upload if fileUploadService is available
              if (fileUploadService != null) {
                try {
                  print('[ExpenseRepository] 🗜️ Compressing image...');
                  final compressedFile = await fileUploadService!.compressImage(photoFile);
                  final originalSize = await photoFile.length();
                  final compressedSize = await compressedFile.length();
                  final compressionRatio = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);
                  print('[ExpenseRepository] ✅ Compression complete: ${originalSize ~/ 1024}KB → ${compressedSize ~/ 1024}KB (${compressionRatio}% reduction)');
                  photoFile = compressedFile;
                } catch (e) {
                  print('[ExpenseRepository] ⚠️ Compression failed, using original: $e');
                  // Continue with original file if compression fails
                }
              }
            }
          }
          
          // Retry logic: attempt upload up to 3 times
          ExpenseDto? createdDto;
          int retryCount = 0;
          const maxRetries = 3;
          Exception? lastError;
          
          while (retryCount < maxRetries && createdDto == null) {
            try {
              if (retryCount > 0) {
                print('[ExpenseRepository] 🔄 Retry attempt $retryCount/$maxRetries...');
                // Wait before retrying (exponential backoff)
                await Future.delayed(Duration(seconds: retryCount * 2));
              }
              
              createdDto = await apiDataSource.createExpense(dto, photoFile: photoFile);
              print('[ExpenseRepository] ✅ API creation successful! ID: ${createdDto.id}');
              
              if (photoFile != null) {
                print('[ExpenseRepository] ✅ Photo uploaded successfully');
                if (createdDto.invoicePath != null && createdDto.invoicePath!.isNotEmpty) {
                  print('[ExpenseRepository] 📥 Server invoice path: ${createdDto.invoicePath}');
                  print('[ExpenseRepository] ℹ️ Photo stored on server, will be displayed from URL');
                }
              }
            } catch (e) {
              lastError = e as Exception;
              retryCount++;
              
              if (retryCount < maxRetries) {
                print('[ExpenseRepository] ⚠️ Upload failed (attempt $retryCount/$maxRetries): $e');
              } else {
                print('[ExpenseRepository] ❌ Upload failed after $maxRetries attempts: $e');
                rethrow;
              }
            }
          }
          
          if (createdDto != null) {
            final expense = createdDto.toEntity();
            
            // Cache the created expense
            await cacheDataSource.cacheExpense(createdDto);
            await cacheDataSource.clearAllCache(); // Clear list caches
            
            return Right(expense);
          } else {
            throw lastError ?? Exception('Failed to create expense after $maxRetries attempts');
          }
        } on ApiException catch (e) {
          print('[ExpenseRepository] ⚠️ API failed: ${e.message}');
          print('[ExpenseRepository] Status code: ${e.statusCode}');
          if (e.errors != null) {
            print('[ExpenseRepository] Validation errors: ${e.errors}');
          }
          print('[ExpenseRepository] Queuing for later sync...');
          // Queue for later sync if API fails
          final tempExpense = dto.toEntity();
          await _queueExpenseOperation(tempExpense, QueueOperation.create);
          return Right(tempExpense);
        } catch (e) {
          print('[ExpenseRepository] ⚠️ Unexpected error: $e');
          print('[ExpenseRepository] Queuing for later sync...');
          final tempExpense = dto.toEntity();
          await _queueExpenseOperation(tempExpense, QueueOperation.create);
          return Right(tempExpense);
        }
      } else {
        print('[ExpenseRepository] Offline - queuing for later sync');
        // Queue for later sync if offline
        final tempExpense = dto.toEntity();
        await _queueExpenseOperation(tempExpense, QueueOperation.create);
        return Right(tempExpense);
      }
    } catch (e) {
      print('[ExpenseRepository] ❌ Unexpected error: $e');
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByUser(int userId) async {
    try {
      print('[ExpenseRepository] 🔵 Loading expenses for user $userId');
      
      // NOTE: Data scoping by admin_group_id is handled automatically by the Laravel backend.
      // The API filters expenses based on the authenticated user's admin_group_id from their token.
      // Users only see expenses from members of their admin group.
      // 
      // ⚠️ IMPORTANT: If expenses have admin_group_id = NULL, they might not be returned by the API.
      // This is a backend filtering issue that needs to be fixed on the Laravel side.
      
      // TEMPORARY FIX: Clear cache to force API reload (to get has_invoice field)
      // TODO: Remove this after cache schema is updated
      await cacheDataSource.clearAllCache();
      print('[ExpenseRepository] 🗑️ Cache cleared - forcing API reload');
      
      // Cache-first strategy: Try cache first
      final cachedResponse = await cacheDataSource.getCachedExpenses();
      if (cachedResponse != null && cachedResponse.data.isNotEmpty) {
        print('[ExpenseRepository] ✅ Found ${cachedResponse.data.length} expenses in cache');
        final expenses = cachedResponse.data.map((dto) => dto.toEntity()).toList();
        return Right(expenses);
      }
      
      print('[ExpenseRepository] No cache found, fetching from API...');
      print('[ExpenseRepository] 🔍 Requesting expenses from: /expenses?per_page=15');
      print('[ExpenseRepository] 🔍 Authenticated user ID: $userId');

      // If online, fetch from API
      final isOnline = await connectivityMonitor.isOnline;
      print('[ExpenseRepository] Online status: $isOnline');
      
      if (isOnline) {
        try {
          print('[ExpenseRepository] 📡 Calling API to get expenses...');
          final response = await apiDataSource.getExpenses();
          
          print('[ExpenseRepository] 📥 API Response received:');
          print('[ExpenseRepository]    - Total expenses: ${response.data.length}');
          print('[ExpenseRepository]    - Current page: ${response.currentPage}');
          print('[ExpenseRepository]    - Total pages: ${response.lastPage}');
          print('[ExpenseRepository]    - Total count: ${response.total}');
          
          if (response.data.isEmpty && response.total == 0) {
            print('[ExpenseRepository] ⚠️ WARNING: API returned empty array but expenses exist in database!');
            print('[ExpenseRepository] ⚠️ This indicates a backend filtering issue:');
            print('[ExpenseRepository] ⚠️ 1. Check if expenses have admin_group_id = NULL');
            print('[ExpenseRepository] ⚠️ 2. Check if authenticated user has matching admin_group_id');
            print('[ExpenseRepository] ⚠️ 3. Check backend API filtering logic in ExpenseController');
          }
          
          // Cache the response (even if empty)
          await cacheDataSource.cacheExpenses(response);
          
          final expenses = response.data.map((dto) => dto.toEntity()).toList();
          print('[ExpenseRepository] ✅ Returning ${expenses.length} expenses to UI');
          return Right(expenses);
        } on ApiException catch (e) {
          print('[ExpenseRepository] ❌ API failed: ${e.message}');
          print('[ExpenseRepository]    Status code: ${e.statusCode}');
          print('[ExpenseRepository]    Full error: $e');
          // Return empty list if API fails and no cache
          return const Right([]);
        } catch (e, stackTrace) {
          print('[ExpenseRepository] ❌ Unexpected error: $e');
          print('[ExpenseRepository]    Stack trace: $stackTrace');
          return const Right([]);
        }
      }

      print('[ExpenseRepository] Offline and no cache - returning empty list');
      // If offline and no cache, return empty list
      return const Right([]);
    } catch (e, stackTrace) {
      print('[ExpenseRepository] ❌ Unexpected error in getExpensesByUser: $e');
      print('[ExpenseRepository]    Stack trace: $stackTrace');
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateExpense(Expense expense) async {
    try {
      if (expense.id == null) {
        return const Left(DatabaseFailure('Cannot update expense without ID'));
      }

      // Try to update via API if online
      final isOnline = await connectivityMonitor.isOnline;
      if (isOnline) {
        try {
          final dto = ExpenseDto.fromEntity(expense);
          
          // Prepare photo file if path is provided
          File? photoFile;
          if (expense.invoiceFilePath != null && expense.invoiceFilePath!.isNotEmpty) {
            photoFile = File(expense.invoiceFilePath!);
            if (!await photoFile.exists()) {
              print('[ExpenseRepository] ⚠️ Photo file not found: ${expense.invoiceFilePath}');
              photoFile = null;
            } else {
              print('[ExpenseRepository] 📷 Photo file found, will upload with update');
            }
          }
          
          await apiDataSource.updateExpense(expense.id!, dto, photoFile: photoFile);
          
          if (photoFile != null) {
            print('[ExpenseRepository] ✅ Photo updated successfully');
          }
          
          // Invalidate cache
          await cacheDataSource.invalidateExpenseCache(expense.id!);
          
          return const Right(null);
        } on ApiException {
          // Queue for later sync if API fails
          await _queueExpenseOperation(expense, QueueOperation.update);
          return const Right(null);
        }
      } else {
        // Queue for later sync if offline
        await _queueExpenseOperation(expense, QueueOperation.update);
        return const Right(null);
      }
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(int id, int userId) async {
    try {
      // Try to sync with API if online
      final isOnline = await connectivityMonitor.isOnline;
      if (isOnline) {
        try {
          await apiDataSource.deleteExpense(id);
          
          // Invalidate cache - both single expense and list caches
          await cacheDataSource.invalidateExpenseCache(id);
          await cacheDataSource.clearAllCache(); // Clear list caches to refresh UI
        } on ApiException {
          // Queue for later sync if API fails
          final queueItem = QueueItem(
            id: '',
            operation: QueueOperation.delete,
            resourceType: 'expense',
            data: {'id': id, 'user_id': userId},
            createdAt: DateTime.now(),
            status: QueueStatus.pending,
            retryCount: 0,
          );
          await queueManager.enqueue(queueItem);
        }
      } else {
        // Queue for later sync if offline
        final queueItem = QueueItem(
          id: '',
          operation: QueueOperation.delete,
          resourceType: 'expense',
          data: {'id': id, 'user_id': userId},
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
          retryCount: 0,
        );
        await queueManager.enqueue(queueItem);
      }

      return const Right(null);
    } on ApiException catch (e) {
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> fetchAdminExpenses(
    int requestingUserId,
  ) async {
    try {
      // Get the requesting user to check their role
      final userResult = await authRepository.getCurrentUser();
      
      if (userResult.isLeft()) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'fetchAdminExpenses',
          attemptedUserId: requestingUserId,
          resourceOwnerId: null,
          resourceType: 'all_expenses',
          additionalInfo: 'User not authenticated',
        );
        return const Left(UnauthorizedFailure('User not authenticated'));
      }

      final user = userResult.getOrElse(() => throw Exception());

      // Verify user ID matches
      if (user.id != requestingUserId) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'fetchAdminExpenses',
          attemptedUserId: requestingUserId,
          resourceOwnerId: user.id,
          resourceType: 'all_expenses',
          additionalInfo: 'User ID mismatch',
        );
        return const Left(UnauthorizedFailure('User ID mismatch'));
      }

      // Check if user has admin role
      if (!user.isAdmin) {
        AuthLogger.logUnauthorizedAccess(
          operation: 'fetchAdminExpenses',
          attemptedUserId: requestingUserId,
          resourceOwnerId: null,
          resourceType: 'all_expenses',
          additionalInfo: 'Non-admin user attempted to access admin-only operation',
        );
        return const Left(
          UnauthorizedFailure('Admin privileges required to fetch all expenses'),
        );
      }

      // User is admin - fetch expenses from sync service
      if (syncService == null) {
        return const Left(
          DatabaseFailure('Sync service not available'),
        );
      }

      final result = await syncService!.fetchAdminExpenses();
      
      if (result.isRight()) {
        AuthLogger.logAuthorizedAccess(
          operation: 'fetchAdminExpenses',
          userId: requestingUserId,
          resourceType: 'all_expenses',
        );
      }

      return result;
    } catch (e) {
      AuthLogger.logDatabaseError(
        operation: 'fetchAdminExpenses',
        userId: requestingUserId,
        error: e.toString(),
      );
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Helper method to queue expense operations for offline sync
  Future<void> _queueExpenseOperation(
    Expense expense,
    QueueOperation operation,
  ) async {
    try {
      final queueItem = QueueItem(
        id: '',
        operation: operation,
        resourceType: 'expense',
        data: ExpenseDto.fromEntity(expense).toJson(),
        createdAt: DateTime.now(),
        status: QueueStatus.pending,
        retryCount: 0,
      );
      await queueManager.enqueue(queueItem);
    } catch (e) {
      // Silently fail queue operations
    }
  }
}
