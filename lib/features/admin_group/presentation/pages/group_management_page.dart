import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/admin_group_bloc.dart';
import '../bloc/admin_group_event.dart';
import '../bloc/admin_group_state.dart';
import '../widgets/group_code_display.dart';
import '../widgets/group_member_list.dart';
import '../../../../core/widgets/watermark_background.dart';

/// Group Management Page for Admin users
/// 
/// This page allows admins to:
/// - View and copy their group code
/// - See group name and member count
/// - View and manage group members
/// - Regenerate group code
/// - Remove members from the group
/// 
/// Requirements: 2.1-2.8
class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({super.key});

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  @override
  void initState() {
    super.initState();
    // Load admin group and members on page load
    // Force refresh from API to ensure we get the current admin's group
    _loadGroupData();
  }
  
  void _loadGroupData() {
    context.read<AdminGroupBloc>().add(LoadAdminGroupEvent());
    context.read<AdminGroupBloc>().add(LoadGroupMembersEvent());
  }

  Future<void> _handleRefresh() async {
    _loadGroupData();
  }

  void _showRegenerateConfirmation() {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n?.regenerateCode ?? 'Regenerate Code',
        ),
        content: Text(
          l10n?.confirmRegenerate ??
              'Regenerating will invalidate the old code. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AdminGroupBloc>().add(RegenerateGroupCodeEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n?.regenerateCode ?? 'Regenerate'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberConfirmation(int userId, String memberName) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          l10n?.confirmRemoveTitle ?? 'Remove Member',
        ),
        content: Text(
          l10n?.confirmRemove ??
              'Are you sure you want to remove this member from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AdminGroupBloc>().add(RemoveGroupMemberEvent(userId: userId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n?.removeMember ?? 'Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.groupManagement ?? 'Group Management',
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: WatermarkBackground(
        child: BlocConsumer<AdminGroupBloc, AdminGroupState>(
          listener: (context, state) {
          // Show success messages
          if (state is GroupCodeRegenerated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.codeRegenerated ??
                      'Group code regenerated successfully',
                ),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is MemberRemoved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.memberRemoved ??
                      'Member removed successfully',
                ),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is AdminGroupError) {
            // Show error messages
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          print('[GroupManagementPage] Current state: ${state.runtimeType}');
          print('[GroupManagementPage] Members count: ${state.members.length}');
          print('[GroupManagementPage] Is loading members: ${state.isLoadingMembers}');
          
          // Loading state
          if (state is AdminGroupLoading && state.adminGroup == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state (initial load)
          if (state is AdminGroupError && state.adminGroup == null) {
            return _buildErrorState(context, state.message);
          }

          // Loaded state
          final adminGroup = state.adminGroup;
          final members = state.members;
          final isLoadingMembers = state.isLoadingMembers;
          final hasMoreMembers = state.hasMoreMembers;

          if (adminGroup == null) {
            return _buildNoGroupState(context);
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              slivers: [
                // Group information section
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Group code display
                        GroupCodeDisplay(
                          groupCode: adminGroup.groupCode,
                          onCopy: () {
                            context.read<AdminGroupBloc>().add(
                                  CopyGroupCodeEvent(groupCode: adminGroup.groupCode),
                                );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Regenerate button
                        OutlinedButton.icon(
                          onPressed: state is AdminGroupLoading
                              ? null
                              : _showRegenerateConfirmation,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            l10n?.regenerateCode ??
                                'Regenerate Code',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: theme.colorScheme.error.withOpacity(0.5),
                            ),
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Group info - only show members count
                        _buildInfoCard(
                          context,
                          icon: Icons.people,
                          label: l10n?.membersCount ??
                              'Members',
                          value: '${adminGroup.membersCount ?? members.length}',
                        ),
                      ],
                    ),
                  ),
                ),

                // Members list section
                SliverFillRemaining(
                  child: GroupMemberList(
                    members: members,
                    isLoading: isLoadingMembers,
                    hasMore: hasMoreMembers,
                    onLoadMore: () {
                      context.read<AdminGroupBloc>().add(
                            LoadGroupMembersEvent(
                              page: state.currentPage + 1,
                              loadMore: true,
                            ),
                          );
                    },
                    onRemoveMember: (userId) {
                      final member = members.firstWhere(
                        (m) => m.id == userId,
                        orElse: () => members.first,
                      );
                      _showRemoveMemberConfirmation(userId, member.name);
                    },
                    // Get current user ID from auth state (if available)
                    currentUserId: _getCurrentUserId(context),
                    showRemoveButtons: true,
                  ),
                ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              errorMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGroupState(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noGroupFound ??
                  'No group found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Get current user ID from AuthBloc if available
  /// Returns null if AuthBloc is not available (e.g., in tests)
  int? _getCurrentUserId(BuildContext context) {
    try {
      return context.read<AuthBloc>().state.user?.id;
    } catch (e) {
      // AuthBloc not available (e.g., in tests)
      return null;
    }
  }
}
