import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/config/flavor_config.dart';

void main() {
  group('AppFlavor', () {
    test('should correctly identify superAdmin flavor', () {
      // Arrange
      const flavor = AppFlavor.superAdmin;

      // Assert
      expect(flavor.isSuperAdmin, isTrue);
      expect(flavor.isAdmin, isFalse);
      expect(flavor.isUser, isFalse);
    });

    test('should correctly identify admin flavor', () {
      // Arrange
      const flavor = AppFlavor.admin;

      // Assert
      expect(flavor.isAdmin, isTrue);
      expect(flavor.isSuperAdmin, isFalse);
      expect(flavor.isUser, isFalse);
    });

    test('should correctly identify user flavor', () {
      // Arrange
      const flavor = AppFlavor.user;

      // Assert
      expect(flavor.isUser, isTrue);
      expect(flavor.isAdmin, isFalse);
      expect(flavor.isSuperAdmin, isFalse);
    });
  });

  group('FlavorConfig', () {
    setUp(() {
      // Reset the singleton instance before each test
      // This is a workaround since we can't directly reset the private _instance
      // We'll initialize it in each test
    });

    group('SuperAdmin Flavor Configuration', () {
      test('should initialize with superAdmin flavor and correct module settings', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.flavor, equals(AppFlavor.superAdmin));
        expect(config.appName, equals('Finance SuperAdmin'));
        expect(config.applicationId, equals('com.app.finance.superadmin'));
        expect(config.enableCashModule, isTrue);
        expect(config.enableCashboxModule, isTrue);
        expect(config.enableCurrencyModule, isFalse); // Disabled for SuperAdmin
        expect(config.enableExpensesModule, isTrue);
        expect(config.enableExportModule, isFalse); // Disabled for SuperAdmin
        expect(config.requiresAdminRole, isTrue);
        expect(config.enableAdminDashboard, isFalse); // SuperAdmin has different dashboard
        expect(config.enableFundBox, isTrue);
        expect(config.enableAuditLogs, isTrue);
        expect(config.enableUserManagement, isTrue);
      });

      test('should have SuperAdmin-specific flags correctly set', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableSuperAdminCashPage, isTrue);
        expect(config.enableSuperAdminExpensesPage, isTrue);
        expect(config.showIncomingTransfers, isFalse);
        expect(config.showExchangeHistory, isFalse);
      });

      test('should return true for isSuperAdmin getter', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.isSuperAdmin, isTrue);
        expect(config.isAdmin, isFalse);
        expect(config.isUser, isFalse);
      });

      test('should have correct app name for superAdmin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.appName, equals('Finance SuperAdmin'));
      });

      test('should have correct application ID for superAdmin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.applicationId, equals('com.app.finance.superadmin'));
      });

      test('should disable Currency module in superAdmin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableCurrencyModule, isFalse);
      });

      test('should disable Export module in superAdmin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableExportModule, isFalse);
      });

      test('should not show incoming transfers in superAdmin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.showIncomingTransfers, isFalse);
      });

      test('should not show exchange history in superAdmin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.showExchangeHistory, isFalse);
      });
    });

    group('Admin Flavor Configuration', () {
      test('should initialize with admin flavor and enable all modules', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.flavor, equals(AppFlavor.admin));
        expect(config.appName, equals('Finance Admin'));
        expect(config.applicationId, equals('com.app.finance.admin'));
        expect(config.enableCashModule, isTrue);
        expect(config.enableCashboxModule, isTrue);
        expect(config.enableCurrencyModule, isTrue);
        expect(config.enableExpensesModule, isTrue);
        expect(config.enableExportModule, isTrue);
        expect(config.requiresAdminRole, isTrue);
        expect(config.enableAdminDashboard, isTrue);
        expect(config.enableFundBox, isTrue);
        expect(config.enableAuditLogs, isTrue);
        expect(config.enableUserManagement, isTrue);
      });

      test('should return true for isAdmin getter', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.isAdmin, isTrue);
        expect(config.isUser, isFalse);
      });

      test('should have correct app name for admin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.appName, equals('Finance Admin'));
      });

      test('should have correct application ID for admin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.applicationId, equals('com.app.finance.admin'));
      });

      test('should enable Cash module in admin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableCashModule, isTrue);
      });

      test('should enable Cashbox module in admin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableCashboxModule, isTrue);
      });

      test('should have SuperAdmin-specific flags disabled for admin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableSuperAdminCashPage, isFalse);
        expect(config.enableSuperAdminExpensesPage, isFalse);
        expect(config.showIncomingTransfers, isTrue);
        expect(config.showExchangeHistory, isTrue);
      });
    });

    group('User Flavor Configuration', () {
      test('should initialize with user flavor and disable Cash and Cashbox modules', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.flavor, equals(AppFlavor.user));
        expect(config.appName, equals('Finance'));
        expect(config.applicationId, equals('com.app.finance.user'));
        expect(config.enableCashModule, isFalse);
        expect(config.enableCashboxModule, isFalse);
        expect(config.enableCurrencyModule, isTrue);
        expect(config.enableExpensesModule, isTrue);
        expect(config.enableExportModule, isTrue);
        expect(config.requiresAdminRole, isFalse);
        expect(config.enableAdminDashboard, isFalse);
        expect(config.enableFundBox, isTrue); // Users can view their own fund box
        expect(config.enableAuditLogs, isFalse);
        expect(config.enableUserManagement, isFalse);
      });

      test('should return true for isUser getter', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.isUser, isTrue);
        expect(config.isAdmin, isFalse);
      });

      test('should have correct app name for user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.appName, equals('Finance'));
      });

      test('should have correct application ID for user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.applicationId, equals('com.app.finance.user'));
      });

      test('should disable Cash module in user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableCashModule, isFalse);
      });

      test('should disable Cashbox module in user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableCashboxModule, isFalse);
      });

      test('should enable Currency module in user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableCurrencyModule, isTrue);
      });

      test('should enable Expenses module in user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableExpensesModule, isTrue);
      });

      test('should enable Export module in user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableExportModule, isTrue);
      });

      test('should have SuperAdmin-specific flags disabled for user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.enableSuperAdminCashPage, isFalse);
        expect(config.enableSuperAdminExpensesPage, isFalse);
        expect(config.showIncomingTransfers, isTrue);
        expect(config.showExchangeHistory, isTrue);
      });
    });

    group('Module Enable/Disable Flags', () {
      test('should have all modules enabled for admin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert - All modules should be enabled
        expect(config.enableCashModule, isTrue);
        expect(config.enableCashboxModule, isTrue);
        expect(config.enableCurrencyModule, isTrue);
        expect(config.enableExpensesModule, isTrue);
        expect(config.enableExportModule, isTrue);
      });

      test('should have only Currency, Expenses, and Export modules enabled for user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert - Cash and Cashbox should be disabled
        expect(config.enableCashModule, isFalse);
        expect(config.enableCashboxModule, isFalse);
        
        // Assert - Currency, Expenses, and Export should be enabled
        expect(config.enableCurrencyModule, isTrue);
        expect(config.enableExpensesModule, isTrue);
        expect(config.enableExportModule, isTrue);
      });

      test('should correctly differentiate module flags between admin and user flavors', () {
        // Act - Initialize as admin first
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;
        final adminCashEnabled = adminConfig.enableCashModule;
        final adminCashboxEnabled = adminConfig.enableCashboxModule;

        // Act - Re-initialize as user
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;
        final userCashEnabled = userConfig.enableCashModule;
        final userCashboxEnabled = userConfig.enableCashboxModule;

        // Assert - Admin should have Cash and Cashbox enabled
        expect(adminCashEnabled, isTrue);
        expect(adminCashboxEnabled, isTrue);

        // Assert - User should have Cash and Cashbox disabled
        expect(userCashEnabled, isFalse);
        expect(userCashboxEnabled, isFalse);
      });
    });

    group('Singleton Instance', () {
      test('should return the same instance after initialization', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final instance1 = FlavorConfig.instance;
        final instance2 = FlavorConfig.instance;

        // Assert
        expect(identical(instance1, instance2), isTrue);
      });

      test('should update instance when re-initialized with different flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final adminInstance = FlavorConfig.instance;
        final adminFlavor = adminInstance.flavor;

        FlavorConfig.initialize(AppFlavor.user);
        final userInstance = FlavorConfig.instance;
        final userFlavor = userInstance.flavor;

        // Assert
        expect(adminFlavor, equals(AppFlavor.admin));
        expect(userFlavor, equals(AppFlavor.user));
      });
    });

    group('SuperAdmin-Specific Flags', () {
      test('should enable SuperAdmin cash page only for SuperAdmin flavor', () {
        // Act - SuperAdmin flavor
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminConfig = FlavorConfig.instance;

        // Act - Admin flavor
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;

        // Act - User flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;

        // Assert
        expect(superAdminConfig.enableSuperAdminCashPage, isTrue);
        expect(adminConfig.enableSuperAdminCashPage, isFalse);
        expect(userConfig.enableSuperAdminCashPage, isFalse);
      });

      test('should enable SuperAdmin expenses page only for SuperAdmin flavor', () {
        // Act - SuperAdmin flavor
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminConfig = FlavorConfig.instance;

        // Act - Admin flavor
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;

        // Act - User flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;

        // Assert
        expect(superAdminConfig.enableSuperAdminExpensesPage, isTrue);
        expect(adminConfig.enableSuperAdminExpensesPage, isFalse);
        expect(userConfig.enableSuperAdminExpensesPage, isFalse);
      });

      test('should hide incoming transfers only for SuperAdmin flavor', () {
        // Act - SuperAdmin flavor
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminConfig = FlavorConfig.instance;

        // Act - Admin flavor
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;

        // Act - User flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;

        // Assert
        expect(superAdminConfig.showIncomingTransfers, isFalse);
        expect(adminConfig.showIncomingTransfers, isTrue);
        expect(userConfig.showIncomingTransfers, isTrue);
      });

      test('should hide exchange history only for SuperAdmin flavor', () {
        // Act - SuperAdmin flavor
        FlavorConfig.initialize(AppFlavor.superAdmin);
        final superAdminConfig = FlavorConfig.instance;

        // Act - Admin flavor
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;

        // Act - User flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;

        // Assert
        expect(superAdminConfig.showExchangeHistory, isFalse);
        expect(adminConfig.showExchangeHistory, isTrue);
        expect(userConfig.showExchangeHistory, isTrue);
      });
    });

    group('Role-Based Access Control', () {
      test('should return true for allowsAdminFeatures in admin flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.allowsAdminFeatures, isTrue);
      });

      test('should return false for allowsAdminFeatures in user flavor', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.allowsAdminFeatures, isFalse);
      });

      test('should allow admin access when both flavor and user role are admin', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.canAccessAdminFeatures(true), isTrue);
      });

      test('should deny admin access when flavor is admin but user is not admin', () {
        // Act
        FlavorConfig.initialize(AppFlavor.admin);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.canAccessAdminFeatures(false), isFalse);
      });

      test('should deny admin access when flavor is user even if user is admin', () {
        // Act
        FlavorConfig.initialize(AppFlavor.user);
        final config = FlavorConfig.instance;

        // Assert
        expect(config.canAccessAdminFeatures(true), isFalse);
      });

      test('should enable admin dashboard only in admin flavor', () {
        // Act - Admin flavor
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;

        // Act - User flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;

        // Assert
        expect(adminConfig.enableAdminDashboard, isTrue);
        expect(userConfig.enableAdminDashboard, isFalse);
      });

      test('should enable fund box in both admin and user flavors', () {
        // Act - Admin flavor
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;

        // Act - User flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;

        // Assert - Both should have fund box enabled
        expect(adminConfig.enableFundBox, isTrue);
        expect(userConfig.enableFundBox, isTrue);
      });

      test('should enable audit logs only in admin flavor', () {
        // Act - Admin flavor
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;

        // Act - User flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;

        // Assert
        expect(adminConfig.enableAuditLogs, isTrue);
        expect(userConfig.enableAuditLogs, isFalse);
      });

      test('should enable user management only in admin flavor', () {
        // Act - Admin flavor
        FlavorConfig.initialize(AppFlavor.admin);
        final adminConfig = FlavorConfig.instance;

        // Act - User flavor
        FlavorConfig.initialize(AppFlavor.user);
        final userConfig = FlavorConfig.instance;

        // Assert
        expect(adminConfig.enableUserManagement, isTrue);
        expect(userConfig.enableUserManagement, isFalse);
      });
    });
  });
}
