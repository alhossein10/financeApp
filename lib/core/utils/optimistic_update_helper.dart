import 'package:flutter/foundation.dart';

/// Helper for implementing optimistic UI updates
class OptimisticUpdateHelper<T> {
  final List<T> _items;
  final Map<String, T> _pendingUpdates = {};
  final Map<String, T> _rollbackData = {};

  OptimisticUpdateHelper(this._items);

  /// Get current items including pending updates
  List<T> get items => List.unmodifiable(_items);

  /// Add item optimistically
  /// 
  /// Returns a rollback function that can be called if the operation fails
  Future<void> Function() addOptimistically({
    required T item,
    required String tempId,
    required Future<T> Function() apiCall,
    required void Function(T item) onSuccess,
    required void Function(dynamic error) onError,
  }) {
    // Add item immediately
    _items.add(item);
    _pendingUpdates[tempId] = item;

    // Execute API call in background
    apiCall().then((result) {
      // Replace temp item with real item
      final index = _items.indexOf(item);
      if (index != -1) {
        _items[index] = result;
      }
      _pendingUpdates.remove(tempId);
      onSuccess(result);
    }).catchError((error) {
      // Rollback on error
      _items.remove(item);
      _pendingUpdates.remove(tempId);
      onError(error);
    });

    // Return rollback function
    return () async {
      _items.remove(item);
      _pendingUpdates.remove(tempId);
    };
  }

  /// Update item optimistically
  /// 
  /// Returns a rollback function that can be called if the operation fails
  Future<void> Function() updateOptimistically({
    required T oldItem,
    required T newItem,
    required String itemId,
    required Future<T> Function() apiCall,
    required void Function(T item) onSuccess,
    required void Function(dynamic error) onError,
  }) {
    // Store rollback data
    _rollbackData[itemId] = oldItem;

    // Update item immediately
    final index = _items.indexOf(oldItem);
    if (index != -1) {
      _items[index] = newItem;
      _pendingUpdates[itemId] = newItem;
    }

    // Execute API call in background
    apiCall().then((result) {
      // Update with server response
      final currentIndex = _items.indexOf(newItem);
      if (currentIndex != -1) {
        _items[currentIndex] = result;
      }
      _pendingUpdates.remove(itemId);
      _rollbackData.remove(itemId);
      onSuccess(result);
    }).catchError((error) {
      // Rollback on error
      final currentIndex = _items.indexOf(newItem);
      if (currentIndex != -1 && _rollbackData.containsKey(itemId)) {
        _items[currentIndex] = _rollbackData[itemId] as T;
      }
      _pendingUpdates.remove(itemId);
      _rollbackData.remove(itemId);
      onError(error);
    });

    // Return rollback function
    return () async {
      final currentIndex = _items.indexOf(newItem);
      if (currentIndex != -1 && _rollbackData.containsKey(itemId)) {
        _items[currentIndex] = _rollbackData[itemId] as T;
      }
      _pendingUpdates.remove(itemId);
      _rollbackData.remove(itemId);
    };
  }

  /// Delete item optimistically
  /// 
  /// Returns a rollback function that can be called if the operation fails
  Future<void> Function() deleteOptimistically({
    required T item,
    required String itemId,
    required Future<void> Function() apiCall,
    required void Function() onSuccess,
    required void Function(dynamic error) onError,
  }) {
    // Store rollback data
    final index = _items.indexOf(item);
    _rollbackData[itemId] = item;

    // Remove item immediately
    _items.remove(item);
    _pendingUpdates[itemId] = item;

    // Execute API call in background
    apiCall().then((_) {
      _pendingUpdates.remove(itemId);
      _rollbackData.remove(itemId);
      onSuccess();
    }).catchError((error) {
      // Rollback on error - restore item at original position
      if (_rollbackData.containsKey(itemId)) {
        if (index >= 0 && index <= _items.length) {
          _items.insert(index, _rollbackData[itemId] as T);
        } else {
          _items.add(_rollbackData[itemId] as T);
        }
      }
      _pendingUpdates.remove(itemId);
      _rollbackData.remove(itemId);
      onError(error);
    });

    // Return rollback function
    return () async {
      if (_rollbackData.containsKey(itemId)) {
        if (index >= 0 && index <= _items.length) {
          _items.insert(index, _rollbackData[itemId] as T);
        } else {
          _items.add(_rollbackData[itemId] as T);
        }
      }
      _pendingUpdates.remove(itemId);
      _rollbackData.remove(itemId);
    };
  }

  /// Check if an item has a pending update
  bool hasPendingUpdate(String itemId) {
    return _pendingUpdates.containsKey(itemId);
  }

  /// Get all pending update IDs
  List<String> get pendingUpdateIds => _pendingUpdates.keys.toList();

  /// Clear all pending updates and rollback data
  void clear() {
    _pendingUpdates.clear();
    _rollbackData.clear();
  }
}

/// Mixin for adding optimistic update support to BLoCs
mixin OptimisticUpdateMixin<T> {
  late OptimisticUpdateHelper<T> optimisticHelper;

  void initializeOptimisticHelper(List<T> items) {
    optimisticHelper = OptimisticUpdateHelper<T>(items);
  }

  bool hasPendingUpdate(String itemId) {
    return optimisticHelper.hasPendingUpdate(itemId);
  }

  void clearOptimisticUpdates() {
    optimisticHelper.clear();
  }
}

/// Extension for showing optimistic update indicators
extension OptimisticUpdateIndicator on Widget {
  Widget withOptimisticIndicator({
    required bool isPending,
    Color? indicatorColor,
  }) {
    if (!isPending) return this;

    return Stack(
      children: [
        Opacity(
          opacity: 0.6,
          child: this,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: indicatorColor ?? Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
