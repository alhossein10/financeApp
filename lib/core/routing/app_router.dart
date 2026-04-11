import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../injection_container.dart' as di;
import '../config/flavor_config.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/settings/presentation/pages/language_settings_page.dart';
import '../../features/admin_group/presentation/pages/group_management_page.dart';
import '../../features/admin_group/presentation/pages/group_info_page.dart';
import '../../features/admin_group/presentation/pages/join_group_page.dart';
import '../../features/admin_group/presentation/bloc/admin_group_bloc.dart';
import '../../features/exchanges/presentation/pages/exchange_history_page.dart';
import '../../features/exchanges/presentation/bloc/exchange_bloc.dart';
import '../../features/superadmin/presentation/pages/superadmin_analytics_page.dart';
import '../../features/superadmin/presentation/pages/superadmin_transfer_page.dart';
import '../../features/admin/presentation/bloc/super_admin_analytics_bloc.dart';
import '../../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../../ui/cash_inbox_page.dart';
import '../../ui/user_cash_inbox_page.dart';
import '../../ui/currency_tool_page.dart';
import '../../ui/expense_page.dart';
import '../../ui/superadmin_cash_page.dart';
import '../../ui/superadmin_expenses_page.dart';
import '../../features/admin/presentation/pages/admin_export_page.dart';
import '../../features/user/presentation/pages/user_export_page.dart';
import '../../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../../features/incoming/presentation/bloc/incoming_bloc.dart';
import '../../features/expenses/presentation/bloc/expense_bloc.dart';
import 'home_scaffold.dart';

/// App router configuration with flavor-specific route guards
/// 
/// This class manages all application routes and ensures that routes
/// are only accessible based on the current flavor configuration.
/// 
/// Route Guards:
/// - Routes are filtered based on FlavorConfig feature flags
/// - Unauthorized routes return a 404-style error page
/// - Default home route is determined by flavor
/// 
/// Usage:
/// ```dart
/// MaterialApp(
///   onGenerateRoute: AppRouter.generateRoute,
///   initialRoute: AppRouter.initialRoute,
/// )
/// ```
class AppRouter {
  /// Get the initial route based on flavor
  static String get initialRoute => '/';
  
  /// Get the default home route based on flavor
  static String get defaultHomeRoute {
    final config = FlavorConfig.instance;
    return config.defaultHomeRoute;
  }
  
  /// Generate routes with flavor-specific guards
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final config = FlavorConfig.instance;
    
    // Check if route is allowed for current flavor
    if (!_isRouteAllowed(settings.name ?? '', config)) {
      return MaterialPageRoute(
        builder: (_) => _buildUnauthorizedPage(settings.name ?? ''),
      );
    }
    
