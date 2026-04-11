import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/group_member.dart';
import 'member_fund_box_balance.dart';

/// Widget to display a group member's information with optional remove button
class GroupMemberCard extends StatelessWidget {
  final GroupMember member;
  final bool showRemoveButton;
  final VoidCallback? onRemove;
  final bool isCurrentUser;

  const GroupMemberCard({
    super.key,
    required this.member,
    this.showRemoveButton = true,
    this.onRemove,
    this.isCurrentUser = false,
  });

  Future<void> _showRemoveConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.confirmRemoveTitle ??
              'Remove Member',
        ),
        content: Text(
          AppLocalizations.of(context)?.confirmRemove ??
              'Are you sure you want to remove this member from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              AppLocalizations.of(context)?.removeMember ??
                  'Remove',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && onRemove != null) {
      onRemove!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with profile photo
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty
                  ? NetworkImage(member.profileImageUrl!)
                  : null,
              child: member.profileImageUrl == null || member.profileImageUrl!.isEmpty
                  ? Text(
                      _getInitials(member.name),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Member information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with role badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (member.role == 'admin')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.adminBadge ??
                                'Admin',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Email
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          member.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Department (if available)
                  if (member.departmentName != null && member.departmentName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            member.departmentName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Organization (if available)
                  if (member.organizationName != null && member.organizationName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.apartment_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            member.organizationName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Fund Box Balance (for SuperAdmin viewing Admin, or Admin viewing Users)
                  MemberFundBoxBalance(
                    userId: member.id,
                    userRole: member.role,
                    isCurrentUser: isCurrentUser,
                  ),
                ],
              ),
            ),
            
            // Remove button (conditionally shown)
            if (showRemoveButton && !isCurrentUser && onRemove != null)
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: () => _showRemoveConfirmation(context),
                tooltip: AppLocalizations.of(context)?.removeMember ??
                    'Remove member',
              ),
            
            // Current user indicator (cannot remove self)
            if (isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Tooltip(
                  message: AppLocalizations.of(context)?.cannotRemoveSelf ??
                      'You cannot remove yourself',
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
