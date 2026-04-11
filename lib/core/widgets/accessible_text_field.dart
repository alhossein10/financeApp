import 'package:flutter/material.dart';
import '../utils/accessibility_utils.dart';

/// Accessible text field with proper semantic labels and validation
/// 
/// Requirements: 34.1, 34.2, 34.4, 34.7
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? semanticLabel;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final String? errorText;

  const AccessibleTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.semanticLabel,
    this.isRequired = false,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = semanticLabel ??
        AccessibilityUtils.formFieldSemanticLabel(
          label: label,
          isRequired: isRequired,
          hint: hint,
          error: errorText,
        );

    return Semantics(
      label: effectiveSemanticLabel,
      textField: true,
      enabled: enabled,
      child: ExcludeSemantics(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
            border: const OutlineInputBorder(),
            // Ensure sufficient padding for touch targets
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          enabled: enabled,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          validator: validator,
          // Ensure text scales properly
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// Accessible dropdown field
class AccessibleDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String label;
  final String? hint;
  final String? semanticLabel;
  final bool isRequired;
  final Widget? prefixIcon;
  final bool enabled;
  final String? Function(T?)? validator;

  const AccessibleDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.hint,
    this.semanticLabel,
    this.isRequired = false,
    this.prefixIcon,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = semanticLabel ??
        AccessibilityUtils.formFieldSemanticLabel(
          label: label,
          isRequired: isRequired,
          hint: hint,
        );

    return Semantics(
      label: effectiveSemanticLabel,
      button: true,
      enabled: enabled,
      child: ExcludeSemantics(
        child: DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? _handleChange : null,
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            hintText: hint,
            prefixIcon: prefixIcon,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: validator,
          // Ensure text scales properly
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  void _handleChange(T? newValue) {
    if (onChanged != null) {
      AccessibilityUtils.selectionFeedback();
      onChanged!(newValue);
    }
  }
}

/// Accessible checkbox with proper touch targets
class AccessibleCheckbox extends StatelessWidget {
  final bool value;
  final void Function(bool?)? onChanged;
  final String label;
  final String? semanticLabel;

  const AccessibleCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = semanticLabel ??
        '$label, checkbox, ${value ? 'checked' : 'unchecked'}';

    return Semantics(
      label: effectiveSemanticLabel,
      checked: value,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onChanged != null ? () => _handleChange(!value) : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: AccessibilityUtils.minTouchTargetSize,
                  height: AccessibilityUtils.minTouchTargetSize,
                  child: Checkbox(
                    value: value,
                    onChanged: _handleChange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleChange(bool? newValue) {
    if (onChanged != null && newValue != null) {
      AccessibilityUtils.selectionFeedback();
      onChanged!(newValue);
    }
  }
}

/// Accessible radio button with proper touch targets
class AccessibleRadio<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final void Function(T?)? onChanged;
  final String label;
  final String? semanticLabel;

  const AccessibleRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final effectiveSemanticLabel = semanticLabel ??
        '$label, radio button, ${isSelected ? 'selected' : 'not selected'}';

    return Semantics(
      label: effectiveSemanticLabel,
      selected: isSelected,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onChanged != null ? () => _handleChange(value) : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: AccessibilityUtils.minTouchTargetSize,
                  height: AccessibilityUtils.minTouchTargetSize,
                  child: Radio<T>(
                    value: value,
                    groupValue: groupValue,
                    onChanged: _handleChange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleChange(T? newValue) {
    if (onChanged != null && newValue != null) {
      AccessibilityUtils.selectionFeedback();
      onChanged!(newValue);
    }
  }
}

/// Accessible switch with proper touch targets
class AccessibleSwitch extends StatelessWidget {
  final bool value;
  final void Function(bool)? onChanged;
  final String label;
  final String? semanticLabel;

  const AccessibleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = semanticLabel ??
        '$label, switch, ${value ? 'on' : 'off'}';

    return Semantics(
      label: effectiveSemanticLabel,
      toggled: value,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onChanged != null ? () => _handleChange(!value) : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                SizedBox(
                  width: AccessibilityUtils.minTouchTargetSize,
                  height: AccessibilityUtils.minTouchTargetSize,
                  child: Switch(
                    value: value,
                    onChanged: _handleChange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleChange(bool newValue) {
    if (onChanged != null) {
      AccessibilityUtils.selectionFeedback();
      onChanged!(newValue);
    }
  }
}
