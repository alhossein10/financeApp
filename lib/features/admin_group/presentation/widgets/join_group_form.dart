import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'group_code_input.dart';

/// Widget for joining a group using a group code
class JoinGroupForm extends StatefulWidget {
  final Function(String groupCode) onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const JoinGroupForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<JoinGroupForm> createState() => _JoinGroupFormState();
}

class _JoinGroupFormState extends State<JoinGroupForm> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isCodeValid = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_isCodeValid) {
      setState(() {
        // Trigger validation display
      });
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final code = _codeController.text.trim().toUpperCase();
      widget.onSubmit(code);
    }
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)?.codeRequired ??
          'Group code is required';
    }

    if (value.length != 6) {
      return AppLocalizations.of(context)?.codeMustBe6 ??
          'Code must be exactly 6 characters';
    }

    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumericRegex.hasMatch(value)) {
      return AppLocalizations.of(context)?.codeInvalidChars ??
          'Code must contain only letters and numbers';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions
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
                    AppLocalizations.of(context)?.joinInstructions ??
                        'Enter the 6-character group code provided by your admin to join their group.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Group code input
          GroupCodeInput(
            controller: _codeController,
            enabled: !widget.isLoading,
            autofocus: true,
            errorText: widget.errorMessage,
            onChanged: (value) {
              setState(() {
                _isCodeValid = _validateCode(value) == null;
              });
            },
            onSubmitted: _handleSubmit,
          ),
          const SizedBox(height: 24),

          // Error message (if any from parent)
          if (widget.errorMessage != null && widget.errorMessage!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit button
          ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
              disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_add),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)?.joinGroup ??
                            'Join Group',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),

          // Help text
          const SizedBox(height: 16),
          Center(
            child: Text(
              AppLocalizations.of(context)?.joinHelp ??
                  'Don\'t have a code? Contact your admin.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
