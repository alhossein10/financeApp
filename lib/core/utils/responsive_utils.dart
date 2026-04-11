import 'package:flutter/material.dart';

/// Responsive design utilities for adapting layouts to different screen sizes
/// 
/// Requirements: 31.1, 31.2, 31.3, 31.4, 31.5, 31.6, 31.7, 31.8
class ResponsiveUtils {
  ResponsiveUtils._();

  // Screen size breakpoints (in dp)
  static const double smallPhoneMaxWidth = 360;
  static const double standardPhoneMaxWidth = 600;
  static const double largePhoneMaxWidth = 840;
  // Tablets are > 840dp

  /// Get the current screen breakpoint
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < smallPhoneMaxWidth) {
      return ScreenSize.smallPhone;
    } else if (width < standardPhoneMaxWidth) {
      return ScreenSize.standardPhone;
    } else if (width < largePhoneMaxWidth) {
      return ScreenSize.largePhone;
    } else {
      return ScreenSize.tablet;
    }
  }

  /// Check if the device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return const EdgeInsets.all(8);
      case ScreenSize.standardPhone:
        return const EdgeInsets.all(12);
      case ScreenSize.largePhone:
        return const EdgeInsets.all(16);
      case ScreenSize.tablet:
        return const EdgeInsets.all(24);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return const EdgeInsets.symmetric(horizontal: 8);
      case ScreenSize.standardPhone:
        return const EdgeInsets.symmetric(horizontal: 12);
      case ScreenSize.largePhone:
        return const EdgeInsets.symmetric(horizontal: 16);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 24);
    }
  }

  /// Get responsive vertical padding
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return const EdgeInsets.symmetric(vertical: 8);
      case ScreenSize.standardPhone:
        return const EdgeInsets.symmetric(vertical: 12);
      case ScreenSize.largePhone:
        return const EdgeInsets.symmetric(vertical: 16);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(vertical: 24);
    }
  }

  /// Get responsive spacing value
  static double getResponsiveSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 8;
      case ScreenSize.standardPhone:
        return 12;
      case ScreenSize.largePhone:
        return 16;
      case ScreenSize.tablet:
        return 24;
    }
  }

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 0.9;
      case ScreenSize.standardPhone:
        return 1.0;
      case ScreenSize.largePhone:
        return 1.1;
      case ScreenSize.tablet:
        return 1.2;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 20;
      case ScreenSize.standardPhone:
        return 24;
      case ScreenSize.largePhone:
        return 28;
      case ScreenSize.tablet:
        return 32;
    }
  }

  /// Get responsive card elevation
  static double getResponsiveCardElevation(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 1;
      case ScreenSize.standardPhone:
        return 2;
      case ScreenSize.largePhone:
        return 3;
      case ScreenSize.tablet:
        return 4;
    }
  }

  /// Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 8;
      case ScreenSize.standardPhone:
        return 12;
      case ScreenSize.largePhone:
        return 16;
      case ScreenSize.tablet:
        return 20;
    }
  }

  /// Get responsive grid cross axis count
  static int getResponsiveGridCrossAxisCount(BuildContext context) {
    final screenSize = getScreenSize(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return isLandscape ? 2 : 1;
      case ScreenSize.standardPhone:
        return isLandscape ? 3 : 2;
      case ScreenSize.largePhone:
        return isLandscape ? 4 : 3;
      case ScreenSize.tablet:
        return isLandscape ? 5 : 4;
    }
  }

  /// Get responsive list tile height
  static double getResponsiveListTileHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 60;
      case ScreenSize.standardPhone:
        return 72;
      case ScreenSize.largePhone:
        return 80;
      case ScreenSize.tablet:
        return 88;
    }
  }

  /// Get responsive dialog width
  static double getResponsiveDialogWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return screenWidth * 0.95;
      case ScreenSize.standardPhone:
        return screenWidth * 0.9;
      case ScreenSize.largePhone:
        return screenWidth * 0.8;
      case ScreenSize.tablet:
        return 600;
    }
  }

  /// Get responsive max content width for tablets
  static double getResponsiveMaxContentWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    if (screenSize == ScreenSize.tablet) {
      return 1200;
    }
    return double.infinity;
  }

  /// Get responsive column count for forms
  static int getResponsiveFormColumns(BuildContext context) {
    final screenSize = getScreenSize(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 1;
      case ScreenSize.standardPhone:
        return isLandscape ? 2 : 1;
      case ScreenSize.largePhone:
        return isLandscape ? 2 : 1;
      case ScreenSize.tablet:
        return 2;
    }
  }

  /// Get responsive button width
  static double getResponsiveButtonWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return screenWidth - 32;
      case ScreenSize.standardPhone:
        return screenWidth - 48;
      case ScreenSize.largePhone:
        return screenWidth - 64;
      case ScreenSize.tablet:
        return 400;
    }
  }

  /// Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 56;
      case ScreenSize.standardPhone:
        return 56;
      case ScreenSize.largePhone:
        return 64;
      case ScreenSize.tablet:
        return 72;
    }
  }

  /// Get responsive bottom navigation bar height
  static double getResponsiveBottomNavHeight(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 56;
      case ScreenSize.standardPhone:
        return 64;
      case ScreenSize.largePhone:
        return 72;
      case ScreenSize.tablet:
        return 80;
    }
  }

  /// Check if should use side navigation (for tablets in landscape)
  static bool shouldUseSideNavigation(BuildContext context) {
    final screenSize = getScreenSize(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    
    return screenSize == ScreenSize.tablet && isLandscape;
  }

  /// Get responsive image size
  static double getResponsiveImageSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 80;
      case ScreenSize.standardPhone:
        return 100;
      case ScreenSize.largePhone:
        return 120;
      case ScreenSize.tablet:
        return 150;
    }
  }

  /// Get responsive avatar size
  static double getResponsiveAvatarSize(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.smallPhone:
        return 40;
      case ScreenSize.standardPhone:
        return 48;
      case ScreenSize.largePhone:
        return 56;
      case ScreenSize.tablet:
        return 64;
    }
  }
}

