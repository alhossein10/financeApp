import 'package:flutter/material.dart';
import '../../../admin_group/data/models/group_member_dto.dart';

/// Bottom sheet widget to display detailed User information
/// Shows user profile, contact info, and organization details
/// 
/// Requirements: 8.5
class UserDetailSheet extends StatelessWidget {
  final GroupMemberDto user;

  const UserDetailSheet({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: theme.primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.role,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildInfoCard(
                  context,
                  isArabic,
                  theme,
                  Icons.email,
                  isArabic ? 'البريد الإلكتروني' : 'Email',
                  user.email,
                ),
                const SizedBox(height: 12),

                if (user.organizationName != null)
                  _buildInfoCard(
                    context,
                    isArabic,
                    theme,
                    Icons.business,
                    isArabic ? 'المنظمة' : 'Organization',
                    user.organizationName!,
                  ),
                if (user.organizationName != null) const SizedBox(height: 12),

                if (user.departmentName != null)
                  _buildInfoCard(
                    context,
                    isArabic,
                    theme,
                    Icons.apartment,
                    isArabic ? 'القسم' : 'Department',
                    user.departmentName!,
                  ),
                if (user.departmentName != null) const SizedBox(height: 12),

                _buildInfoCard(
                  context,
                  isArabic,
                  theme,
                  Icons.calendar_today,
                  isArabic ? 'تاريخ الانضمام' : 'Joined',
                  _formatDate(user.createdAt, isArabic),
                ),
                const SizedBox(height: 24),

                // Note about balances
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'لعرض الأرصدة المالية، انتقل إلى صفحة الصندوق المالي'
                              : 'To view financial balances, go to the Financial Box page',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isArabic ? 'إغلاق' : 'Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isArabic,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr, bool isArabic) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays < 1) {
        return isArabic ? 'اليوم' : 'Today';
      } else if (difference.inDays < 7) {
        return isArabic
            ? '${difference.inDays} أيام مضت'
            : '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return isArabic
            ? '$weeks ${weeks == 1 ? 'أسبوع' : 'أسابيع'} مضت'
            : '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return isArabic
            ? '$months ${months == 1 ? 'شهر' : 'أشهر'} مضت'
            : '$months ${months == 1 ? 'month' : 'months'} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return isArabic
            ? '$years ${years == 1 ? 'سنة' : 'سنوات'} مضت'
            : '$years ${years == 1 ? 'year' : 'years'} ago';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
