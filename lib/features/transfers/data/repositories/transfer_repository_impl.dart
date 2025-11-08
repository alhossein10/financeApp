import 'package:dartz/dartz.dart';
import '../../../../core/api/api_exception.dart' as api_exceptions;
import '../../../../core/error/failures.dart';
import '../../../../core/models/queue_item.dart';
import '../../../../core/services/connectivity_monitor.dart';
import '../../../../core/services/queue_manager.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/transfer_api_datasource.dart';
import '../datasources/transfer_cache_datasource.dart';
import '../datasources/transfer_local_datasource.dart';
import '../models/exchange_dto.dart';
import '../models/transfer_dto.dart';
import '../models/transfer_model.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TransferLocalDataSource? localDataSource;
  final TransferApiDataSource? apiDataSource;
  final TransferCacheDataSource? cacheDataSource;
  final QueueManager? queueManager;
  final ConnectivityMonitor? connectivityMonitor;

  TransferRepositoryImpl({
    this.localDataSource,
    this.apiDataSource,
    this.cacheDataSource,
    this.queueManager,
    this.connectivityMonitor,
  });

  /// Helper method to format date for API (YYYY-MM-DD)
  String _formatDateForApi(DateTime date) {
    return DateFormatter.toApiDate(date);
  }

  @override
  Future<Either<Failure, Transfer>> createTransfer({
    required int userId,
    required String recipientName,
    int? recipientUserId,
    int? adminGroupId,
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  }) async {
    // Use API if available, otherwise fall back to local
    if (apiDataSource != null) {
      return _createTransferViaApi(
        userId: userId,
        recipientName: recipientName,
        recipientUserId: recipientUserId,
        adminGroupId: adminGroupId,
        amountUsd: amountUsd,
        convertedAmountUsd: convertedAmountUsd,
        amountSypAtExchange: amountSypAtExchange,
        manualUsdToSypRate: manualUsdToSypRate,
        transactionDate: transactionDate,
      );
    } else if (localDataSource != null) {
      return _createTransferViaLocal(
        userId: userId,
        recipientName: recipientName,
        amountUsd: amountUsd,
        convertedAmountUsd: convertedAmountUsd,
        amountSypAtExchange: amountSypAtExchange,
        manualUsdToSypRate: manualUsdToSypRate,
        transactionDate: transactionDate,
      );
    } else {
      return const Left(DatabaseFailure('No data source available'));
    }
  }

  Future<Either<Failure, Transfer>> _createTransferViaApi({
    required int userId,
    required String recipientName,
    int? recipientUserId,
    int? adminGroupId,
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  }) async {
    try {
      // Check connectivity
      final isOnline = connectivityMonitor != null 
          ? await connectivityMonitor!.isOnline 
          : true;

      if (!isOnline && queueManager != null) {
        // Queue operation for later
        final queueItem = QueueItem(
          id: '',
          operation: QueueOperation.create,
          resourceType: 'transfer',
          data: {
            'user_id': userId,
            'recipient_name': recipientName,
            if (recipientUserId != null) 'recipient_user_id': recipientUserId,
            if (adminGroupId != null) 'admin_group_id': adminGroupId,
            'amount_usd': amountUsd,
            'converted_amount_usd': convertedAmountUsd,
            'amount_syp_at_exchange': amountSypAtExchange,
            'manual_usd_to_syp_rate': manualUsdToSypRate,
            'transfer_date': (transactionDate ?? DateTime.now()).toIso8601String(),
          },
          retryCount: 0,
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
        );

        await queueManager!.enqueue(queueItem);

        // Return a temporary transfer with pending status
        final tempTransfer = Transfer(
          id: null,
          userId: userId,
          recipientName: recipientName,
          amountUsd: amountUsd,
          convertedAmountUsd: convertedAmountUsd,
          amountSypAtExchange: amountSypAtExchange,
          manualUsdToSypRate: manualUsdToSypRate,
          transactionDate: transactionDate ?? DateTime.now(),
          createdAt: DateTime.now(),
        );

        return Right(tempTransfer);
      }

      // Create transfer DTO
      ExchangeDto? exchangeDto;
      if (convertedAmountUsd != null && manualUsdToSypRate != null) {
        exchangeDto = ExchangeDto(
          convertedAmountSyp: convertedAmountUsd,
          exchangeRateUsdToSyp: manualUsdToSypRate,
          exchangeDate: transactionDate ?? DateTime.now(),
        );
      }

      final transferDto = TransferDto(
        userId: userId,
        recipientUserId: recipientUserId,
        adminGroupId: adminGroupId,
        recipientName: recipientName,
        amountUsd: amountUsd,
        transferDate: _formatDateForApi(transactionDate ?? DateTime.now()),
        exchange: exchangeDto,
      );

      // Create via API
      final createdDto = await apiDataSource!.createTransfer(transferDto);

      // Cache the result
      if (cacheDataSource != null) {
        await cacheDataSource!.cacheTransfer(createdDto);
        await cacheDataSource!.invalidateTransferCache(userId);
      }

      return Right(createdDto.toEntity());
    } on api_exceptions.ApiException catch (e) {
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(ApiFailure('Failed to create transfer: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Transfer>> _createTransferViaLocal({
    required int userId,
    required String recipientName,
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  }) async {
    try {
      final transfer = await localDataSource!.createTransfer(
        userId: userId,
        recipientName: recipientName,
        amountUsd: amountUsd,
        convertedAmountUsd: convertedAmountUsd,
        amountSypAtExchange: amountSypAtExchange,
        manualUsdToSypRate: manualUsdToSypRate,
        transactionDate: transactionDate,
      );
      return Right(transfer);
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Transfer>>> getTransfersByUser(int userId) async {
    // Use API if available, otherwise fall back to local
    if (apiDataSource != null) {
      return _getTransfersByUserViaApi(userId);
    } else if (localDataSource != null) {
      return _getTransfersByUserViaLocal(userId);
    } else {
      return const Left(DatabaseFailure('No data source available'));
    }
  }

  Future<Either<Failure, List<Transfer>>> _getTransfersByUserViaApi(
    int userId,
  ) async {
    try {
      // NOTE: Data scoping by admin_group_id is handled automatically by the Laravel backend.
      // The API filters transfers based on the authenticated user's admin_group_id from their token.
      // Users only see transfers from members of their admin group.
      
      // Try to get from cache first
      if (cacheDataSource != null) {
        final cached = await cacheDataSource!.getCachedTransfers(userId);
        if (cached != null) {
          final entities = cached.map((dto) => dto.toEntity()).toList();
          
          // Fetch fresh data in background
          _refreshTransfersInBackground(userId);
          
          return Right(entities);
        }
      }

      print('[TransferRepository] 🔵 Loading transfers for user $userId');
      print('[TransferRepository] 🔍 Requesting transfers from: /transfers?per_page=15');
      print('[TransferRepository] 🔍 Authenticated user ID: $userId');
      
      // NOTE: Data scoping by admin_group_id is handled automatically by the Laravel backend.
      // The API filters transfers based on the authenticated user's admin_group_id from their token.
      // Users only see transfers from members of their admin group.
      // 
      // ⚠️ IMPORTANT: If transfers have admin_group_id = NULL, they might not be returned by the API.
      // This is a backend filtering issue that needs to be fixed on the Laravel side.
      // 
      // For admin flavor: Admins should see outgoing transfers (where user_id = admin_id)
      // For admin flavor: Admins should see transfers to their group members
      
      // Fetch from API (automatically filtered by admin_group_id)
      final response = await apiDataSource!.getTransfers();
      
      print('[TransferRepository] 📥 API Response received:');
      print('[TransferRepository]    - Total transfers: ${response.data.length}');
      print('[TransferRepository]    - Current page: ${response.currentPage}');
      print('[TransferRepository]    - Total pages: ${response.lastPage}');
      print('[TransferRepository]    - Total count: ${response.total}');
      
      if (response.data.isEmpty && response.total == 0) {
        print('[TransferRepository] ⚠️ WARNING: API returned empty array but transfers exist in database!');
        print('[TransferRepository] ⚠️ This indicates a backend filtering issue:');
        print('[TransferRepository] ⚠️ 1. Check if transfers have admin_group_id = NULL');
        print('[TransferRepository] ⚠️ 2. Check if authenticated user has matching admin_group_id');
        print('[TransferRepository] ⚠️ 3. Check backend API filtering logic in TransferController');
        print('[TransferRepository] ⚠️ 4. For admin flavor: Admins should see outgoing transfers (where user_id = admin_id)');
        print('[TransferRepository] ⚠️ 5. For admin flavor: Admins should see transfers to their group members');
      }
      
      // Filter transfers to include only those where user_id matches the requested userId
      // This ensures we only return transfers for the specific user
      // NOTE: For admin flavor, we want to show outgoing transfers (where user_id = admin_id)
      final transfers = response.data.map((dto) => dto.toEntity()).toList();
      final userTransfers = transfers.where((t) => t.userId == userId).toList();
      
      print('[TransferRepository] ✅ Filtered to ${userTransfers.length} transfers for user $userId');
      print('[TransferRepository]    Outgoing transfers (user_id=$userId): ${userTransfers.length}');
      print('[TransferRepository]    All transfers from API: ${transfers.length}');

      // Cache the result
      if (cacheDataSource != null) {
        await cacheDataSource!.cacheTransfers(userId, response.data);
      }

      return Right(userTransfers);
    } on api_exceptions.ApiException catch (e) {
      // If API fails, try to return cached data
      if (cacheDataSource != null) {
        final cached = await cacheDataSource!.getCachedTransfers(userId);
        if (cached != null) {
          final entities = cached.map((dto) => dto.toEntity()).toList();
          return Right(entities);
        }
      }
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(ApiFailure('Failed to get transfers: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<Transfer>>> _getTransfersByUserViaLocal(
    int userId,
  ) async {
    try {
      final transfers = await localDataSource!.getTransfersByUser(userId);
      return Right(transfers);
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  Future<void> _refreshTransfersInBackground(int userId) async {
    try {
      final response = await apiDataSource!.getTransfers();
      if (cacheDataSource != null) {
        await cacheDataSource!.cacheTransfers(userId, response.data);
      }
    } catch (e) {
      // Silently fail background refresh
    }
  }

  @override
  Future<Either<Failure, void>> updateTransfer(Transfer transfer) async {
    // Use API if available, otherwise fall back to local
    if (apiDataSource != null) {
      return _updateTransferViaApi(transfer);
    } else if (localDataSource != null) {
      return _updateTransferViaLocal(transfer);
    } else {
      return const Left(DatabaseFailure('No data source available'));
    }
  }

  Future<Either<Failure, void>> _updateTransferViaApi(Transfer transfer) async {
    try {
      if (transfer.id == null) {
        return const Left(ApiFailure('Transfer ID is required for update'));
      }

      // Check connectivity
      final isOnline = connectivityMonitor != null 
          ? await connectivityMonitor!.isOnline 
          : true;

      if (!isOnline && queueManager != null) {
        // Queue operation for later
        final queueItem = QueueItem(
          id: '',
          operation: QueueOperation.update,
          resourceType: 'transfer',
          data: {
            'id': transfer.id,
            'user_id': transfer.userId,
            'recipient_name': transfer.recipientName,
            'amount_usd': transfer.amountUsd,
            'converted_amount_usd': transfer.convertedAmountUsd,
            'amount_syp_at_exchange': transfer.amountSypAtExchange,
            'manual_usd_to_syp_rate': transfer.manualUsdToSypRate,
            'transfer_date': transfer.transactionDate.toIso8601String(),
          },
          retryCount: 0,
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
        );

        await queueManager!.enqueue(queueItem);
        return const Right(null);
      }

      // Create transfer DTO
      final transferDto = TransferDto.fromEntity(transfer);

      // Update via API
      await apiDataSource!.updateTransfer(transfer.id!, transferDto);

      // Invalidate cache
      if (cacheDataSource != null) {
        await cacheDataSource!.invalidateTransfer(transfer.id!);
        await cacheDataSource!.invalidateTransferCache(transfer.userId);
      }

      return const Right(null);
    } on api_exceptions.ApiException catch (e) {
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(ApiFailure('Failed to update transfer: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> _updateTransferViaLocal(Transfer transfer) async {
    try {
      final transferModel = TransferModel.fromEntity(transfer);
      await localDataSource!.updateTransfer(transferModel);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransfer(
    int id,
    int userId, {
    bool refund = false,
  }) async {
    // Use API if available, otherwise fall back to local
    if (apiDataSource != null) {
      return _deleteTransferViaApi(id, userId, refund: refund);
    } else if (localDataSource != null) {
      return _deleteTransferViaLocal(id, userId, refund: refund);
    } else {
      return const Left(DatabaseFailure('No data source available'));
    }
  }

  Future<Either<Failure, void>> _deleteTransferViaApi(
    int id,
    int userId, {
    bool refund = false,
  }) async {
    try {
      // Check connectivity
      final isOnline = connectivityMonitor != null 
          ? await connectivityMonitor!.isOnline 
          : true;

      if (!isOnline && queueManager != null) {
        // Queue operation for later
        final queueItem = QueueItem(
          id: '',
          operation: QueueOperation.delete,
          resourceType: 'transfer',
          data: {
            'id': id,
            'user_id': userId,
            'refund': refund,
          },
          retryCount: 0,
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
        );

        await queueManager!.enqueue(queueItem);
        return const Right(null);
      }

      // Delete via API
      await apiDataSource!.deleteTransfer(id);

      // Invalidate cache
      if (cacheDataSource != null) {
        await cacheDataSource!.invalidateTransfer(id);
        await cacheDataSource!.invalidateTransferCache(userId);
      }

      return const Right(null);
    } on api_exceptions.ApiException catch (e) {
      return Left(ApiFailure(e.message));
    } catch (e) {
      return Left(ApiFailure('Failed to delete transfer: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> _deleteTransferViaLocal(
    int id,
    int userId, {
    bool refund = false,
  }) async {
    try {
      await localDataSource!.deleteTransfer(id, userId, refund: refund);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
