import 'package:flutter/material.dart';

/// Comprehensive loading indicators for various UI scenarios
/// Implements requirements 28.1-28.8 for loading states

/// Primary loading indicator for general use
class PrimaryLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const PrimaryLoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading button for forms - shows loading state on button
class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final IconData? icon;
  final ButtonStyle? style;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style ??
          ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            minimumSize: const Size(double.infinity, 48),
          ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}

/// Image placeholder with loading indicator
class ImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Progress indicator for file uploads
class FileUploadProgress extends StatelessWidget {
  final String fileName;
  final double progress; // 0.0 to 1.0
  final VoidCallback? onCancel;

  const FileUploadProgress({
    super.key,
    required this.fileName,
    required this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploading... $percentage%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                    tooltip: 'Cancel upload',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Progress indicator for exports (PDF, Excel)
class ExportProgress extends StatelessWidget {
  final String exportType; // 'PDF', 'Excel', 'Images'
  final String status; // 'Preparing', 'Generating', 'Finalizing'
  final double? progress; // Optional progress value

  const ExportProgress({
    super.key,
    required this.exportType,
    required this.status,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForExportType(exportType),
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Exporting $exportType',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (progress != null)
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceVariant,
              )
            else
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  IconData _getIconForExportType(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'excel':
        return Icons.table_chart;
      case 'images':
        return Icons.photo_library;
      default:
        return Icons.download;
    }
  }
}

/// Timeout warning overlay for long operations
class TimeoutWarning extends StatelessWidget {
  final String message;
  final VoidCallback? onCancel;
  final VoidCallback? onContinue;

  const TimeoutWarning({
    super.key,
    this.message = 'This is taking longer than expected...',
    this.onCancel,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The operation is still in progress.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                    if (onContinue != null)
                      ElevatedButton(
                        onPressed: onContinue,
                        child: const Text('Keep Waiting'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pull-to-refresh wrapper with custom indicator
class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? indicatorColor;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: indicatorColor ?? Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}

/// Loading overlay for full-screen operations
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: PrimaryLoadingIndicator(message: message),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
