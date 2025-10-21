import 'package:flutter/material.dart';
import '../../domain/entities/user_statistics.dart';

/// Card displaying user statistics
class ProfileStatisticsCard extends StatelessWidget {
  final UserStatistics statistics;

  const ProfileStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _StatisticItem(
                    icon: Icons.trending_down,
                    label: 'Total Expenses',
                    value: '\$${statistics.totalExpenses.toStringAsFixed(2)}',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatisticItem(
                    icon: Icons.send,
                    label: 'Total Transfers',
                    value: '\$${statistics.totalTransfers.toStringAsFixed(2)}',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _StatisticItem(
                    icon: Icons.receipt_long,
                    label: 'Total Transactions',
                    value: statistics.totalTransactions.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatisticItem(
                    icon: Icons.calendar_today,
                    label: 'Account Age',
                    value: statistics.accountAgeFormatted,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            if (statistics.lastActivity != null) ...[
              const SizedBox(height: 16),
              _StatisticItem(
                icon: Icons.access_time,
                label: 'Last Activity',
                value: _formatLastActivity(statistics.lastActivity!),
                color: Colors.orange,
                fullWidth: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  const _StatisticItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: fullWidth
          ? Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}