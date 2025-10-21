import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/config/flavor_config.dart';

void main() {
  group('AppFlavor', () {
    test('should correctly identify admin flavor', () {
      // Arrange
      const flavor = AppFlavor.admin;

      // Assert
      expect(flavor.isAdmin, isTrue);
      expect(flavor.isUser, isFalse);
    });

    test('should correctly identify user flavor', () {
      // Arrange
      const flavor = AppFlavor.user;

      // Assert
      expect(flavor.isUser, isTrue);
      expect(flavor.isAdmin, isFalse);
    });
  });

  group('FlavorConfig', () {
    setUp(() {
      // Reset the singleton instance before each test
      // This is a workaround since we can't directly reset the private _instance
      // We'll initialize it in each test
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
  });
}
