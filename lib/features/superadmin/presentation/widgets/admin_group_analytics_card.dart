import 'package:flutter/material.dart';
import '../../data/models/superadmin_analytics_dto.dart';

/// Admin Group Analytics Card Widget
/// Displays analytics for a single admin group
class AdminGroupAnalyticsCard extends StatelessWidget {
  final AdminGroupAnalyticsData group;

  const AdminGroupAnalyticsCard({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.group,
                    color: theme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.adminGroupName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.adminUserName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        group.adminUserEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Expense Statistics
            _buildStatisticsSection(
              context,
              isArabic,
              icon: Icons.receipt_long,
              title: isArabic ? 'المصروفات' : 'Expenses',
              count: group.expensesCount,
              usd: group.expensesTotalUsd,
              syp: group.expensesTotalSyp,
              tryAmount: group.expensesTotalTry,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),

            // Transfer Statistics
            _buildStatisticsSection(
              context,
              isArabic,
              icon: Icons.swap_horiz,
              title: isArabic ? 'التحويلات' : 'Transfers',
              count: group.transfersCount,
              usd: group.transfersTotalUsd,
              syp: group.transfersTotalSyp,
              tryAmount: group.transfersTotalTry,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    bool isArabic, {
    required IconData icon,
    required String title,
    required int count,
    required double usd,
    required double syp,
    required double tryAmount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Currency Values
          _buildCurrencyRow(context, 'USD', usd, Colors.green),
          const SizedBox(height: 6),
          _buildCurrencyRow(context, 'SYP', syp, Colors.blue),
          const SizedBox(height: 6),
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
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currency,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        Text(
          _formatCurrency(amount, currency),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
