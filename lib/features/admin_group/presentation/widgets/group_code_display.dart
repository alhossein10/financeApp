import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';

/// Widget to display a group code prominently with copy-to-clipboard functionality
class GroupCodeDisplay extends StatefulWidget {
  final String groupCode;
  final VoidCallback? onCopy;
  final bool showCopyButton;
  final EdgeInsetsGeometry? padding;

  const GroupCodeDisplay({
    Key? key,
    required this.groupCode,
    this.onCopy,
    this.showCopyButton = true,
    this.padding,
  }) : super(key: key);

  @override
  State<GroupCodeDisplay> createState() => _GroupCodeDisplayState();
}

class _GroupCodeDisplayState extends State<GroupCodeDisplay> {
  bool _showCopiedMessage = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.groupCode));
    
    setState(() {
      _showCopiedMessage = true;
    });

    // Call the optional callback
    widget.onCopy?.call();

    // Hide the message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCopiedMessage = false;
        });
      }
    });

    // Show snackbar confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('admin_group.code_copied') ??
                'Group code copied to clipboard',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label
          Text(
            AppLocalizations.of(context).translate('admin_group.group_code') ??
                'Group Code',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Group code display with copy button
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Group code
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    widget.groupCode.toUpperCase(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                
                if (widget.showCopyButton) ...[
                  const SizedBox(width: 12),
                  
                  // Copy button
                  Material(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _copyToClipboard,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showCopiedMessage ? Icons.check : Icons.copy,
                              color: theme.colorScheme.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showCopiedMessage
                                  ? (AppLocalizations.of(context).translate('admin_group.copied') ?? 'Copied!')
                                  : (AppLocalizations.of(context).translate('admin_group.copy_code') ?? 'Copy'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Helper text
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).translate('admin_group.share_with_team') ??
                'Share this code with your team members',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
