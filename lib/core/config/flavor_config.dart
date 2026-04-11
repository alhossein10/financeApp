import 'package:flutter/material.dart';

enum AppFlavor {
  superAdmin,
  admin,
  user;

  bool get isSuperAdmin => this == AppFlavor.superAdmin;
  bool get isAdmin => this == AppFlavor.admin;
  bool get isUser => this == AppFlavor.user;
}

/// Navigation destination definition for flavor-specific navigation
class FlavorNavigationDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
  final String route;

  const FlavorNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
    required this.route,
  });
}

class FlavorConfig {
  final AppFlavor flavor;
  final String appName;
  final String applicationId;
  final bool enableCashModule;
  final bool enableCashboxModule;
  final bool enableCurrencyModule;
  final bool enableExpensesModule;
  final bool enableExportModule;
  final bool requiresAdminRole;
  final bool enableAdminDashboard;
  final bool enableFundBox;
  final bool enableAuditLogs;
  final bool enableUserManagement;
  
  // SuperAdmin-specific flags
  final bool enableSuperAdminCashPage;
  final bool enableSuperAdminExpensesPage;
  final bool showIncomingTransfers;
  final bool showExchangeHistory;
  
  // Feature flags for granular control
  final Map<String, bool> featureFlags;
  
  // Navigation destinations for this flavor
  final List<FlavorNavigationDestination> navigationDestinations;

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.applicationId,
    required this.enableCashModule,
    required this.enableCashboxModule,
    required this.enableCurrencyModule,
    required this.enableExpensesModule,
    required this.enableExportModule,
    required this.requiresAdminRole,
    required this.enableAdminDashboard,
    required this.enableFundBox,
    required this.enableAuditLogs,
    required this.enableUserManagement,
    this.enableSuperAdminCashPage = false,
    this.enableSuperAdminExpensesPage = false,
    this.showIncomingTransfers = true,
    this.showExchangeHistory = true,
    this.featureFlags = const {},
    this.navigationDestinations = const [],
  });

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    assert(_instance != null, 'FlavorConfig must be initialized');
    return _instance!;
  }

  static void initialize(AppFlavor flavor) {
    if (flavor == AppFlavor.superAdmin) {
      _instance = const FlavorConfig(
        flavor: AppFlavor.superAdmin,
        appName: 'Finance SuperAdmin',
        applicationId: 'com.app.finance.superadmin',
        enableCashModule: true,
        enableCashboxModule: true,
        enableCurrencyModule: false, // Disabled for SuperAdmin - no exchange page
        enableExpensesModule: true,
        enableExportModule: false, // Disabled for SuperAdmin - no export page
        requiresAdminRole: true,
        enableAdminDashboard: false, // SuperAdmin has different dashboard
        enableFundBox: true, // SuperAdmin can view fund box
        enableAuditLogs: true,
        enableUserManagement: true,
        enableSuperAdminCashPage: true,
        enableSuperAdminExpensesPage: true,
        showIncomingTransfers: false, // SuperAdmin only sees outgoing transfers
        showExchangeHistory: false, // No exchange history for SuperAdmin
        featureFlags: {
          'canCreateExpenses': false, // SuperAdmin cannot create expenses
          'canExchangeCurrency': false, // SuperAdmin cannot exchange currency
          'canExportData': false, // SuperAdmin cannot export data
          'canManageGroup': true, // SuperAdmin can manage admin groups
          'canViewAnalytics': true, // SuperAdmin can view analytics
          'canTransferFunds': true, // SuperAdmin can transfer to admins
          'canViewTransfers': true, // SuperAdmin can view transfers
          'canManageIncoming': true, // SuperAdmin can add incoming amounts
        },
        navigationDestinations: [
          FlavorNavigationDestination(
            icon: Icons.group_outlined,
            selectedIcon: Icons.group,
            labelKey: 'admin_group.group_management',
            route: '/group-management',
          ),
          FlavorNavigationDestination(
            icon: Icons.inbox_outlined,
            selectedIcon: Icons.inbox,
            labelKey: 'cash_inbox',
            route: '/cash',
          ),
          FlavorNavigationDestination(
            icon: Icons.analytics_outlined,
            selectedIcon: Icons.analytics,
            labelKey: 'analytics',
            route: '/analytics',
          ),
        ],
      );
    } else if (flavor == AppFlavor.admin) {
      _instance = const FlavorConfig(
        flavor: AppFlavor.admin,
        appName: 'Finance Admin',
        applicationId: 'com.app.finance.admin',
        enableCashModule: true, // Enabled for admin flavor
        enableCashboxModule: true,
        enableCurrencyModule: true, // Enabled for admin flavor - تصريف page
        enableExpensesModule: true,
        enableExportModule: true,
        requiresAdminRole: true,
        enableAdminDashboard: true,
        enableFundBox: true,
        enableAuditLogs: true,
        enableUserManagement: true,
        enableSuperAdminCashPage: false,
        enableSuperAdminExpensesPage: false,
        showIncomingTransfers: true,
        showExchangeHistory: true,
        featureFlags: {
          'canCreateExpenses': true, // Admin can create expenses
          'canExchangeCurrency': true, // Admin can exchange currency
          'canExportData': true, // Admin can export data
          'canManageGroup': true, // Admin can manage user groups
          'canViewAnalytics': false, // Admin cannot view global analytics
          'canTransferFunds': true, // Admin can transfer to users
          'canViewTransfers': true, // Admin can view transfers
          'canManageIncoming': false, // Admin cannot add incoming amounts
        },
        navigationDestinations: [
          FlavorNavigationDestination(
            icon: Icons.group_outlined,
            selectedIcon: Icons.group,
            labelKey: 'admin_group.group_management',
            route: '/group-management',
          ),
          FlavorNavigationDestination(
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet,
            labelKey: 'cash',
            route: '/cash',
          ),
          FlavorNavigationDestination(
            icon: Icons.currency_exchange_outlined,
            selectedIcon: Icons.currency_exchange,
            labelKey: 'convert',
            route: '/exchange',
          ),
          FlavorNavigationDestination(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            labelKey: 'expenses',
            route: '/expenses',
          ),
          FlavorNavigationDestination(
            icon: Icons.ios_share_outlined,
            selectedIcon: Icons.ios_share,
            labelKey: 'export',
            route: '/export',
          ),
        ],
      );
    } else {
      _instance = const FlavorConfig(
        flavor: AppFlavor.user,
        appName: 'Finance',
        applicationId: 'com.app.finance.user',
        enableCashModule: false,
        enableCashboxModule: false,
        enableCurrencyModule: true,
        enableExpensesModule: true,
        enableExportModule: true,
        requiresAdminRole: false,
        enableAdminDashboard: false,
        enableFundBox: true, // Users can view their own fund box
        enableAuditLogs: false,
        enableUserManagement: false,
        enableSuperAdminCashPage: false,
        enableSuperAdminExpensesPage: false,
        showIncomingTransfers: true,
        showExchangeHistory: true,
        featureFlags: {
          'canCreateExpenses': true, // User can create expenses
          'canExchangeCurrency': true, // User can exchange currency
          'canExportData': true, // User can export data
          'canManageGroup': false, // User cannot manage groups
          'canViewAnalytics': false, // User cannot view analytics
          'canTransferFunds': false, // User cannot transfer funds
          'canViewTransfers': true, // User can view incoming transfers
          'canManageIncoming': false, // User cannot add incoming amounts
        },
        navigationDestinations: [
          FlavorNavigationDestination(
            icon: Icons.inbox_outlined,
            selectedIcon: Icons.inbox,
            labelKey: 'cash_inbox',
            route: '/cash',
          ),
          FlavorNavigationDestination(
            icon: Icons.currency_exchange_outlined,
            selectedIcon: Icons.currency_exchange,
            labelKey: 'convert',
            route: '/exchange',
          ),
          FlavorNavigationDestination(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            labelKey: 'expenses',
            route: '/expenses',
          ),
          FlavorNavigationDestination(
            icon: Icons.ios_share_outlined,
            selectedIcon: Icons.ios_share,
            labelKey: 'export',
            route: '/export',
          ),
        ],
      );
    }
  }

  bool get isSuperAdmin => flavor.isSuperAdmin;
  bool get isAdmin => flavor.isAdmin;
  bool get isUser => flavor.isUser;
  
  /// Check if flavor allows admin features
  /// Note: This checks flavor configuration, not user role
  /// Use RoleService to check actual user permissions
  bool get allowsAdminFeatures => requiresAdminRole;
  
  /// Check if both flavor and user role allow admin access
  /// This should be used in combination with RoleService
  bool canAccessAdminFeatures(bool userIsAdmin) {
    return requiresAdminRole && userIsAdmin;
  }
  
  /// Check if a specific feature is enabled
  bool isFeatureEnabled(String featureKey) {
    return featureFlags[featureKey] ?? false;
  }
  
  /// Get navigation destinations for this flavor
  List<FlavorNavigationDestination> getNavigationDestinations() {
    return navigationDestinations;
  }
  
  /// Get the default home route for this flavor
  String get defaultHomeRoute {
    if (navigationDestinations.isEmpty) return '/';
    return navigationDestinations.first.route;
  }
}
