import 'package:flutter/material.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/token_manager.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../injection_container.dart' as di;

/// Dialog widget for previewing invoice images
/// Displays full-screen invoice image with zoom controls
/// Handles loading states and errors gracefully
/// 
/// Requirements: 11.7, 25.1, 25.2, 25.3, 25.4, 25.5, 25.6, 25.7, 25.8
class InvoicePreviewDialog extends StatefulWidget {
  final int expenseId;
  final String? localFilePath; // Optional local file path for offline viewing

  const InvoicePreviewDialog({
    super.key,
    required this.expenseId,
    this.localFilePath,
  });

  @override
  State<InvoicePreviewDialog> createState() => _InvoicePreviewDialogState();
}

class _InvoicePreviewDialogState extends State<InvoicePreviewDialog> {
  final TransformationController _transformationController = TransformationController();
  String? _authToken;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthToken() async {
    try {
      final tokenManager = di.sl<TokenManager>();
      final token = await tokenManager.getToken();
      
      if (mounted) {
        setState(() {
          _authToken = token;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load authentication token';
          _isLoading = false;
        });
      }
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(1.0, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(1.0, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  String get _imageUrl {
    return '${ApiConfig.apiUrl}/expenses/${widget.expenseId}/invoice';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.translate('invoice_image')),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            // Zoom controls
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoomOut,
              tooltip: l10n.translate('zoom_out'),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoomIn,
              tooltip: l10n.translate('zoom_in'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetZoom,
              tooltip: l10n.translate('reset_zoom'),
            ),
          ],
        ),
        body: _buildBody(context, l10n, theme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    // Show loading indicator
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.translate('loading_invoice'),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    // Show error if authentication failed
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('failed_to_load_image'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadAuthToken();
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    // Show image with zoom controls
    return Container(
      color: Colors.black,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            _imageUrl,
            fit: BoxFit.contain,
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Accept': 'application/json',
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              final progress = loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Text(
                      progress != null
                          ? '${(progress * 100).toStringAsFixed(0)}%'
                          : l10n.translate('loading'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('[InvoicePreview] ❌ Image load error: $error');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.translate('failed_to_load_image'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadAuthToken();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.translate('retry')),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Helper function to show invoice preview dialog
Future<void> showInvoicePreview({
  required BuildContext context,
  required int expenseId,
  String? localFilePath,
}) {
  return showDialog(
    context: context,
    builder: (context) => InvoicePreviewDialog(
      expenseId: expenseId,
      localFilePath: localFilePath,
    ),
  );
}
