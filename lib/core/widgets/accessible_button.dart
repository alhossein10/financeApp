import 'package:flutter/material.dart';
import '../utils/accessibility_utils.dart';

/// Accessible button widget with proper touch targets, semantic labels, and haptic feedback
/// 
/// Requirements: 34.1, 34.2, 34.6, 34.7
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final ButtonType type;
  final String? semanticLabel;
  final String? tooltip;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = ButtonType.filled,
    this.semanticLabel,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSemanticLabel = semanticLabel ??
        AccessibilityUtils.buttonSemanticLabel(
          label: label,
          isEnabled: onPressed != null && !isLoading,
          isLoading: isLoading,
        );

    Widget button;

    switch (type) {
      case ButtonType.filled:
        button = _buildFilledButton(context);
        break;
      case ButtonType.outlined:
        button = _buildOutlinedButton(context);
        break;
      case ButtonType.text:
        button = _buildTextButton(context);
        break;
      case ButtonType.elevated:
        button = _buildElevatedButton(context);
        break;
    }

    // Ensure minimum touch target size
    button = AccessibilityUtils.ensureMinTouchTarget(child: button);

    // Add semantic label
    button = Semantics(
      label: effectiveSemanticLabel,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: ExcludeSemantics(child: button),
    );

    // Add tooltip if provided
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }

  Widget _buildFilledButton(BuildContext context) {
    if (icon != null) {
      return FilledButton.icon(
        onPressed: _handlePress,
        icon: isLoading ? _buildLoadingIndicator() : icon!,
        label: Text(label),
      );
    }
    return FilledButton(
      onPressed: _handlePress,
      child: isLoading
          ? _buildLoadingIndicator()
          : Text(label),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: _handlePress,
        icon: isLoading ? _buildLoadingIndicator() : icon!,
        label: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: _handlePress,
      child: isLoading
          ? _buildLoadingIndicator()
          : Text(label),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    if (icon != null) {
      return TextButton.icon(
        onPressed: _handlePress,
        icon: isLoading ? _buildLoadingIndicator() : icon!,
        label: Text(label),
      );
    }
    return TextButton(
      onPressed: _handlePress,
      child: isLoading
          ? _buildLoadingIndicator()
          : Text(label),
    );
  }

  Widget _buildElevatedButton(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: _handlePress,
        icon: isLoading ? _buildLoadingIndicator() : icon!,
        label: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: _handlePress,
      child: isLoading
          ? _buildLoadingIndicator()
          : Text(label),
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  void _handlePress() {
    if (onPressed != null && !isLoading) {
      AccessibilityUtils.buttonTapFeedback();
      onPressed!();
    }
  }
}

/// Button type enum
enum ButtonType {
  filled,
  outlined,
  text,
  elevated,
}

/// Accessible icon button with proper touch targets and semantic labels
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;
  final double size;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      icon: Icon(icon, size: size),
      onPressed: _handlePress,
      color: color,
      tooltip: tooltip ?? semanticLabel,
      // Ensure minimum touch target
      constraints: const BoxConstraints(
        minWidth: AccessibilityUtils.minTouchTargetSize,
        minHeight: AccessibilityUtils.minTouchTargetSize,
      ),
    );

    // Add semantic label
    button = Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: ExcludeSemantics(child: button),
    );

    return button;
  }

  void _handlePress() {
    if (onPressed != null) {
      AccessibilityUtils.buttonTapFeedback();
      onPressed!();
    }
  }
}

/// Accessible floating action button
class AccessibleFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final bool isExtended;
  final String? extendedLabel;

  const AccessibleFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.isExtended = false,
    this.extendedLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget fab;

    if (isExtended && extendedLabel != null) {
      fab = FloatingActionButton.extended(
        onPressed: _handlePress,
        icon: Icon(icon),
        label: Text(extendedLabel!),
        tooltip: tooltip ?? semanticLabel,
      );
    } else {
      fab = FloatingActionButton(
        onPressed: _handlePress,
        tooltip: tooltip ?? semanticLabel,
        child: Icon(icon),
      );
    }

    // Add semantic label
    fab = Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: ExcludeSemantics(child: fab),
    );

    return fab;
  }

  void _handlePress() {
    if (onPressed != null) {
      AccessibilityUtils.buttonTapFeedback();
      onPressed!();
    }
  }
}
