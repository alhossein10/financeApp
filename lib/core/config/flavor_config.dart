enum AppFlavor {
  superAdmin,
  admin,
  user;

  bool get isSuperAdmin => this == AppFlavor.superAdmin;
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
        enableFundBox: false, // Disabled for SuperAdmin - no fund-box functionality
        enableAuditLogs: true,
        enableUserManagement: true,
        enableSuperAdminCashPage: true,
        enableSuperAdminExpensesPage: true,
        showIncomingTransfers: false, // SuperAdmin only sees outgoing transfers
        showExchangeHistory: false, // No exchange history for SuperAdmin
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
}
