import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/accessibility_utils.dart';

/// Widget that displays multi-currency balances (USD, SYP, TRY)
/// Shows loading and error states
/// Formats each currency appropriately
/// Displays last updated timestamp
class MultiCurrencyBalanceCard extends StatelessWidget {
  final double? balanceUsd;
  final double? balanceSyp;
  final double? balanceTry;
  final DateTime? lastUpdated;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;

  const MultiCurrencyBalanceCard({
    Key? key,
    this.balanceUsd,
    this.balanceSyp,
    this.balanceTry,
    this.lastUpdated,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Create semantic label for the entire card
    final semanticLabel = _buildSemanticLabel();
    
    return Semantics(
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Financial Box',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onRefresh != null)
                      Semantics(
                        label: 'Refresh balances',
                        button: true,
                        enabled: !isLoading,
                        child: ExcludeSemantics(
                          child: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: isLoading ? null : _handleRefresh,
                            tooltip: 'Refresh balances',
                            // Ensure minimum touch target
                            constraints: const BoxConstraints(
                              minWidth: AccessibilityUtils.minTouchTargetSize,
                              minHeight: AccessibilityUtils.minTouchTargetSize,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
            
            // Loading state
            if (isLoading)
              Semantics(
                label: AccessibilityUtils.loadingSemanticLabel('balances'),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            
            // Error state
            else if (errorMessage != null)
              Semantics(
                label: AccessibilityUtils.errorSemanticLabel(errorMessage!),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        semanticLabel: 'Error',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            
            // Balance display
            else
              Column(
                children: [
                  _buildCurrencyRow(
                    context,
                    'USD',
                    balanceUsd ?? 0.0,
                    '\$',
                    theme.colorScheme.primary,
                  ),
                  const Divider(height: 24),
                  _buildCurrencyRow(
                    context,
                    'SYP',
                    balanceSyp ?? 0.0,
                    'S£',
                    theme.colorScheme.secondary,
                  ),
                  const Divider(height: 24),
                  _buildCurrencyRow(
                    context,
                    'TRY',
                    balanceTry ?? 0.0,
                    '₺',
                    theme.colorScheme.tertiary,
                  ),
                ],
              ),
            
            // Last updated timestamp
            if (!isLoading && errorMessage == null && lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last updated: ${_formatTimestamp(lastUpdated!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildCurrencyRow(
    BuildContext context,
    String currencyCode,
    double balance,
    String symbol,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Currency code with icon
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              currencyCode,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        // Balance amount
        Text(
          _formatCurrency(balance, currencyCode),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );
    
    final formattedAmount = formatter.format(amount);
    
    switch (currencyCode) {
      case 'USD':
        return '\$$formattedAmount';
      case 'SYP':
        return 'S£$formattedAmount';
      case 'TRY':
        return '₺$formattedAmount';
      default:
        return formattedAmount;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  /// Build semantic label for the entire card
  String _buildSemanticLabel() {
    if (isLoading) {
      return AccessibilityUtils.loadingSemanticLabel('financial box balances');
    }
    
    if (errorMessage != null) {
      return AccessibilityUtils.errorSemanticLabel(errorMessage!);
    }
    
    final parts = <String>['Financial Box'];
    
    if (balanceUsd != null) {
      parts.add(AccessibilityUtils.currencySemanticLabel(
        balanceUsd!,
        'USD',
        locale: 'en',
      ));
    }
    
    if (balanceSyp != null) {
      parts.add(AccessibilityUtils.currencySemanticLabel(
        balanceSyp!,
        'SYP',
        locale: 'en',
      ));
    }
    
    if (balanceTry != null) {
      parts.add(AccessibilityUtils.currencySemanticLabel(
        balanceTry!,
        'TRY',
        locale: 'en',
      ));
    }
    
    if (lastUpdated != null) {
      parts.add('Last updated ${DateFormat('MMM d, y').format(lastUpdated!)}');
    }
    
    return parts.join(', ');
  }

  /// Handle refresh with haptic feedback
  void _handleRefresh() {
    if (onRefresh != null) {
      AccessibilityUtils.buttonTapFeedback();
      onRefresh!();
    }
  }
}
