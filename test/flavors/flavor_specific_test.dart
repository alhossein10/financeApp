import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/config/flavor_config.dart';

/// Comprehensive flavor-specific testing
/// 
/// This test suite verifies that each flavor (SuperAdmin, Admin, User) works
/// independently with correct feature flags, navigation, and data visibility rules.
/// 
/// Test Coverage:
/// - SuperAdmin flavor configuration and features
/// - Admin flavor configuration and features
/// - User flavor configuration and features
/// - Feature flag verification for each flavor
/// - Navigation structure verification for each flavor
/// - Data visibility rules for each flavor
/// 
/// Requirements: 35.5, 35.6

void main() {
  group('Flavor-Specific Testing', () {
    group('SuperAdmin Flavor Tests', () {
      setUp(() {
        FlavorConfig.initialize(AppFlavor.superAdmin);
      });

      test('should have correct app identity', () {
        final config = FlavorConfig.instance;
        
        expect(config.flavor, equals(AppFlavor.superAdmin));
        expect(config.appName, equals('Finance SuperAdmin'));
        expect(config.applicationId, equals('com.app.finance.superadmin'));
        expect(config.isSuperAdmin, isTrue);
        expect(config.isAdmin, isFalse);
        expect(config.isUser, isFalse);
      });

      test('should have correct module configuration', () {
        final config = FlavorConfig.instance;
        
        // Enabled modules
        expect(config.enableCashModule, isTrue, reason: 'Cash module should be enabled');
        expect(config.enableCashboxModule, isTrue, reason: 'Cashbox module should be enabled');
        expect(config.enableExpensesModule, isTrue, reason: 'Expenses module should be enabled');
        expect(config.enableFundBox, isTrue, reason: 'FundBox should be enabled');
        expect(config.enableAuditLogs, isTrue, reason: 'Audit logs should be enabled');
        expect(config.enableUserManagement, isTrue, reason: 'User management should be enabled');
        
        // Disabled modules
        expect(config.enableCurrencyModule, isFalse, reason: 'Currency module should be disabled');
        expect(config.enableExportModule, isFalse, reason: 'Export module should be disabled');
        expect(config.enableAdminDashboard, isFalse, reason: 'Admin dashboard should be disabled');
      });


      test('should have correct SuperAdmin-specific flags', () {
        final config = FlavorConfig.instance;
        
        expect(config.enableSuperAdminCashPage, isTrue);
        expect(config.enableSuperAdminExpensesPage, isTrue);
        expect(config.showIncomingTransfers, isFalse, reason: 'SuperAdmin only sees outgoing transfers');
        expect(config.showExchangeHistory, isFalse, reason: 'SuperAdmin cannot exchange currency');
      });

      test('should have correct feature flags', () {
        final config = FlavorConfig.instance;
        
        // Enabled features
        expect(config.isFeatureEnabled('canManageGroup'), isTrue);
        expect(config.isFeatureEnabled('canViewAnalytics'), isTrue);
        expect(config.isFeatureEnabled('canTransferFunds'), isTrue);
        expect(config.isFeatureEnabled('canViewTransfers'), isTrue);
        expect(config.isFeatureEnabled('canManageIncoming'), isTrue);
        
        // Disabled features
        expect(config.isFeatureEnabled('canCreateExpenses'), isFalse);
        expect(config.isFeatureEnabled('canExchangeCurrency'), isFalse);
        expect(config.isFeatureEnabled('canExportData'), isFalse);
      });

      test('should have correct navigation structure', () {
        final config = FlavorConfig.instance;
        final destinations = config.getNavigationDestinations();
        
        expect(destinations.length, equals(5), reason: 'SuperAdmin should have 5 navigation items');
        
        // Verify navigation destinations
        expect(destinations[0].labelKey, equals('admin_group.group_management'));
        expect(destinations[0].route, equals('/group-management'));
        
        expect(destinations[1].labelKey, equals('cash'));
        expect(destinations[1].route, equals('/cash'));
        
        expect(destinations[2].labelKey, equals('transfers'));
        expect(destinations[2].route, equals('/transfers'));
        
        expect(destinations[3].labelKey, equals('analytics'));
        expect(destinations[3].route, equals('/analytics'));
        
        expect(destinations[4].labelKey, equals('profile'));
        expect(destinations[4].route, equals('/profile'));
      });

      test('should have correct default home route', () {
        final config = FlavorConfig.instance;
        
        expect(config.defaultHomeRoute, equals('/group-management'));
      });

      test('should verify data visibility rules', () {
        final config = FlavorConfig.instance;
        
        // SuperAdmin can view admin data
        expect(config.isFeatureEnabled('canManageGroup'), isTrue);
        expect(config.isFeatureEnabled('canViewAnalytics'), isTrue);
        
        // SuperAdmin cannot create expenses
        expect(config.isFeatureEnabled('canCreateExpenses'), isFalse);
        
        // SuperAdmin cannot exchange currency
        expect(config.isFeatureEnabled('canExchangeCurrency'), isFalse);
        
        // SuperAdmin cannot export data
        expect(config.isFeatureEnabled('canExportData'), isFalse);
      });

      test('should require admin role', () {
        final config = FlavorConfig.instance;
        
        expect(config.requiresAdminRole, isTrue);
        expect(config.allowsAdminFeatures, isTrue);
      });
    });

    group('Admin Flavor Tests', () {
      setUp(() {
        FlavorConfig.initialize(AppFlavor.admin);
      });

      test('should have correct app identity', () {
        final config = FlavorConfig.instance;
        
        expect(config.flavor, equals(AppFlavor.admin));
        expect(config.appName, equals('Finance Admin'));
        expect(config.applicationId, equals('com.app.finance.admin'));
        expect(config.isAdmin, isTrue);
        expect(config.isSuperAdmin, isFalse);
        expect(config.isUser, isFalse);
      });

      test('should have correct module configuration', () {
        final config = FlavorConfig.instance;
        
        // All modules should be enabled for Admin
        expect(config.enableCashModule, isTrue);
        expect(config.enableCashboxModule, isTrue);
        expect(config.enableCurrencyModule, isTrue);
        expect(config.enableExpensesModule, isTrue);
        expect(config.enableExportModule, isTrue);
        expect(config.enableAdminDashboard, isTrue);
        expect(config.enableFundBox, isTrue);
        expect(config.enableAuditLogs, isTrue);
        expect(config.enableUserManagement, isTrue);
      });

      test('should have correct Admin-specific flags', () {
        final config = FlavorConfig.instance;
        
        expect(config.enableSuperAdminCashPage, isFalse);
        expect(config.enableSuperAdminExpensesPage, isFalse);
        expect(config.showIncomingTransfers, isTrue);
        expect(config.showExchangeHistory, isTrue);
      });

      test('should have correct feature flags', () {
        final config = FlavorConfig.instance;
        
        // Enabled features
        expect(config.isFeatureEnabled('canCreateExpenses'), isTrue);
        expect(config.isFeatureEnabled('canExchangeCurrency'), isTrue);
        expect(config.isFeatureEnabled('canExportData'), isTrue);
        expect(config.isFeatureEnabled('canManageGroup'), isTrue);
        expect(config.isFeatureEnabled('canTransferFunds'), isTrue);
        expect(config.isFeatureEnabled('canViewTransfers'), isTrue);
        
        // Disabled features
        expect(config.isFeatureEnabled('canViewAnalytics'), isFalse);
        expect(config.isFeatureEnabled('canManageIncoming'), isFalse);
      });

      test('should have correct navigation structure', () {
        final config = FlavorConfig.instance;
        final destinations = config.getNavigationDestinations();
        
        expect(destinations.length, equals(6), reason: 'Admin should have 6 navigation items');
        
        // Verify navigation destinations
        expect(destinations[0].labelKey, equals('admin_group.group_management'));
        expect(destinations[0].route, equals('/group-management'));
        
        expect(destinations[1].labelKey, equals('cash'));
        expect(destinations[1].route, equals('/cash'));
        
        expect(destinations[2].labelKey, equals('convert'));
        expect(destinations[2].route, equals('/exchange'));
        
        expect(destinations[3].labelKey, equals('expenses'));
        expect(destinations[3].route, equals('/expenses'));
        
        expect(destinations[4].labelKey, equals('export'));
        expect(destinations[4].route, equals('/export'));
        
        expect(destinations[5].labelKey, equals('profile'));
        expect(destinations[5].route, equals('/profile'));
      });

      test('should have correct default home route', () {
        final config = FlavorConfig.instance;
        
        expect(config.defaultHomeRoute, equals('/group-management'));
      });

      test('should verify data visibility rules', () {
        final config = FlavorConfig.instance;
        
        // Admin can manage users in their group
        expect(config.isFeatureEnabled('canManageGroup'), isTrue);
        
        // Admin can create expenses
        expect(config.isFeatureEnabled('canCreateExpenses'), isTrue);
        
        // Admin can exchange currency
        expect(config.isFeatureEnabled('canExchangeCurrency'), isTrue);
        
        // Admin can export data
        expect(config.isFeatureEnabled('canExportData'), isTrue);
        
        // Admin can transfer funds to users
        expect(config.isFeatureEnabled('canTransferFunds'), isTrue);
        
        // Admin cannot view global analytics
        expect(config.isFeatureEnabled('canViewAnalytics'), isFalse);
        
        // Admin cannot manage incoming amounts
        expect(config.isFeatureEnabled('canManageIncoming'), isFalse);
      });

      test('should require admin role', () {
        final config = FlavorConfig.instance;
        
        expect(config.requiresAdminRole, isTrue);
        expect(config.allowsAdminFeatures, isTrue);
      });
    });

    group('User Flavor Tests', () {
      setUp(() {
        FlavorConfig.initialize(AppFlavor.user);
      });

      test('should have correct app identity', () {
        final config = FlavorConfig.instance;
        
        expect(config.flavor, equals(AppFlavor.user));
        expect(config.appName, equals('Finance'));
        expect(config.applicationId, equals('com.app.finance.user'));
        expect(config.isUser, isTrue);
        expect(config.isAdmin, isFalse);
        expect(config.isSuperAdmin, isFalse);
      });

      test('should have correct module configuration', () {
        final config = FlavorConfig.instance;
        
        // Enabled modules
        expect(config.enableCurrencyModule, isTrue);
        expect(config.enableExpensesModule, isTrue);
        expect(config.enableExportModule, isTrue);
        expect(config.enableFundBox, isTrue);
        
        // Disabled modules
        expect(config.enableCashModule, isFalse);
        expect(config.enableCashboxModule, isFalse);
        expect(config.enableAdminDashboard, isFalse);
        expect(config.enableAuditLogs, isFalse);
        expect(config.enableUserManagement, isFalse);
      });

      test('should have correct User-specific flags', () {
        final config = FlavorConfig.instance;
        
        expect(config.enableSuperAdminCashPage, isFalse);
        expect(config.enableSuperAdminExpensesPage, isFalse);
        expect(config.showIncomingTransfers, isTrue);
        expect(config.showExchangeHistory, isTrue);
      });

      test('should have correct feature flags', () {
        final config = FlavorConfig.instance;
        
        // Enabled features
        expect(config.isFeatureEnabled('canCreateExpenses'), isTrue);
        expect(config.isFeatureEnabled('canExchangeCurrency'), isTrue);
        expect(config.isFeatureEnabled('canExportData'), isTrue);
        expect(config.isFeatureEnabled('canViewTransfers'), isTrue);
        
        // Disabled features
        expect(config.isFeatureEnabled('canManageGroup'), isFalse);
        expect(config.isFeatureEnabled('canViewAnalytics'), isFalse);
        expect(config.isFeatureEnabled('canTransferFunds'), isFalse);
        expect(config.isFeatureEnabled('canManageIncoming'), isFalse);
      });

      test('should have correct navigation structure', () {
        final config = FlavorConfig.instance;
        final destinations = config.getNavigationDestinations();
        
        expect(destinations.length, equals(5), reason: 'User should have 5 navigation items');
        
        // Verify navigation destinations
        expect(destinations[0].labelKey, equals('home'));
        expect(destinations[0].route, equals('/home'));
        
        expect(destinations[1].labelKey, equals('convert'));
        expect(destinations[1].route, equals('/exchange'));
        
        expect(destinations[2].labelKey, equals('expenses'));
        expect(destinations[2].route, equals('/expenses'));
        
        expect(destinations[3].labelKey, equals('export'));
        expect(destinations[3].route, equals('/export'));
        
        expect(destinations[4].labelKey, equals('profile'));
        expect(destinations[4].route, equals('/profile'));
      });

      test('should have correct default home route', () {
        final config = FlavorConfig.instance;
        
        expect(config.defaultHomeRoute, equals('/home'));
      });

      test('should verify data visibility rules', () {
        final config = FlavorConfig.instance;
        
        // User can create expenses
        expect(config.isFeatureEnabled('canCreateExpenses'), isTrue);
        
        // User can exchange currency
        expect(config.isFeatureEnabled('canExchangeCurrency'), isTrue);
        
        // User can export their own data
        expect(config.isFeatureEnabled('canExportData'), isTrue);
        
        // User can view incoming transfers
        expect(config.isFeatureEnabled('canViewTransfers'), isTrue);
        
        // User cannot manage groups
        expect(config.isFeatureEnabled('canManageGroup'), isFalse);
        
        // User cannot view analytics
        expect(config.isFeatureEnabled('canViewAnalytics'), isFalse);
        
        // User cannot transfer funds
        expect(config.isFeatureEnabled('canTransferFunds'), isFalse);
        
        // User cannot manage incoming amounts
        expect(config.isFeatureEnabled('canManageIncoming'), isFalse);
      });

      test('should not require admin role', () {
        final config = FlavorConfig.instance;
        
        expect(config.requiresAdminRole, isFalse);
        expect(config.allowsAdminFeatures, isFalse);
      });
    });

    group('Cross-Flavor Comparison Tests', () {
      test('should have different app names for each flavor', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminName = FlavorConfig.instance.appName;
        
        FlavorConfig.initialize(AppFlavor.admin);
        final adminName = FlavorConfig.instance.appName;
        
        FlavorConfig.initialize(AppFlavor.user);
        final userName = FlavorConfig.instance.appName;
        
        expect(superAdminName, equals('Finance SuperAdmin'));
        expect(adminName, equals('Finance Admin'));
        expect(userName, equals('Finance'));
        
        // All should be different
        expect(superAdminName, isNot(equals(adminName)));
        expect(adminName, isNot(equals(userName)));
        expect(superAdminName, isNot(equals(userName)));
      });

      test('should have different application IDs for each flavor', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminId = FlavorConfig.instance.applicationId;
        
        FlavorConfig.initialize(AppFlavor.admin);
        final adminId = FlavorConfig.instance.applicationId;
        
        FlavorConfig.initialize(AppFlavor.user);
        final userId = FlavorConfig.instance.applicationId;
        
        expect(superAdminId, equals('com.app.finance.superadmin'));
        expect(adminId, equals('com.app.finance.admin'));
        expect(userId, equals('com.app.finance.user'));
        
        // All should be different
        expect(superAdminId, isNot(equals(adminId)));
        expect(adminId, isNot(equals(userId)));
        expect(superAdminId, isNot(equals(userId)));
      });

      test('should have different navigation counts', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminNavCount = FlavorConfig.instance.navigationDestinations.length;
        
        FlavorConfig.initialize(AppFlavor.admin);
        final adminNavCount = FlavorConfig.instance.navigationDestinations.length;
        
        FlavorConfig.initialize(AppFlavor.user);
        final userNavCount = FlavorConfig.instance.navigationDestinations.length;
        
        expect(superAdminNavCount, equals(5));
        expect(adminNavCount, equals(6));
        expect(userNavCount, equals(5));
      });

      test('should have different default home routes', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminHome = FlavorConfig.instance.defaultHomeRoute;
        
        FlavorConfig.initialize(AppFlavor.admin);
        final adminHome = FlavorConfig.instance.defaultHomeRoute;
        
        FlavorConfig.initialize(AppFlavor.user);
        final userHome = FlavorConfig.instance.defaultHomeRoute;
        
        expect(superAdminHome, equals('/group-management'));
        expect(adminHome, equals('/group-management'));
        expect(userHome, equals('/home'));
      });

      test('should have unique feature flag combinations', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminCanExport = FlavorConfig.instance.isFeatureEnabled('canExportData');
        final superAdminCanAnalyze = FlavorConfig.instance.isFeatureEnabled('canViewAnalytics');
        
        FlavorConfig.initialize(AppFlavor.admin);
        final adminCanExport = FlavorConfig.instance.isFeatureEnabled('canExportData');
        final adminCanAnalyze = FlavorConfig.instance.isFeatureEnabled('canViewAnalytics');
        
        FlavorConfig.initialize(AppFlavor.user);
        final userCanExport = FlavorConfig.instance.isFeatureEnabled('canExportData');
        final userCanAnalyze = FlavorConfig.instance.isFeatureEnabled('canViewAnalytics');
        
        // SuperAdmin: can analyze but not export
        expect(superAdminCanAnalyze, isTrue);
        expect(superAdminCanExport, isFalse);
        
        // Admin: can export but not analyze
        expect(adminCanExport, isTrue);
        expect(adminCanAnalyze, isFalse);
        
        // User: can export but not analyze
        expect(userCanExport, isTrue);
        expect(userCanAnalyze, isFalse);
      });
    });

    group('Navigation Route Verification Tests', () {
      test('should have correct routes for SuperAdmin navigation', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;
        final destinations = config.navigationDestinations;
        
        expect(destinations[0].route, equals('/group-management'));
        expect(destinations[1].route, equals('/cash'));
        expect(destinations[2].route, equals('/transfers'));
        expect(destinations[3].route, equals('/analytics'));
        expect(destinations[4].route, equals('/profile'));
      });

      test('should have correct routes for Admin navigation', () {
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;
        final destinations = config.navigationDestinations;
        
        expect(destinations[0].route, equals('/group-management'));
        expect(destinations[1].route, equals('/cash'));
        expect(destinations[2].route, equals('/exchange'));
        expect(destinations[3].route, equals('/expenses'));
        expect(destinations[4].route, equals('/export'));
        expect(destinations[5].route, equals('/profile'));
      });

      test('should have correct routes for User navigation', () {
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;
        final destinations = config.navigationDestinations;
        
        expect(destinations[0].route, equals('/home'));
        expect(destinations[1].route, equals('/exchange'));
        expect(destinations[2].route, equals('/expenses'));
        expect(destinations[3].route, equals('/export'));
        expect(destinations[4].route, equals('/profile'));
      });

      test('SuperAdmin should not have exchange or export routes', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;
        final routes = config.navigationDestinations.map((d) => d.route).toList();
        
        expect(routes.contains('/exchange'), isFalse);
        expect(routes.contains('/export'), isFalse);
      });

      test('Admin should have all routes including exchange and export', () {
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;
        final routes = config.navigationDestinations.map((d) => d.route).toList();
        
        expect(routes.contains('/group-management'), isTrue);
        expect(routes.contains('/cash'), isTrue);
        expect(routes.contains('/exchange'), isTrue);
        expect(routes.contains('/expenses'), isTrue);
        expect(routes.contains('/export'), isTrue);
        expect(routes.contains('/profile'), isTrue);
      });

      test('User should not have group-management or analytics routes', () {
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;
        final routes = config.navigationDestinations.map((d) => d.route).toList();
        
        expect(routes.contains('/group-management'), isFalse);
        expect(routes.contains('/analytics'), isFalse);
        expect(routes.contains('/home'), isTrue);
      });
    });

    group('Feature Flag Edge Cases', () {
      test('should return false for non-existent feature flags', () {
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;
        
        expect(config.isFeatureEnabled('nonExistentFeature'), isFalse);
        expect(config.isFeatureEnabled(''), isFalse);
      });

      test('should handle feature flag checks across flavor changes', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminCanExport = FlavorConfig.instance.isFeatureEnabled('canExportData');
        
        FlavorConfig.initialize(AppFlavor.admin);
        final adminCanExport = FlavorConfig.instance.isFeatureEnabled('canExportData');
        
        expect(superAdminCanExport, isFalse);
        expect(adminCanExport, isTrue);
      });
    });

    group('Data Visibility Rules Verification', () {
      test('SuperAdmin should only see admin-level data', () {
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;
        
        // Can manage admin groups
        expect(config.isFeatureEnabled('canManageGroup'), isTrue);
        
        // Can view analytics (aggregated admin data)
        expect(config.isFeatureEnabled('canViewAnalytics'), isTrue);
        
        // Cannot create expenses (view-only for expenses)
        expect(config.isFeatureEnabled('canCreateExpenses'), isFalse);
        
        // Cannot exchange currency
        expect(config.isFeatureEnabled('canExchangeCurrency'), isFalse);
      });

      test('Admin should see group-level data', () {
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;
        
        // Can manage user groups
        expect(config.isFeatureEnabled('canManageGroup'), isTrue);
        
        // Can create expenses (own + users in group)
        expect(config.isFeatureEnabled('canCreateExpenses'), isTrue);
        
        // Can exchange currency (own + users in group)
        expect(config.isFeatureEnabled('canExchangeCurrency'), isTrue);
        
        // Cannot view global analytics
        expect(config.isFeatureEnabled('canViewAnalytics'), isFalse);
      });

      test('User should only see personal data', () {
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;
        
        // Can create own expenses
        expect(config.isFeatureEnabled('canCreateExpenses'), isTrue);
        
        // Can exchange own currency
        expect(config.isFeatureEnabled('canExchangeCurrency'), isTrue);
        
        // Can export own data
        expect(config.isFeatureEnabled('canExportData'), isTrue);
        
        // Cannot manage groups
        expect(config.isFeatureEnabled('canManageGroup'), isFalse);
        
        // Cannot view analytics
        expect(config.isFeatureEnabled('canViewAnalytics'), isFalse);
        
        // Cannot transfer funds
        expect(config.isFeatureEnabled('canTransferFunds'), isFalse);
      });
    });
  });
}
