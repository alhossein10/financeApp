import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for optimizing API requests through debouncing and batching
class ApiRequestOptimizer {
  // Debounce timers for different operations
  final Map<String, Timer?> _debounceTimers = {};
  
  // Batch queues for different resource types
  final Map<String, List<BatchOperation>> _batchQueues = {};
  
  // Batch processing timers
  final Map<String, Timer?> _batchTimers = {};
  
  // Default debounce duration
  static const Duration defaultDebounceDuration = Duration(milliseconds: 500);
  
  // Default batch processing interval
  static const Duration defaultBatchInterval = Duration(seconds: 2);
  
  // Maximum batch size
  static const int maxBatchSize = 50;

  /// Debounce an API request
  /// 
  /// Delays execution of [operation] until [duration] has passed without
  /// another call to debounce with the same [key]
  Future<T> debounce<T>({
    required String key,
    required Future<T> Function() operation,
    Duration duration = defaultDebounceDuration,
  }) async {
    // Cancel existing timer for this key
    _debounceTimers[key]?.cancel();
    
    // Create completer for the result
    final completer = Completer<T>();
    
    // Set new timer
    _debounceTimers[key] = Timer(duration, () async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      } finally {
        _debounceTimers.remove(key);
      }
    });
    
    return completer.future;
  }

  /// Add operation to batch queue
  /// 
  /// Operations are automatically processed when:
  /// - Batch size reaches [maxBatchSize]
  /// - [batchInterval] time has passed since first operation
  void addToBatch({
    required String resourceType,
    required String operationType,
    required Map<String, dynamic> data,
    required Function(dynamic result) onComplete,
    required Function(dynamic error) onError,
    Duration batchInterval = defaultBatchInterval,
  }) {
    final operation = BatchOperation(
      resourceType: resourceType,
      operationType: operationType,
      data: data,
      onComplete: onComplete,
      onError: onError,
    );
    
    // Initialize queue if needed
    _batchQueues[resourceType] ??= [];
    
    // Add to queue
    _batchQueues[resourceType]!.add(operation);
    
    // Check if we should process immediately
    if (_batchQueues[resourceType]!.length >= maxBatchSize) {
      _processBatch(resourceType);
    } else if (_batchTimers[resourceType] == null) {
      // Start timer for batch processing
      _batchTimers[resourceType] = Timer(batchInterval, () {
        _processBatch(resourceType);
      });
    }
  }

  /// Process batch queue for a resource type
  void _processBatch(String resourceType) {
    _batchTimers[resourceType]?.cancel();
    _batchTimers.remove(resourceType);
    
    final operations = _batchQueues[resourceType];
    if (operations == null || operations.isEmpty) return;
    
    // Clear the queue
    _batchQueues[resourceType] = [];
    
    // Process operations
    // Note: Actual batch API call should be implemented by the caller
    debugPrint('Processing batch of ${operations.length} operations for $resourceType');
    
    // For now, just notify that operations are ready to be processed
    for (final operation in operations) {
      operation.onComplete({'status': 'queued', 'data': operation.data});
    }
  }

  /// Manually trigger batch processing for a resource type
  void processBatchNow(String resourceType) {
    _processBatch(resourceType);
  }

  /// Get pending batch operations for a resource type
  List<BatchOperation> getPendingOperations(String resourceType) {
    return List.unmodifiable(_batchQueues[resourceType] ?? []);
  }

  /// Cancel all pending debounce timers
  void cancelAllDebounce() {
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
  }

  /// Cancel all batch timers
  void cancelAllBatches() {
    for (final timer in _batchTimers.values) {
      timer?.cancel();
    }
    _batchTimers.clear();
    _batchQueues.clear();
  }

  /// Dispose and clean up all resources
  void dispose() {
    cancelAllDebounce();
    cancelAllBatches();
  }
}

/// Represents a batched operation
class BatchOperation {
  final String resourceType;
  final String operationType;
  final Map<String, dynamic> data;
  final Function(dynamic result) onComplete;
  final Function(dynamic error) onError;

  BatchOperation({
    required this.resourceType,
    required this.operationType,
    required this.data,
    required this.onComplete,
    required this.onError,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': resourceType,
      'action': operationType,
      'data': data,
    };
  }
}
