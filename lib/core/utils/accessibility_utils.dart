import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Utility class for accessibility features
/// Provides semantic labels, haptic feedback, and accessibility helpers
/// 
/// Requirements: 34.1, 34.2, 34.3, 34.4, 34.5, 34.6, 34.7, 34.8
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Minimum touch target size in logical pixels (48dp)
  static const double minTouchTargetSize = 48.0;

  /// Minimum contrast ratio for normal text (4.5:1)
  static const double minContrastRatio = 4.5;

  /// Minimum contrast ratio for large text (3:1)
  static const double minLargeTextContrastRatio = 3.0;

  /// Maximum text scaling factor supported
  static const double maxTextScaleFactor = 2.0;

  /// Provide haptic feedback for button taps
  static Future<void> buttonTapFeedback() async {
    await HapticFeedback.lightImpact();
  }

  /// Provide haptic feedback for important actions (delete, submit)
  static Future<void> importantActionFeedback() async {
    await HapticFeedback.mediumImpact();
  }

  /// Provide haptic feedback for errors
  static Future<void> errorFeedback() async {
    await HapticFeedback.vibrate();
  }

  /// Provide haptic feedback for success
  static Future<void> successFeedback() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Provide haptic feedback for selection changes
  static Future<void> selectionFeedback() async {
    await HapticFeedback.selectionClick();
  }

  /// Calculate contrast ratio between two colors
  /// Returns a value between 1 and 21
  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = _calculateRelativeLuminance(foreground);
    final bgLuminance = _calculateRelativeLuminance(background);

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _calculateRelativeLuminance(Color color) {
    final r = _linearizeColorComponent(color.red / 255.0);
    final g = _linearizeColorComponent(color.green / 255.0);
    final b = _linearizeColorComponent(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize a color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Check if contrast ratio meets WCAG AA standards
  static bool meetsContrastRequirement(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    final requiredRatio =
        isLargeText ? minLargeTextContrastRatio : minContrastRatio;
    return ratio >= requiredRatio;
  }

  /// Wrap a widget with minimum touch target size
  static Widget ensureMinTouchTarget({
    required Widget child,
    double minSize = minTouchTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }

  /// Create semantic label for currency amount
  static String currencySemanticLabel(
    double amount,
    String currency, {
    required String locale,
  }) {
    final formattedAmount = amount.toStringAsFixed(2);
    switch (currency) {
      case 'USD':
        return '$formattedAmount US dollars';
      case 'SYP':
        return '$formattedAmount Syrian pounds';
      case 'TRY':
        return '$formattedAmount Turkish lira';
      default:
        return '$formattedAmount $currency';
    }
  }

  /// Create semantic label for date
  static String dateSemanticLabel(DateTime date, {required String locale}) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Create semantic label for navigation destination
  static String navigationSemanticLabel(
    String label,
    int index,
    int total,
    bool isSelected,
  ) {
    final position = 'Tab ${index + 1} of $total';
    final state = isSelected ? 'selected' : 'not selected';
    return '$label, $position, $state';
  }

  /// Create semantic label for loading state
  static String loadingSemanticLabel(String context) {
    return 'Loading $context, please wait';
  }

  /// Create semantic label for error state
  static String errorSemanticLabel(String error) {
    return 'Error: $error';
  }

  /// Create semantic label for success state
  static String successSemanticLabel(String message) {
    return 'Success: $message';
  }

  /// Create semantic label for form field
  static String formFieldSemanticLabel({
    required String label,
    required bool isRequired,
    String? hint,
    String? error,
  }) {
    final parts = <String>[label];

    if (isRequired) {
      parts.add('required');
    }

    if (hint != null && hint.isNotEmpty) {
      parts.add(hint);
    }

    if (error != null && error.isNotEmpty) {
      parts.add('Error: $error');
    }

    return parts.join(', ');
  }

  /// Create semantic label for button
  static String buttonSemanticLabel({
    required String label,
    bool isEnabled = true,
    bool isLoading = false,
  }) {
    if (isLoading) {
      return '$label, loading';
    }
    if (!isEnabled) {
      return '$label, disabled';
    }
    return '$label, button';
  }

  /// Create semantic label for image
  static String imageSemanticLabel({
    required String description,
    bool isLoading = false,
    bool hasError = false,
  }) {
    if (isLoading) {
      return 'Loading image: $description';
    }
    if (hasError) {
      return 'Failed to load image: $description';
    }
    return 'Image: $description';
  }

  /// Create semantic label for list item
  static String listItemSemanticLabel({
    required String title,
    String? subtitle,
    int? index,
    int? total,
  }) {
    final parts = <String>[title];

    if (subtitle != null && subtitle.isNotEmpty) {
      parts.add(subtitle);
    }

    if (index != null && total != null) {
      parts.add('Item ${index + 1} of $total');
    }

    return parts.join(', ');
  }

  /// Announce message to screen reader
  static Future<void> announce(BuildContext context, String message) async {
    // Use SemanticsService from semantics package
    final textDirection = Directionality.of(context);
    await SemanticsService.announce(message, textDirection);
  }

  /// Announce message with delay (useful for state changes)
  static Future<void> announceDelayed(
    BuildContext context,
    String message, {
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    await Future.delayed(delay);
    await announce(context, message);
  }
}
