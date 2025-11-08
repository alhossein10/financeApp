enum AppFlavor {
  admin,
  user;

  bool get isAdmin => this == AppFlavor.admin;
  bool get isUser => this == AppFlavor.user;
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

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.applicationId,
    required this.enableCashModule,
    required this.enableCashboxModule,
    required this.enableCurrencyModule,
    required this.enableExpensesModule,
    required this.enableExportModule,
  });

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    assert(_instance != null, 'FlavorConfig must be initialized');
    return _instance!;
  }

  static void initialize(AppFlavor flavor) {
    _instance = flavor == AppFlavor.admin
        ? const FlavorConfig(
            flavor: AppFlavor.admin,
            appName: 'Finance Admin',
            applicationId: 'com.app.finance.admin',
            enableCashModule: true,
            enableCashboxModule: true,
            enableCurrencyModule: true,
            enableExpensesModule: true,
            enableExportModule: true,
          )
        : const FlavorConfig(
            flavor: AppFlavor.user,
            appName: 'Finance',
            applicationId: 'com.app.finance.user',
            enableCashModule: false,
            enableCashboxModule: false,
            enableCurrencyModule: true,
            enableExpensesModule: true,
            enableExportModule: true,
          );
  }

  bool get isAdmin => flavor.isAdmin;
  bool get isUser => flavor.isUser;
}
