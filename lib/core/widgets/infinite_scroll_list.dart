import 'package:flutter/material.dart';

/// A widget that provides infinite scroll functionality for paginated lists
/// 
/// This widget automatically loads more data when the user scrolls near the bottom
/// of the list. It handles loading states, empty states, and error states.
/// 
/// Example usage:
/// ```dart
/// InfiniteScrollList<Expense>(
///   items: expenses,
///   isLoading: isLoading,
///   hasMore: hasMorePages,
///   onLoadMore: () => bloc.add(LoadMoreExpenses()),
///   itemBuilder: (context, expense) => ExpenseListTile(expense: expense),
///   emptyMessage: 'No expenses found',
/// )
/// ```
class InfiniteScrollList<T> extends StatefulWidget {
  /// The list of items to display
  final List<T> items;
  
  /// Whether data is currently being loaded
  final bool isLoading;
  
  /// Whether there are more pages to load
  final bool hasMore;
  
  /// Callback when more data should be loaded
  final VoidCallback onLoadMore;
  
  /// Builder for each item in the list
  final Widget Function(BuildContext context, T item) itemBuilder;
  
  /// Message to display when the list is empty
  final String emptyMessage;
  
  /// Widget to display when the list is empty (overrides emptyMessage)
  final Widget? emptyWidget;
  
  /// Widget to display while loading the first page
  final Widget? loadingWidget;
  
  /// Widget to display at the bottom while loading more items
  final Widget? loadMoreWidget;
  
  /// Scroll threshold (0.0 to 1.0) at which to trigger loading more
  /// Default is 0.8 (80% scrolled)
  final double scrollThreshold;
  
  /// Optional separator between items
  final Widget? separator;
  
  /// Optional padding for the list
  final EdgeInsetsGeometry? padding;
  
  /// Optional scroll controller
  final ScrollController? controller;
  
  /// Optional refresh callback for pull-to-refresh
  final Future<void> Function()? onRefresh;

  const InfiniteScrollList({
    super.key,
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyMessage = 'No items found',
    this.emptyWidget,
    this.loadingWidget,
    this.loadMoreWidget,
    this.scrollThreshold = 0.8,
    this.separator,
    this.padding,
    this.controller,
    this.onRefresh,
  });

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends State<InfiniteScrollList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * widget.scrollThreshold;

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore || !widget.hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    widget.onLoadMore();
    
    // Reset loading state after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading widget for initial load
    if (widget.isLoading && widget.items.isEmpty) {
      return widget.loadingWidget ?? _buildDefaultLoadingWidget();
    }

    // Show empty state
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? _buildDefaultEmptyWidget();
    }

    // Build the list
    Widget listView = ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: (context, index) {
        return widget.separator ?? const SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        // Show load more indicator at the bottom
        if (index >= widget.items.length) {
          return widget.loadMoreWidget ?? _buildDefaultLoadMoreWidget();
        }

        return widget.itemBuilder(context, widget.items[index]);
      },
    );

    // Wrap with RefreshIndicator if onRefresh is provided
    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildDefaultLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLoadMoreWidget() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// A simpler "Load More" button widget for manual pagination
class LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onPressed;
  final String text;

  const LoadMoreButton({
    super.key,
    required this.isLoading,
    required this.hasMore,
    required this.onPressed,
    this.text = 'Load More',
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No more items',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(text),
        ),
      ),
    );
  }
}
