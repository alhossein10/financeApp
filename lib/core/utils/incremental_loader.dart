import 'package:flutter/foundation.dart';

/// Helper for implementing incremental/infinite scroll loading
class IncrementalLoader<T> {
  final Future<List<T>> Function(int page) loadPage;
  final int pageSize;
  
  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  IncrementalLoader({
    required this.loadPage,
    this.pageSize = 15,
  });

  /// Get current items
  List<T> get items => List.unmodifiable(_items);
  
  /// Check if currently loading
  bool get isLoading => _isLoading;
  
  /// Check if more items are available
  bool get hasMore => _hasMore;
  
  /// Get current error if any
  String? get error => _error;
  
  /// Get current page number
  int get currentPage => _currentPage;
  
  /// Get total items loaded
  int get itemCount => _items.length;

  /// Load next page of items
  Future<void> loadNext() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;

    try {
      final nextPage = _currentPage + 1;
      final newItems = await loadPage(nextPage);
      
      _items.addAll(newItems);
      _currentPage = nextPage;
      
      // If we got fewer items than page size, we've reached the end
      if (newItems.length < pageSize) {
        _hasMore = false;
      }
      
      debugPrint('Loaded page $nextPage: ${newItems.length} items');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading page ${_currentPage + 1}: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Refresh from the beginning
  Future<void> refresh() async {
    _currentPage = 0;
    _items.clear();
    _hasMore = true;
    _error = null;
    
    await loadNext();
  }

  /// Reset loader state
  void reset() {
    _currentPage = 0;
    _items.clear();
    _hasMore = true;
    _error = null;
    _isLoading = false;
  }

  /// Check if should load more based on scroll position
  /// 
  /// Returns true if we're near the end and should trigger loading
  bool shouldLoadMore({
    required int visibleItemIndex,
    int threshold = 5,
  }) {
    if (!_hasMore || _isLoading) return false;
    
    // Load more when we're within threshold items of the end
    return visibleItemIndex >= _items.length - threshold;
  }
}

/// State for incremental loading in BLoC/State management
class IncrementalLoadingState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const IncrementalLoadingState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  IncrementalLoadingState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return IncrementalLoadingState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get itemCount => items.length;
}
