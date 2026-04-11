import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/flavor_config.dart';
import '../utils/accessibility_utils.dart';
import '../../l10n/app_localizations.dart';

/// Flavor-specific navigation bar widget
/// 
/// This widget provides a bottom navigation bar that adapts to the current
/// app flavor (SuperAdmin, Admin, or User). Each flavor has its own set of
/// navigation destinations with appropriate icons and labels.
/// 
/// Navigation Destinations by Flavor:
/// 
/// **SuperAdmin:**
/// - Group Management: Manage admin groups
/// - Cash: View financial box and transfers
/// - Transfers: Manage transfers to admins
/// - Analytics: View global analytics
/// - Profile: User profile (via AppBar action)
/// 
/// **Admin:**
/// - Group Management: Manage user groups
/// - Cash: View financial box
/// - Exchange: Currency exchange
/// - Expenses: Manage expenses
/// - Export: Export data
/// - Profile: User profile (via AppBar action)
/// 
/// **User:**
/// - Home: Financial box and incoming transfers
/// - Exchange: Currency exchange
/// - Expenses: Manage personal expenses
/// - Export: Export personal data
/// - Profile: User profile (via AppBar action)
/// 
/// Usage:
/// ```dart
/// AppNavigationBar(
///   selectedIndex: _currentIndex,
///   onDestinationSelected: (index) {
///     setState(() => _currentIndex = index);
///   },
/// )
/// ```
class AppNavigationBar extends StatelessWidget {
  /// The currently selected navigation destination index
  final int selectedIndex;
  
  /// Callback when a navigation destination is selected
  final ValueChanged<int> onDestinationSelected;
  
  /// Optional flavor configuration override
  /// If not provided, uses FlavorConfig.instance
  final FlavorConfig? flavorConfig;

  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.flavorConfig,
  });

  @override
  Widget build(BuildContext context) {
    final config = flavorConfig ?? FlavorConfig.instance;
    final destinations = _buildNavigationDestinations(context, config);
    
    return Semantics(
      container: true,
      label: 'Navigation bar with ${destinations.length} tabs',
      child: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: destinations,
        onDestinationSelected: (index) {
          // Provide haptic feedback on navigation
          _provideHapticFeedback();
          onDestinationSelected(index);
        },
        // Ensure minimum height for touch targets
        height: 80,
      ),
    );
  }

  /// Provide haptic feedback for navigation changes
  void _provideHapticFeedback() {
    HapticFeedback.selectionClick();
  }

  /// Build navigation destinations based on flavor configuration
  List<NavigationDestination> _buildNavigationDestinations(
    BuildContext context,
    FlavorConfig config,
  ) {
    final l10n = AppLocalizations.of(context);
    final destinations = <NavigationDestination>[];
    
    // Get navigation destinations from flavor config
    final flavorDestinations = config.getNavigationDestinations();
    
    // Convert FlavorNavigationDestination to NavigationDestination
    for (var i = 0; i < flavorDestinations.length; i++) {
      final dest = flavorDestinations[i];
      final label = _getLocalizedLabel(l10n, dest.labelKey);
      final isSelected = i == selectedIndex;
      
      // Create semantic label for navigation destination
      final semanticLabel = AccessibilityUtils.navigationSemanticLabel(
        label,
        i,
        flavorDestinations.length,
        isSelected,
      );
      
      destinations.add(
        NavigationDestination(
          icon: Semantics(
            label: semanticLabel,
            selected: isSelected,
            button: true,
            child: ExcludeSemantics(
              child: Icon(dest.icon),
            ),
          ),
          selectedIcon: Semantics(
            label: semanticLabel,
            selected: true,
            button: true,
            child: ExcludeSemantics(
              child: Icon(dest.selectedIcon),
            ),
          ),
          label: label,
          tooltip: label,
        ),
      );
    }
    
    return destinations;
  }

  /// Get localized label for a navigation destination
  String _getLocalizedLabel(AppLocalizations? l10n, String labelKey) {
    if (l10n == null) return labelKey;
    
    switch (labelKey) {
      case 'cash':
        return l10n.cash;
      case 'cash_inbox':
        return l10n.cash;
      case 'transfers':
        return l10n.transfers;
      case 'expenses':
        return l10n.expenses;
      case 'export':
        return l10n.export;
      case 'profile':
        return l10n.profile;
      case 'convert':
        return l10n.convert;
      case 'analytics':
        return l10n.statistics;
      case 'home':
        return l10n.fundBoxUsd;
      case 'admin_group.group_management':
        return l10n.groupManagement;
      default:
        return labelKey;
    }
  }
}

/// Extension to provide navigation destination information
extension AppNavigationBarExtension on FlavorConfig {
  /// Get the number of navigation destinations for this flavor
  int get navigationDestinationCount => navigationDestinations.length;
  
  /// Get the route for a specific navigation index
  String? getRouteForIndex(int index) {
    if (index < 0 || index >= navigationDestinations.length) {
      return null;
    }
    return navigationDestinations[index].route;
  }
  
  /// Get the label key for a specific navigation index
  String? getLabelKeyForIndex(int index) {
    if (index < 0 || index >= navigationDestinations.length) {
      return null;
    }
    return navigationDestinations[index].labelKey;
  }
  
  /// Find the index for a specific route
  int? getIndexForRoute(String route) {
    for (var i = 0; i < navigationDestinations.length; i++) {
      if (navigationDestinations[i].route == route) {
        return i;
      }
    }
    return null;
  }
}
