import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

/// Dialog for confirming account deletion
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _confirmationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileAccountDeleted) {
          // Clear all data and logout
          context.read<AuthBloc>().add(const AuthLogoutRequested());
          
          Navigator.of(context).popUntil((route) => route.isFirst);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProfileError) {
          setState(() {
            _isDeleting = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ProfileLoading) {
          setState(() {
            _isDeleting = true;
          });
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Delete Account'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone!',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deleting your account will:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Permanently delete all your data'),
              const Text('• Remove you from any groups'),
              const Text('• Delete all your expenses and transfers'),
              const Text('• Cannot be recovered'),
              const SizedBox(height: 24),
              const Text(
                'Type "DELETE" to confirm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmationController,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please type DELETE to confirm';
                  }
                  if (value != 'DELETE') {
                    return 'Please type DELETE exactly as shown';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isDeleting ? null : _deleteAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<ProfileBloc>().add(const ProfileDeleteAccountRequested());
  }
}