    // Route to appropriate page
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const AuthenticationWrapper(),
        );
        
      case '/home':
        return MaterialPageRoute(
          builder: (_) => const HomeScaffold(),
        );
        
      case '/group-management':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<AdminGroupBloc>(),
            child: const GroupManagementPage(),
          ),
        );
        
      case '/group-info':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<AdminGroupBloc>(),
            child: const GroupInfoPage(),
          ),
        );
        
      case '/join-group':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<AdminGroupBloc>(),
            child: const JoinGroupPage(),
          ),
        );
        
      case '/cash':
        return MaterialPageRoute(
          builder: (_) => _buildCashPage(config),
        );
        
      case '/exchange':
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<ExchangeBloc>()),
              BlocProvider(create: (_) => di.sl<FundBoxBloc>()),
            ],
            child: const CurrencyToolPage(),
          ),
        );
        
      case '/exchange-history':
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<ExchangeBloc>()),
              BlocProvider(create: (_) => di.sl<AdminGroupBloc>()),
            ],
            child: const ExchangeHistoryPage(),
          ),
        );
        
      case '/expenses':
        return MaterialPageRoute(
          builder: (_) => _buildExpensesPage(config),
        );
        
      case '/export':
        // Use flavor-specific export pages (frontend-only, no API)
        if (FlavorConfig.instance.flavor.isAdmin) {
          return MaterialPageRoute(builder: (_) => const AdminExportPage());
        } else if (FlavorConfig.instance.flavor.isUser) {
          return MaterialPageRoute(builder: (_) => const UserExportPage());
        } else {
          // SuperAdmin doesn't have export page yet
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Export not available for SuperAdmin')),
            ),
          );
        }
        
      case '/transfers':
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<TransferBloc>()),
              BlocProvider(create: (_) => di.sl<AdminGroupBloc>()),
            ],
            child: const SuperAdminTransferPage(),
          ),
        );
        
      case '/analytics':
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => di.sl<SuperAdminAnalyticsBloc>()),
              BlocProvider(create: (_) => di.sl<AdminGroupBloc>()),
            ],
            child: const SuperAdminAnalyticsPage(),
          ),
        );
        
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<ProfileBloc>(),
            child: const ProfilePage(),
          ),
        );
        
      case '/language-settings':
        return MaterialPageRoute(
          builder: (_) => const LanguageSettingsPage(),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => _buildNotFoundPage(settings.name ?? ''),
        );
    }
  }
  
  /// Check if a route is allowed for the current flavor
  static bool _isRouteAllowed(String route, FlavorConfig config) {
    // Root and home routes are always allowed
    if (route == '/' || route == '/home') {
      return true;
    }
    
    // Profile and settings are always allowed
    if (route == '/profile' || route == '/language-settings') {
      return true;
    }
    
    // Check flavor-specific routes
    switch (route) {
      case '/group-management':
      case '/group-info':
      case '/join-group':
        // Group management available for SuperAdmin and Admin
        return config.isSuperAdmin || config.isAdmin;
        
      case '/cash':
        // Cash page available for all flavors (different implementations)
        return true;
        
      case '/exchange':
      case '/exchange-history':
        // Exchange only for Admin and User
        return config.enableCurrencyModule;
        
      case '/expenses':
        // Expenses available for all flavors (different implementations)
        return config.enableExpensesModule;
        
      case '/export':
        // Export only for Admin and User
        return config.enableExportModule;
        
      case '/transfers':
        // Transfers page only for SuperAdmin
        return config.isSuperAdmin;
        
      case '/analytics':
        // Analytics only for SuperAdmin
        return config.isSuperAdmin && config.isFeatureEnabled('canViewAnalytics');
        
      default:
        return false;
    }
  }
  
  /// Build the appropriate cash page based on flavor
  static Widget _buildCashPage(FlavorConfig config) {
    if (config.isSuperAdmin) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => di.sl<FundBoxBloc>()),
          BlocProvider(create: (_) => di.sl<TransferBloc>()),
          BlocProvider(create: (_) => di.sl<AdminGroupBloc>()),
        ],
        child: const SuperAdminCashPage(),
      );
    } else if (config.isAdmin) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => di.sl<AdminGroupBloc>()),
        ],
        child: const CashInboxPage(),
      );
    } else {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => di.sl<FundBoxBloc>()),
          BlocProvider(create: (_) => di.sl<IncomingBloc>()),
        ],
        child: const UserCashInboxPage(),
      );
    }
  }
  
  /// Build the appropriate expenses page based on flavor
  static Widget _buildExpensesPage(FlavorConfig config) {
    if (config.isSuperAdmin) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => di.sl<SuperAdminAnalyticsBloc>()),
          BlocProvider(create: (_) => di.sl<AdminGroupBloc>()),
        ],
        child: const SuperAdminExpensesPage(),
      );
    } else if (config.isAdmin) {
      return BlocProvider(
        create: (_) => di.sl<AdminGroupBloc>(),
        child: const ExpensePage(),
      );
    } else {
      return const ExpensePage();
    }
  }
  
  /// Build unauthorized access page
  static Widget _buildUnauthorizedPage(String route) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unauthorized'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is not available in your app version.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Route: $route',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // This will be handled by the navigator
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build 404 not found page
  static Widget _buildNotFoundPage(String route) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page does not exist.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Route: $route',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // This will be handled by the navigator
              },
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Authentication wrapper to check auth state before showing content
class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle authentication state changes
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          // Show loading screen while checking authentication
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is AuthAuthenticated) {
          // User is authenticated, go to home
          return const HomeScaffold();
        } else {
          // User is not authenticated, show welcome page
          return const WelcomePage();
        }
      },
    );
  }
}
