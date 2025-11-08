import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_group_bloc.dart';
import '../bloc/admin_group_event.dart';
import '../bloc/admin_group_state.dart';
import '../widgets/join_group_form.dart';

/// Join SuperAdmin Group Page for Admin Users
/// 
/// This page allows admin users to:
/// - Enter a 6-character SuperAdmin group code
/// - Join a SuperAdmin's group
/// - See validation errors
/// 
/// Note: This is separate from the admin's own group (adminGroupId).
/// An admin can manage their own group with users AND be part of a SuperAdmin group.
class JoinSuperAdminGroupPage extends StatefulWidget {
  const JoinSuperAdminGroupPage({super.key});

  @override
  State<JoinSuperAdminGroupPage> createState() => _JoinSuperAdminGroupPageState();
}

class _JoinSuperAdminGroupPageState extends State<JoinSuperAdminGroupPage> {
  void _handleJoinSuperAdminGroup(String groupCode) {
    context.read<AdminGroupBloc>().add(JoinSuperAdminGroupEvent(groupCode: groupCode));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join SuperAdmin Group'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocConsumer<AdminGroupBloc, AdminGroupState>(
        listener: (context, state) {
          if (state is SuperAdminGroupJoined) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Successfully joined the SuperAdmin group'),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // Navigate back to profile page
            Navigator.of(context).pop();
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
                        Icons.supervisor_account,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Join SuperAdmin Group',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'Enter the SuperAdmin group code provided by your SuperAdmin to join their group. This is separate from your own admin group.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Join group form
                  JoinGroupForm(
                    onSubmit: _handleJoinSuperAdminGroup,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                  ),
                  const SizedBox(height: 24),

                  // Additional help text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Important Information',
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
                          'The SuperAdmin group code is 6 characters long',
                        ),
                        const SizedBox(height: 8),
                        _buildHelpItem(
                          context,
                          'Get the code from your SuperAdmin',
                        ),
                        const SizedBox(height: 8),
                        _buildHelpItem(
                          context,
                          'Joining a SuperAdmin group does not affect your own admin group',
                        ),
                        const SizedBox(height: 8),
                        _buildHelpItem(
                          context,
                          'You can manage your own group with users while being part of a SuperAdmin group',
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

