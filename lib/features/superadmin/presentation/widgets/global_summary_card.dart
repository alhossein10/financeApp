import 'package:flutter/material.dart';
import '../../data/models/superadmin_analytics_dto.dart';

/// Global Summary Card Widget
/// Displays aggregated statistics across all admin groups
class GlobalSummaryCard extends StatelessWidget {
  final List<AdminGroupAnalyticsDto> adminGroups;

  const GlobalSummaryCard({
    super.key,
    required this.adminGroups,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    // Calculate totals
    final totals = _calculateTotals();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isArabic ? 'ملخص المجموعة العالمية' : 'Global Group Summary',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Total Invoices Section
            _buildSectionHeader(
              context,
              icon: Icons.receipt_long,
              title: isArabic ? 'إجمالي الفواتير' : 'Total Invoices',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatisticsGrid(
              context,
              isArabic,
              count: totals['invoiceCount'] as int,
              usd: totals['invoiceUsd'] as double,
              syp: totals['invoiceSyp'] as double,
              tryAmount: totals['invoiceTry'] as double,
            ),
            const SizedBox(height: 20),

            // Total Transfers Section
            _buildSectionHeader(
              context,
              icon: Icons.swap_horiz,
              title: isArabic ? 'إجمالي التحويلات' : 'Total Transfers',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatisticsGrid(
              context,
              isArabic,
              count: totals['transferCount'] as int,
              usd: totals['transferUsd'] as double,
              syp: totals['transferSyp'] as double,
              tryAmount: totals['transferTry'] as double,
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate totals across all admin groups
  Map<String, dynamic> _calculateTotals() {
    int invoiceCount = 0;
    double invoiceUsd = 0.0;
    double invoiceSyp = 0.0;
    double invoiceTry = 0.0;

    int transferCount = 0;
    double transferUsd = 0.0;
    double transferSyp = 0.0;
    double transferTry = 0.0;

    for (final group in adminGroups) {
      // Expense totals
      invoiceCount += group.expensesCount;
      invoiceUsd += group.expensesTotalUsd;
      invoiceSyp += group.expensesTotalSyp;
      invoiceTry += group.expensesTotalTry;

      // Transfer totals
      transferCount += group.transfersCount;
      transferUsd += group.transfersTotalUsd;
      transferSyp += group.transfersTotalSyp;
      transferTry += group.transfersTotalTry;
    }

    return {
      'invoiceCount': invoiceCount,
      'invoiceUsd': invoiceUsd,
      'invoiceSyp': invoiceSyp,
      'invoiceTry': invoiceTry,
      'transferCount': transferCount,
      'transferUsd': transferUsd,
      'transferSyp': transferSyp,
      'transferTry': transferTry,
    };
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(
    BuildContext context,
    bool isArabic, {
    required int count,
    required double usd,
    required double syp,
    required double tryAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'العدد الإجمالي:' : 'Total Count:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Currency amounts
          Text(
            isArabic ? 'القيمة الإجمالية:' : 'Total Value:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 12),
          _buildCurrencyRow(context, 'USD', usd, Colors.green),
          const SizedBox(height: 8),
          _buildCurrencyRow(context, 'SYP', syp, Colors.blue),
          const SizedBox(height: 8),
          _buildCurrencyRow(context, 'TRY', tryAmount, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildCurrencyRow(
    BuildContext context,
    String currency,
    double amount,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currency,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        Text(
          _formatCurrency(amount, currency),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount, String currency) {
    if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    } else if (currency == 'SYP') {
      return '${amount.toStringAsFixed(0)} ل.س';
    } else if (currency == 'TRY') {
      return '${amount.toStringAsFixed(2)} ₺';
    }
    return amount.toStringAsFixed(2);
  }
}
