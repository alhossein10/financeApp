import 'package:flutter/material.dart';
import '../../../admin_group/data/models/group_member_dto.dart';

/// Widget to display a User member in a list
/// Shows profile image, name, and balances in all currencies
/// 
/// Requirements: 8.2, 8.3, 8.4
class UserListCard extends StatelessWidget {
  final GroupMemberDto user;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final double? balanceUsd;
  final double? balanceSyp;
  final double? balanceTry;

  const UserListCard({
    super.key,
    required this.user,
    required this.onTap,
    this.onRemove,
    this.balanceUsd,
    this.balanceSyp,
    this.balanceTry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Profile Image as Circular Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        color: theme.primaryColor,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Name
                    Text(
                      user.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // User Email
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Balances in all currencies
                    _buildBalanceRow(context, isArabic, theme),
                  ],
                ),
              ),

              // Tap Indicator
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),

              // Remove Button (optional)
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: isArabic ? 'إزالة' : 'Remove',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceRow(BuildContext context, bool isArabic, ThemeData theme) {
    // If no balance data is provided, show a placeholder
    if (balanceUsd == null && balanceSyp == null && balanceTry == null) {
      return Text(
        isArabic ? 'اضغط لعرض التفاصيل' : 'Tap to view details',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        if (balanceUsd != null)
          _buildBalanceChip(
            context,
            'USD',
            balanceUsd!,
            Colors.green,
          ),
        if (balanceSyp != null)
          _buildBalanceChip(
            context,
            'SYP',
            balanceSyp!,
            Colors.blue,
          ),
        if (balanceTry != null)
          _buildBalanceChip(
            context,
            'TRY',
            balanceTry!,
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildBalanceChip(
    BuildContext context,
    String currency,
    double amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '$currency ${_formatAmount(amount)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }
}
