import 'package:flutter/material.dart';
import '../../data/models/admin_member_dto.dart';

/// Widget to display an Admin member in a list
/// Shows profile image, name, email, and tap handler
class AdminListCard extends StatelessWidget {
  final AdminMemberDto admin;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const AdminListCard({
    super.key,
    required this.admin,
    required this.onTap,
    this.onRemove,
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
                backgroundImage: admin.profileImageUrl != null && admin.profileImageUrl!.isNotEmpty
                    ? NetworkImage(admin.profileImageUrl!)
                    : null,
                child: admin.profileImageUrl == null || admin.profileImageUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        color: theme.primaryColor,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Admin Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Name
                    Text(
                      admin.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Admin Email
                    Text(
                      admin.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Admin Group Info
                    if (admin.adminGroupName != null)
                      Text(
                        '${isArabic ? 'المجموعة:' : 'Group:'} ${admin.adminGroupName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),

                    // User Count
                    Text(
                      '${admin.userCount} ${isArabic ? 'مستخدم' : 'users'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
}
