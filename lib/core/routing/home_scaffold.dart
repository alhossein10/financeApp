import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../injection_container.dart' as di;
import '../config/flavor_config.dart';
import '../widgets/app_navigation_bar.dart';
import '../widgets/app_logo.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/fund_box/presentation/bloc/fund_box_bloc.dart';
import '../../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../../features/incoming/presentation/bloc/incoming_bloc.dart';
import '../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../features/admin_group/presentation/bloc/admin_group_bloc.dart';
import '../../features/exchanges/presentation/bloc/exchange_bloc.dart';
import '../../features/admin/presentation/bloc/super_admin_analytics_bloc.dart';
import '../../features/admin_group/presentation/pages/group_management_page.dart';
import '../../ui/cash_inbox_page.dart';
import '../../ui/user_cash_inbox_page.dart';
import '../../ui/currency_tool_page.dart';
import '../../ui/expense_page.dart';
import '../../ui/superadmin_cash_page.dart';
import '../../ui/superadmin_expenses_page.dart';
import '../../features/admin/presentation/pages/admin_export_page.dart';
import '../../features/user/presentation/pages/user_export_page.dart';
import '../../features/superadmin/presentation/pages/superadmin_analytics_page.dart';

/// Home scaffold with flavor-specific navigation
/// 
/// This widget provides the main app scaffold with:
/// - AppBar with logo and profile button
/// - IndexedStack for page navigation
/// - AppNavigationBar for bottom navigation
/// 
/// The pages and navigation are determined by the current flavor:
/// - SuperAdmin: Group Management, Cash, Transfers, Analytics
/// - Admin: Group Management, Cash, Exchange, Expenses, Export
/// - User: Home (Cash), Exchange, Expenses, Export
class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _selectedIndex = 0;
  final _flavorConfig = FlavorConfig.instance;
  List<Widget>? _cachedPages;
  bool? _lastIsAdminState;

  @override
  void initState() {
    super.initState();
    // Initialize admin state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAdminState();
    });
  }

  void _updateAdminState() {
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated || 
                           authState is AuthAuthenticated;
    final isAdmin = isAuthenticated && authState.user?.isAdmin == true;
    
    // Only update if admin state actually changed
    if (_lastIsAdminState != isAdmin) {
      print('🔵 [HomeScaffold] Admin state changed: $isAdmin, user: ${authState.user?.email}');
      if (mounted) {
        setState(() {
          _lastIsAdminState = isAdmin;
          _cachedPages = null; // Clear cache to rebuild pages
          _selectedIndex = 0; // Reset to first page
        });
      }
    }
  }

  List<Widget> _buildPages(BuildContext context) {
    // Get current user from auth state - use read to avoid rebuild loops
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated || 
                           authState is AuthAuthenticated;
    final isAdmin = isAuthenticated && authState.user?.isAdmin == true;
    
    // Initialize last admin state if not set
    _lastIsAdminState ??= isAdmin;
    
    // Cache pages to prevent recreation on navigation
    // This preserves state including loaded expenses and photos
    if (_cachedPages != null) {
      return _cachedPages!;
    }
    
    final pages = <Widget>[];
    final destinations = _flavorConfig.getNavigationDestinations();
    
    // Build pages based on navigation destinations
    for (final dest in destinations) {
      pages.add(_buildPageForRoute(dest.route));
    }
    
    _cachedPages = pages;
    return pages;
  }

  Widget _buildPageForRoute(String route) {
    switch (route) {
      case '/group-management':
        return BlocProvider(
          create: (context) => di.sl<AdminGroupBloc>(),
          child: const GroupManagementPage(),
        );
        
      case '/cash':
        return _buildCashPage();
        
      case '/home':
        return _buildHomePage();
        
      case '/exchange':
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => di.sl<ExchangeBloc>()),
            BlocProvider(create: (context) => di.sl<FundBoxBloc>()),
          ],
          child: const CurrencyToolPage(),
        );
        
      case '/expenses':
        return _buildExpensesPage();
        
      case '/export':
        // Use flavor-specific export pages (frontend-only, no API)
        if (FlavorConfig.instance.flavor.isAdmin) {
          return const AdminExportPage();
        } else if (FlavorConfig.instance.flavor.isUser) {
          return const UserExportPage();
        } else {
          // SuperAdmin doesn't have export page yet
          return const Center(child: Text('Export not available for SuperAdmin'));
        }
        
      case '/transfers':
        // SuperAdmin transfers page - handled separately in routing
        return const Center(child: Text('Transfers'));
        
      case '/analytics':
        // SuperAdmin analytics page
        return const SuperAdminAnalyticsPage();
        
      default:
        return Center(child: Text('Unknown route: $route'));
    }
  }

  Widget _buildCashPage() {
    if (_flavorConfig.isSuperAdmin) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<FundBoxBloc>()),
          BlocProvider(create: (context) => di.sl<TransferBloc>()),
          BlocProvider(create: (context) => di.sl<IncomingBloc>()),
          BlocProvider(create: (context) => di.sl<AdminGroupBloc>()),
        ],
        child: const SuperAdminCashPage(),
      );
    } else if (_flavorConfig.isAdmin) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<AdminGroupBloc>()),
        ],
        child: const CashInboxPage(),
      );
    } else {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<FundBoxBloc>()),
          BlocProvider(create: (context) => di.sl<IncomingBloc>()),
        ],
        child: const UserCashInboxPage(),
      );
    }
  }

  Widget _buildHomePage() {
    // User home page (same as cash page for user)
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<FundBoxBloc>()),
        BlocProvider(create: (context) => di.sl<IncomingBloc>()),
      ],
      child: const UserCashInboxPage(),
    );
  }

  Widget _buildExpensesPage() {
    if (_flavorConfig.isSuperAdmin) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<SuperAdminAnalyticsBloc>()),
          BlocProvider(create: (context) => di.sl<AdminGroupBloc>()),
        ],
        child: const SuperAdminExpensesPage(),
      );
    } else if (_flavorConfig.isAdmin) {
      return BlocProvider(
        create: (context) => di.sl<AdminGroupBloc>(),
        child: const ExpensePage(),
      );
    } else {
      return const ExpensePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build pages first to ensure cache is updated
    final pages = _buildPages(context);
    
    // Ensure index is within bounds after pages rebuild
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }
    
    return MultiBlocProvider(
      providers: [
        BlocProvider<FundBoxBloc>(
          create: (context) => di.sl<FundBoxBloc>(),
        ),
        BlocProvider<TransferBloc>(
          create: (context) => di.sl<TransferBloc>(),
        ),
        BlocProvider<IncomingBloc>(
          create: (context) => di.sl<IncomingBloc>(),
        ),
        BlocProvider<ExpenseBloc>(
          create: (context) => di.sl<ExpenseBloc>(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: AppLogo(
            appName: _getAppNameForFlavor(_flavorConfig),
          ),
          automaticallyImplyLeading: false, // Remove back arrow
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => di.sl<ProfileBloc>(),
                      child: const ProfilePage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: AppNavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
        ),
      ),
    );
  }

  /// Get app name based on flavor
  /// Returns:
  /// - "الإدارة المالية" for user flavor
  /// - "الإدارة المالية (أدمن)" for admin flavor
  /// - "الإدارة المالية (سوبر)" for superAdmin flavor
  String _getAppNameForFlavor(FlavorConfig config) {
    if (config.isSuperAdmin) {
      return 'الإدارة المالية (سوبر)';
    } else if (config.isAdmin) {
      return 'الإدارة المالية (أدمن)';
    } else {
      return 'الإدارة المالية';
    }
  }
}
