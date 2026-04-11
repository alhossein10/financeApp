import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/offline_operation_queue.dart';

/// Persistent banner that displays when offline
/// Shows connectivity status and pending sync operations
class OfflineIndicator extends StatelessWidget {
  final ConnectivityService connectivityService;
  final OfflineOperationQueue? operationQueue;
  final bool showSyncStatus;

  const OfflineIndicator({
    Key? key,
    required this.connectivityService,
    this.operationQueue,
    this.showSyncStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityStatus>(
      stream: connectivityService.statusStream,
      initialData: connectivityService.currentStatus,
      builder: (context, connectivitySnapshot) {
        final isOffline = connectivitySnapshot.data?.isOffline ?? false;

        if (!isOffline && !showSyncStatus) {
          return const SizedBox.shrink();
        }

        if (operationQueue != null && showSyncStatus) {
          return StreamBuilder<OfflineSyncStatus>(
            stream: operationQueue!.syncStatusStream,
            builder: (context, syncSnapshot) {
              return _buildIndicatorBanner(
                context,
                isOffline: isOffline,
                syncStatus: syncSnapshot.data,
              );
            },
          );
        }

        return _buildIndicatorBanner(context, isOffline: isOffline);
      },
    );
  }

  Widget _buildIndicatorBanner(
    BuildContext context, {
    required bool isOffline,
    OfflineSyncStatus? syncStatus,
  }) {
    // Don't show anything if online and synced
    if (!isOffline && (syncStatus == null || syncStatus.isSynced)) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    IconData icon;
    String message;

    if (isOffline) {
      backgroundColor = Colors.orange.shade700;
      icon = Icons.cloud_off;
      message = 'You are offline';
      
      if (syncStatus != null && syncStatus.isQueued) {
        message = 'Offline - Changes will sync when online';
      }
    } else if (syncStatus != null) {
      switch (syncStatus) {
        case OfflineSyncStatus.syncing:
          backgroundColor = Colors.blue.shade700;
          icon = Icons.sync;
          message = 'Syncing changes...';
          break;
        case OfflineSyncStatus.failed:
          backgroundColor = Colors.red.shade700;
          icon = Icons.sync_problem;
          message = 'Sync failed - Will retry';
          break;
        case OfflineSyncStatus.partialSync:
          backgroundColor = Colors.orange.shade700;
          icon = Icons.sync_problem;
          message = 'Some changes synced';
          break;
        case OfflineSyncStatus.queued:
          backgroundColor = Colors.blue.shade700;
          icon = Icons.schedule;
          message = 'Changes queued for sync';
          break;
        default:
          return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }

    return Material(
      color: backgroundColor,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (syncStatus != null && syncStatus.isFailed && operationQueue != null)
                TextButton(
                  onPressed: () => operationQueue!.retryFailedOperations(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text('RETRY'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that shows cached data indicator
class CachedDataIndicator extends StatelessWidget {
  final DateTime? cacheTimestamp;
  final bool isOffline;

  const CachedDataIndicator({
    Key? key,
    this.cacheTimestamp,
    required this.isOffline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOffline || cacheTimestamp == null) {
      return const SizedBox.shrink();
    }

    final timeDiff = DateTime.now().difference(cacheTimestamp!);
    final timeAgo = _formatTimeAgo(timeDiff);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cached,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            'Cached data from $timeAgo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }
}

/// Mixin for widgets that need offline awareness
mixin OfflineAwareMixin<T extends StatefulWidget> on State<T> {
  ConnectivityService? _connectivityService;
  OfflineOperationQueue? _operationQueue;
  
  bool _isOffline = false;
  
  bool get isOffline => _isOffline;
  bool get isOnline => !_isOffline;

  /// Initialize offline awareness
  void initOfflineAwareness({
    required ConnectivityService connectivityService,
    OfflineOperationQueue? operationQueue,
  }) {
    _connectivityService = connectivityService;
    _operationQueue = operationQueue;
    _isOffline = !connectivityService.isOnline;

    // Listen to connectivity changes
    connectivityService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isOffline = status.isOffline;
        });
        onConnectivityChanged(status);
      }
    });
  }

  /// Called when connectivity status changes
  void onConnectivityChanged(ConnectivityStatus status) {
    // Override in subclass if needed
  }

  /// Show offline message
  void showOfflineMessage(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message ?? 'You are offline. Changes will sync when online.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show operation queued message
  void showOperationQueuedMessage(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message ?? 'Operation queued. Will sync when online.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Prevent balance-dependent operations when offline
  bool canPerformBalanceOperation(BuildContext context) {
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cannot perform this operation offline. Balance verification required.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }
}

