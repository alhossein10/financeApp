import 'package:flutter/material.dart';

/// Optimized ListView.builder with pagination support
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.emptyWidget,
    this.loadingWidget,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
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
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0; // Trigger load more 200px before reaching the end

    if (maxScroll - currentScroll <= delta) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.items.length + (widget.hasMore || _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return widget.itemBuilder(context, widget.items[index], index);
        }

        // Loading indicator at the bottom
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: widget.loadingWidget ??
                const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

/// Optimized grid view with lazy loading
class OptimizedGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.emptyWidget,
    this.padding,
    this.controller,
  });

  @override
  State<OptimizedGridView<T>> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends State<OptimizedGridView<T>> {
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
    if (_isLoadingMore || !widget.hasMore || widget.onLoadMore == null) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = 200.0;

    if (maxScroll - currentScroll <= delta) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No items found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: widget.items.length + (widget.hasMore || _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return widget.itemBuilder(context, widget.items[index], index);
        }

        // Loading indicator
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

/// Sliver list with optimized rendering
class OptimizedSliverList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  const OptimizedSliverList({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => itemBuilder(context, items[index], index),
        childCount: items.length,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        addSemanticIndexes: true,
      ),
    );
  }
}

/// Optimized list tile with repaint boundary
class OptimizedListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const OptimizedListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: contentPadding,
      ),
    );
  }
}
