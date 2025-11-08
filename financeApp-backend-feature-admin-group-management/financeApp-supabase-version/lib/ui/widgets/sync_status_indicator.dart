import 'package:flutter/material.dart';
import '../../features/expenses/domain/entities/expense.dart';

/// Widget that displays the synchronization status of an expense
/// Shows different icons, colors, and labels based on the sync status
class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onRetry;
  final bool compact;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactIndicator(context);
    }
    return _buildChipIndicator(context);
  }

  Widget _buildCompactIndicator(BuildContext context) {
    switch (status) {
      case SyncStatus.pending:
        return const Tooltip(
          message: 'Pending Sync',
          child: Icon(Icons.schedule, size: 16, color: Colors.orange),
        );

      case SyncStatus.syncing:
        return const Tooltip(
          message: 'Syncing...',
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
          ),
        );

      case SyncStatus.synced:
        return const Tooltip(
          message: 'Synced',
          child: Icon(Icons.cloud_done, size: 16, color: Colors.green),
        );

      case SyncStatus.failed:
        return Tooltip(
          message: 'Sync Failed - Tap to retry',
          child: InkWell(
            onTap: onRetry,
            child: const Icon(Icons.error, size: 16, color: Colors.red),
          ),
        );
    }
  }

  Widget _buildChipIndicator(BuildContext context) {
    switch (status) {
      case SyncStatus.pending:
        return Chip(
          avatar: const Icon(Icons.schedule, size: 16, color: Colors.white),
          label: const Text('Pending Sync', style: TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

      case SyncStatus.syncing:
        return const Chip(
          avatar: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          label: Text('Syncing...', style: TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

      case SyncStatus.synced:
        return Chip(
          avatar: const Icon(Icons.cloud_done, size: 16, color: Colors.white),
          label: const Text('Synced', style: TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

      case SyncStatus.failed:
        return Chip(
          avatar: const Icon(Icons.error, size: 16, color: Colors.white),
          label: const Text('Sync Failed', style: TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: Colors.red,
          deleteIcon: const Icon(Icons.refresh, size: 16, color: Colors.white),
          onDeleted: onRetry,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
    }
  }
}
