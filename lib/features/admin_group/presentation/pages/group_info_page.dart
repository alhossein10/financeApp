import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/admin_group_bloc.dart';
import '../bloc/admin_group_event.dart';
import '../bloc/admin_group_state.dart';
import '../widgets/group_code_display.dart';

/// Group Info Page for Regular Users
/// 
/// This page allows regular users to:
/// - View their group information
/// - See group code, name, and admin details
/// - View member count and join date
/// - Get help text about contacting admin
/// 
/// Requirements: 3.1-3.6
class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({super.key});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  @override
  void initState() {
    super.initState();
    // Load user group info on page load
    context.read<AdminGroupBloc>().add(LoadUserGroupInfoEvent());
  }

  Future<void> _handleRefresh() async {
    context.read<AdminGroupBloc>().add(LoadUserGroupInfoEvent());
  }

  void _navigateToJoinGroup() {
    Navigator.of(context).pushNamed('/join-group');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.myGroup ?? 'My Group',
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocConsumer<AdminGroupBloc, AdminGroupState>(
        listener: (context, state) {
          if (state is AdminGroupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          // Loading state
          if (state is AdminGroupLoading && state.userGroupInfo == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state (initial load)
          if (state is AdminGroupError && state.userGroupInfo == null) {
            return _buildErrorState(context, state.errorMessage ?? 'An error occurred');
          }

          // Check if user has group info
          final groupInfo = state.userGroupInfo;

          if (groupInfo == null) {
            return _buildNotInGroupState(context);
          }

          // User is in a group - show group information
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Group code display
                  GroupCodeDisplay(
                    groupCode: groupInfo.groupCode,
                    onCopy: () {
                      context.read<AdminGroupBloc>().add(
                            CopyGroupCodeEvent(groupCode: groupInfo.groupCode),
                          );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Group information card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group name
                          _buildInfoRow(
                            context,
                            icon: Icons.group,
                            label: l10n?.groupName ??
                                'Group Name',
                            value: groupInfo.groupName ?? 'N/A',
                          ),
                          const Divider(height: 24),

                          // Admin name
                          _buildInfoRow(
                            context,
                            icon: Icons.person,
                            label: l10n?.adminContact ??
                                'Admin',
                            value: groupInfo.adminName,
                          ),
                          const SizedBox(height: 12),

                          // Admin email
                          _buildInfoRow(
                            context,
                            icon: Icons.email,
                            label: l10n?.email ?? 'Email',
                            value: groupInfo.adminEmail,
                          ),
                          const Divider(height: 24),

                          // Member count
                          _buildInfoRow(
                            context,
                            icon: Icons.people,
                            label: l10n?.membersCount ??
                                'Members',
                            value: '${groupInfo.membersCount}',
                          ),
                          const SizedBox(height: 12),

                          // Join date
                          _buildInfoRow(
                            context,
                            icon: Icons.calendar_today,
                            label: l10n?.joinedAt ??
                                'Joined',
                            value: '${groupInfo.joinedAt.year}-${groupInfo.joinedAt.month.toString().padLeft(2, '0')}-${groupInfo.joinedAt.day.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Help text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n?.contactAdminToLeave ??
                                'Contact your admin to leave the group',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildNotInGroupState(BuildContext context) {
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
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.notInGroup ??
                  'You are not in a group',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.notInGroupDesc ??
                  'Join a group using a code provided by your admin to access shared financial data.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToJoinGroup,
              icon: const Icon(Icons.group_add),
              label: Text(
                l10n?.joinGroup ?? 'Join Group',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