/// Screen size categories
enum ScreenSize {
  smallPhone,    // < 360dp
  standardPhone, // 360-600dp
  largePhone,    // 600-840dp
  tablet,        // > 840dp
}

/// Extension on BuildContext for easier access to responsive utilities
extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);
  bool get isPortrait => ResponsiveUtils.isPortrait(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);
  EdgeInsets get responsiveHorizontalPadding => ResponsiveUtils.getResponsiveHorizontalPadding(this);
  EdgeInsets get responsiveVerticalPadding => ResponsiveUtils.getResponsiveVerticalPadding(this);
  double get responsiveSpacing => ResponsiveUtils.getResponsiveSpacing(this);
  double get fontSizeMultiplier => ResponsiveUtils.getFontSizeMultiplier(this);
  double get responsiveIconSize => ResponsiveUtils.getResponsiveIconSize(this);
  double get responsiveCardElevation => ResponsiveUtils.getResponsiveCardElevation(this);
  double get responsiveBorderRadius => ResponsiveUtils.getResponsiveBorderRadius(this);
  int get responsiveGridCrossAxisCount => ResponsiveUtils.getResponsiveGridCrossAxisCount(this);
  double get responsiveListTileHeight => ResponsiveUtils.getResponsiveListTileHeight(this);
  double get responsiveDialogWidth => ResponsiveUtils.getResponsiveDialogWidth(this);
  double get responsiveMaxContentWidth => ResponsiveUtils.getResponsiveMaxContentWidth(this);
  int get responsiveFormColumns => ResponsiveUtils.getResponsiveFormColumns(this);
  double get responsiveButtonWidth => ResponsiveUtils.getResponsiveButtonWidth(this);
  double get responsiveAppBarHeight => ResponsiveUtils.getResponsiveAppBarHeight(this);
  double get responsiveBottomNavHeight => ResponsiveUtils.getResponsiveBottomNavHeight(this);
  bool get shouldUseSideNavigation => ResponsiveUtils.shouldUseSideNavigation(this);
  double get responsiveImageSize => ResponsiveUtils.getResponsiveImageSize(this);
  double get responsiveAvatarSize => ResponsiveUtils.getResponsiveAvatarSize(this);
}
