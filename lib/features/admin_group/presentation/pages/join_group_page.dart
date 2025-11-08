import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/admin_group_bloc.dart';
import '../bloc/admin_group_event.dart';
import '../bloc/admin_group_state.dart';
import '../widgets/join_group_form.dart';

/// Join Group Page for Regular Users
/// 
/// This page allows regular users to:
/// - Enter a 6-character group code
/// - Join an admin's group
/// - See validation errors
/// - Navigate to group info on success
/// 
/// Requirements: 4.1-4.6
class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({Key? key}) : super(key: key);

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  void _handleJoinGroup(String groupCode) {
    context.read<AdminGroupBloc>().add(JoinGroupEvent(groupCode: groupCode));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.translate('admin_group.join_group') ?? 'Join Group',
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocConsumer<AdminGroupBloc, AdminGroupState>(
        listener: (context, state) {
          if (state is GroupJoined) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.translate('admin_group.joined_group') ??
                      'Successfully joined the group',
                ),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Navigate to group info page
            Navigator.of(context).pushReplacementNamed('/group-info');
          }
        },
        builder: (context, state) {
          final isLoading = state.isLoading;
          final errorMessage = state.errorMessage;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.group_add,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    l10n.translate('admin_group.join_group') ?? 'Join Group',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    l10n.translate('admin_group.join_description') ??
                        'Enter the group code provided by your admin to join their group and access shared financial data.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Join group form
                  JoinGroupForm(
                    onSubmit: _handleJoinGroup,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                  ),
                  const SizedBox(height: 24),

                  // Additional help text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.translate('admin_group.help_title') ?? 'Need Help?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildHelpItem(
                          context,
                          l10n.translate('admin_group.help_1') ??
                              'The group code is 6 characters long',
                        ),
                        const SizedBox(height: 8),
                        _buildHelpItem(
                          context,
                          l10n.translate('admin_group.help_2') ??
                              'Get the code from your admin',
                        ),
                        const SizedBox(height: 8),
                        _buildHelpItem(
                          context,
                          l10n.translate('admin_group.help_3') ??
                              'You can only be in one group at a time',
                        ),
                        const SizedBox(height: 8),
                        _buildHelpItem(
                          context,
                          l10n.translate('admin_group.help_4') ??
                              'Contact your admin if you need to leave a group',
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

  Widget _buildHelpItem(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            Icons.check_circle_outline,
            size: 16,
            color: theme.colorScheme.primary.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
