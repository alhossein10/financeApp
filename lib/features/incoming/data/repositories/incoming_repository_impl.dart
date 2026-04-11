import 'package:dartz/dartz.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/queue_item.dart';
import '../../../../core/services/connectivity_monitor.dart';
import '../../../../core/services/queue_manager.dart';
import '../../domain/entities/incoming.dart';
import '../../domain/repositories/incoming_repository.dart';
import '../datasources/incoming_api_datasource.dart';
import '../datasources/incoming_cache_datasource.dart';
import '../datasources/incoming_local_datasource.dart';
import '../models/incoming_dto.dart';

class IncomingRepositoryImpl implements IncomingRepository {
  final IncomingLocalDataSource localDataSource;
  final IncomingApiDataSource apiDataSource;
  final IncomingCacheDataSource cacheDataSource;
  final ConnectivityMonitor connectivityMonitor;
  final QueueManager queueManager;

  IncomingRepositoryImpl({
    required this.localDataSource,
    required this.apiDataSource,
    required this.cacheDataSource,
    required this.connectivityMonitor,
    required this.queueManager,
  });

  @override
  Future<Either<Failure, Incoming>> createIncoming({
    required int userId,
    required String description,
    required double amountUsd,
    DateTime? transactionDate,
  }) async {
    try {
      final date = transactionDate ?? DateTime.now();
      // Format date as YYYY-MM-DD
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Create DTO for API request
      final dto = IncomingDto(
        userId: userId,
        amountUsd: amountUsd,
        source: description, // Use description as source
        description: description,
        date: dateStr,
        paymentMethod: 'cash', // Default payment method
        createdAt: DateTime.now(),
      );

      // Try to create via API if online
      final isOnline = await connectivityMonitor.isOnline;
      if (isOnline) {
        try {
          final createdDto = await apiDataSource.createIncoming(dto);
          final incoming = createdDto.toEntity();
          
          // Cache the created incoming
          await cacheDataSource.cacheIncoming(createdDto);
          await cacheDataSource.clearCache(); // Clear list caches
          
          return Right(incoming);
        } on ApiException {
          // Queue for later sync if API fails
          final tempIncoming = dto.toEntity();
          await _queueIncomingOperation(tempIncoming, QueueOperation.create);
          return Right(tempIncoming);
        }
      } else {
        // Queue for later sync if offline
        final tempIncoming = dto.toEntity();
        await _queueIncomingOperation(tempIncoming, QueueOperation.create);
        return Right(tempIncoming);
      }
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Incoming>>> getIncomingByUser(int userId) async {
    try {
      // NOTE: Data scoping by admin_group_id is handled automatically by the Laravel backend.
      // The API filters incoming transactions based on the authenticated user's admin_group_id from their token.
      // Users only see incoming transactions from members of their admin group.
      
      // Cache-first strategy: Try cache first
      final cachedResponse = await cacheDataSource.getCachedIncomingList();
      if (cachedResponse != null && cachedResponse.data.isNotEmpty) {
        final incomingList = cachedResponse.data.map((dto) => dto.toEntity()).toList();
        return Right(incomingList);
      }

      // If online, fetch from API (automatically filtered by admin_group_id)
      final isOnline = await connectivityMonitor.isOnline;
      if (isOnline) {
        try {
          final response = await apiDataSource.getIncoming();
          
          // Cache the response
          await cacheDataSource.cacheIncomingList(response);
          
          final incomingList = response.data.map((dto) => dto.toEntity()).toList();
          return Right(incomingList);
        } on ApiException {
          // Return empty list if API fails and no cache
          return const Right([]);
        }
      }

      // If offline and no cache, return empty list
      return const Right([]);
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateIncoming(Incoming incoming) async {
    try {
      if (incoming.id == null) {
        return const Left(DatabaseFailure('Cannot update incoming without ID'));
      }

      // Try to update via API if online
      final isOnline = await connectivityMonitor.isOnline;
      if (isOnline) {
        try {
          final dto = IncomingDto.fromEntity(incoming);
          await apiDataSource.updateIncoming(incoming.id!, dto);
          
          // Clear ALL cache (both individual and list caches)
          await cacheDataSource.clearIncomingCache(incoming.id!);
          await cacheDataSource.clearCache(); // Clear list caches too
          
          return const Right(null);
        } on ApiException {
          // Queue for later sync if API fails
          await _queueIncomingOperation(incoming, QueueOperation.update);
          return const Right(null);
        }
      } else {
        // Queue for later sync if offline
        await _queueIncomingOperation(incoming, QueueOperation.update);
        return const Right(null);
      }
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIncoming(
    int id,
    int userId, {
    bool refund = false,
  }) async {
    try {
      // Try to delete via API if online
      final isOnline = await connectivityMonitor.isOnline;
      if (isOnline) {
        try {
          await apiDataSource.deleteIncoming(id);
          
          // Clear ALL cache (both individual and list caches)
          await cacheDataSource.clearIncomingCache(id);
          await cacheDataSource.clearCache(); // Clear list caches too
          
          return const Right(null);
        } on ApiException {
          // Queue for later sync if API fails
          final queueItem = QueueItem(
            id: '',
            operation: QueueOperation.delete,
            resourceType: 'incoming',
            data: {'id': id, 'user_id': userId, 'refund': refund},
            createdAt: DateTime.now(),
            status: QueueStatus.pending,
            retryCount: 0,
          );
          await queueManager.enqueue(queueItem);
          return const Right(null);
        }
      } else {
        // Queue for later sync if offline
        final queueItem = QueueItem(
          id: '',
          operation: QueueOperation.delete,
          resourceType: 'incoming',
          data: {'id': id, 'user_id': userId, 'refund': refund},
          createdAt: DateTime.now(),
          status: QueueStatus.pending,
          retryCount: 0,
        );
        await queueManager.enqueue(queueItem);
        return const Right(null);
      }
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  /// Helper method to queue incoming operations for offline sync
  Future<void> _queueIncomingOperation(
    Incoming incoming,
    QueueOperation operation,
  ) async {
    try {
      final queueItem = QueueItem(
        id: '',
        operation: operation,
        resourceType: 'incoming',
        data: IncomingDto.fromEntity(incoming, paymentMethod: 'cash').toJson(),
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
