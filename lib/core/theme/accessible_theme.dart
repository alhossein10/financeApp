import 'package:flutter/material.dart';
import '../utils/accessibility_utils.dart';

/// Accessible theme configuration with proper contrast ratios
/// 
/// Requirements: 34.3, 34.4
class AccessibleTheme {
  AccessibleTheme._();

  /// Light theme with accessible colors
  static ThemeData lightTheme() {
    // Define colors with proper contrast ratios
    const primaryColor = Color(0xFF1976D2); // Blue
    const secondaryColor = Color(0xFFF57C00); // Orange
    const tertiaryColor = Color(0xFF388E3C); // Green
    const errorColor = Color(0xFFD32F2F); // Red
    const backgroundColor = Color(0xFFFFFFFF); // White
    const surfaceColor = Color(0xFFFAFAFA); // Light grey
    const onPrimaryColor = Color(0xFFFFFFFF); // White
    const onSecondaryColor = Color(0xFFFFFFFF); // White
    const onBackgroundColor = Color(0xFF212121); // Dark grey
    const onSurfaceColor = Color(0xFF212121); // Dark grey
    const onErrorColor = Color(0xFFFFFFFF); // White

    // Verify contrast ratios
    assert(
      AccessibilityUtils.calculateContrastRatio(onBackgroundColor, backgroundColor) >= 
        AccessibilityUtils.minContrastRatio,
      'Text on background does not meet contrast requirements',
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: surfaceColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSecondaryColor,
        onBackground: onBackgroundColor,
        onSurface: onSurfaceColor,
        onError: onErrorColor,
      ),
      
      // Text theme with scalable fonts
      textTheme: _buildTextTheme(onBackgroundColor),
      
      // Button themes with minimum touch targets
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      filledButtonTheme: _buildFilledButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      iconButtonTheme: _buildIconButtonTheme(),
      
      // Input decoration theme
      inputDecorationTheme: _buildInputDecorationTheme(),
      
      // Card theme
      cardTheme: _buildCardTheme(),
      
      // App bar theme
      appBarTheme: _buildAppBarTheme(primaryColor, onPrimaryColor),
      
      // Bottom navigation bar theme
      navigationBarTheme: _buildNavigationBarTheme(),
      
      // Floating action button theme
      floatingActionButtonTheme: _buildFABTheme(),
      
      // Ensure minimum touch targets
      materialTapTargetSize: MaterialTapTargetSize.padded,
      
      // Visual density for better spacing
      visualDensity: VisualDensity.standard,
    );
  }

  /// Dark theme with accessible colors
  static ThemeData darkTheme() {
    // Define colors with proper contrast ratios for dark mode
    const primaryColor = Color(0xFF90CAF9); // Light blue
    const secondaryColor = Color(0xFFFFB74D); // Light orange
    const tertiaryColor = Color(0xFF81C784); // Light green
    const errorColor = Color(0xFFEF5350); // Light red
    const backgroundColor = Color(0xFF121212); // Dark grey
    const surfaceColor = Color(0xFF1E1E1E); // Slightly lighter grey
    const onPrimaryColor = Color(0xFF000000); // Black
    const onSecondaryColor = Color(0xFF000000); // Black
    const onBackgroundColor = Color(0xFFE0E0E0); // Light grey
    const onSurfaceColor = Color(0xFFE0E0E0); // Light grey
    const onErrorColor = Color(0xFF000000); // Black

    // Verify contrast ratios
    assert(
      AccessibilityUtils.calculateContrastRatio(onBackgroundColor, backgroundColor) >= 
        AccessibilityUtils.minContrastRatio,
      'Text on background does not meet contrast requirements',
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: surfaceColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSecondaryColor,
        onBackground: onBackgroundColor,
        onSurface: onSurfaceColor,
        onError: onErrorColor,
      ),
      
      // Text theme with scalable fonts
      textTheme: _buildTextTheme(onBackgroundColor),
      
      // Button themes with minimum touch targets
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      filledButtonTheme: _buildFilledButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      iconButtonTheme: _buildIconButtonTheme(),
      
      // Input decoration theme
      inputDecorationTheme: _buildInputDecorationTheme(),
      
      // Card theme
      cardTheme: _buildCardTheme(),
      
      // App bar theme
      appBarTheme: _buildAppBarTheme(surfaceColor, onSurfaceColor),
      
      // Bottom navigation bar theme
      navigationBarTheme: _buildNavigationBarTheme(),
      
      // Floating action button theme
      floatingActionButtonTheme: _buildFABTheme(),
      
      // Ensure minimum touch targets
      materialTapTargetSize: MaterialTapTargetSize.padded,
      
      // Visual density for better spacing
      visualDensity: VisualDensity.standard,
    );
  }

  /// Build text theme with scalable fonts
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.50,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.50,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
        height: 1.45,
      ),
    );
  }

  /// Build elevated button theme with minimum touch targets
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(
          AccessibilityUtils.minTouchTargetSize,
          AccessibilityUtils.minTouchTargetSize,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Build filled button theme with minimum touch targets
  static FilledButtonThemeData _buildFilledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(
          AccessibilityUtils.minTouchTargetSize,
          AccessibilityUtils.minTouchTargetSize,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Build outlined button theme with minimum touch targets
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(
          AccessibilityUtils.minTouchTargetSize,
          AccessibilityUtils.minTouchTargetSize,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Build text button theme with minimum touch targets
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(
          AccessibilityUtils.minTouchTargetSize,
          AccessibilityUtils.minTouchTargetSize,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Build icon button theme with minimum touch targets
  static IconButtonThemeData _buildIconButtonTheme() {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(
          AccessibilityUtils.minTouchTargetSize,
          AccessibilityUtils.minTouchTargetSize,
        ),
      ),
    );
  }

  /// Build input decoration theme
  static InputDecorationTheme _buildInputDecorationTheme() {
    return const InputDecorationTheme(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(),
    );
  }

  /// Build card theme
  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(8),
    );
  }

  /// Build app bar theme
  static AppBarTheme _buildAppBarTheme(Color backgroundColor, Color foregroundColor) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: foregroundColor,
      ),
    );
  }

  /// Build navigation bar theme
  static NavigationBarThemeData _buildNavigationBarTheme() {
    return const NavigationBarThemeData(
      height: 80,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }

  /// Build floating action button theme
  static FloatingActionButtonThemeData _buildFABTheme() {
    return const FloatingActionButtonThemeData(
      shape: CircleBorder(),
    );
  }
}
