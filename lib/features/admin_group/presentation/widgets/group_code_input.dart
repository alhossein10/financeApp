import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';

/// Widget for inputting a 6-character group code with real-time validation
class GroupCodeInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final bool autofocus;

  const GroupCodeInput({
    Key? key,
    this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<GroupCodeInput> createState() => _GroupCodeInputState();
}

class _GroupCodeInputState extends State<GroupCodeInput> {
  late TextEditingController _controller;
  String? _validationError;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    
    // Only validate after user has started typing
    if (_hasInteracted || text.isNotEmpty) {
      setState(() {
        _hasInteracted = true;
        _validationError = _validateGroupCode(text);
      });
    }

    widget.onChanged?.call(text);
  }

  String? _validateGroupCode(String code) {
    if (code.isEmpty) {
      return null; // Don't show error for empty field until submission
    }

    // Check length
    if (code.length < 6) {
      return AppLocalizations.of(context).translate('admin_group.code_too_short') ??
          'Code must be 6 characters';
    }

    if (code.length > 6) {
      return AppLocalizations.of(context).translate('admin_group.code_too_long') ??
          'Code must be exactly 6 characters';
    }

    // Check if alphanumeric
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumericRegex.hasMatch(code)) {
      return AppLocalizations.of(context).translate('admin_group.code_invalid_chars') ??
          'Code must contain only letters and numbers';
    }

    return null;
  }

  bool isValid() {
    final code = _controller.text;
    return code.length == 6 && _validateGroupCode(code) == null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayError = widget.errorText ?? _validationError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          AppLocalizations.of(context).translate('admin_group.group_code') ?? 'Group Code',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Input field
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          style: theme.textTheme.headlineSmall?.copyWith(
            letterSpacing: 8,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'ABC123',
            hintStyle: theme.textTheme.headlineSmall?.copyWith(
              letterSpacing: 8,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            counterText: '', // Hide character counter
            errorText: displayError,
            errorMaxLines: 2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: widget.enabled
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceVariant.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: widget.enabled
                        ? () {
                            _controller.clear();
                            setState(() {
                              _hasInteracted = false;
                              _validationError = null;
                            });
                          }
                        : null,
                  )
                : null,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            UpperCaseTextFormatter(),
          ],
          onSubmitted: (_) {
            if (isValid() && widget.onSubmitted != null) {
              widget.onSubmitted!();
            }
          },
        ),

        // Helper text
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppLocalizations.of(context).translate('admin_group.get_from_admin') ??
                    'Get this code from your admin',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),

        // Format requirements
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).translate('admin_group.code_requirements') ??
                    'Code Requirements:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              _buildRequirement(
                context,
                'Exactly 6 characters',
                _controller.text.length == 6,
              ),
              _buildRequirement(
                context,
                'Letters and numbers only',
                _controller.text.isEmpty ||
                    RegExp(r'^[a-zA-Z0-9]+$').hasMatch(_controller.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirement(BuildContext context, String text, bool isMet) {
    final theme = Theme.of(context);
    final color = _controller.text.isEmpty
        ? theme.colorScheme.onSurface.withOpacity(0.6)
        : isMet
            ? Colors.green
            : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet && _controller.text.isNotEmpty
                ? Icons.check_circle
                : Icons.circle_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Text formatter to convert input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
