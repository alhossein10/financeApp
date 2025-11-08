import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'injection_container.dart' as di;
import 'l10n/app_localizations.dart';
import 'ui/cash_inbox_page.dart';
import 'ui/user_cash_inbox_page.dart';
import 'ui/currency_tool_page.dart';
import 'ui/expense_page.dart';
import 'ui/export_page.dart';
import 'ui/superadmin_cash_page.dart';
import 'ui/superadmin_expenses_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/fund_box/presentation/bloc/fund_box_bloc.dart';
import 'features/transfers/presentation/bloc/transfer_bloc.dart';
import 'features/incoming/presentation/bloc/incoming_bloc.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';
// import 'features/admin/presentation/bloc/admin_bloc.dart'; // Removed - admin dashboard not needed
// import 'features/admin/presentation/pages/admin_dashboard_page.dart'; // Removed - admin dashboard not needed
import 'features/admin_group/presentation/bloc/admin_group_bloc.dart';
import 'features/admin_group/presentation/pages/group_management_page.dart';
import 'features/admin_group/presentation/pages/group_info_page.dart';
import 'features/admin_group/presentation/pages/join_group_page.dart';
import 'features/exchanges/presentation/bloc/exchange_bloc.dart';
import 'features/exchanges/presentation/pages/exchange_history_page.dart';
import 'features/admin/presentation/bloc/super_admin_analytics_bloc.dart';
import 'core/config/flavor_config.dart';

// This main is kept for backward compatibility
// Use main_admin.dart or main_user.dart for flavor-specific builds
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Detect flavor from build configuration
  // Default to user flavor (safer default - limited features)
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'user');
  
  if (flavor == 'admin') {
    FlavorConfig.initialize(AppFlavor.admin);
  } else {
    FlavorConfig.initialize(AppFlavor.user);
  }
  
  print('🔵 [MAIN] App starting with flavor: ${FlavorConfig.instance.flavor}');
  print('🔵 [MAIN] App name: ${FlavorConfig.instance.appName}');
  print('🔵 [MAIN] Cash module enabled: ${FlavorConfig.instance.enableCashModule}');
  
  // Initialize dependencies (includes Laravel API client)
  await di.initializeDependencies();
  
  // Restore authentication token on app start
  await di.restoreAuthToken();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: FlavorConfig.instance.appName,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: const Color(0xFF1A3631), // Dark teal background
            onPrimary: Colors.white,
            secondary: const Color(0xFFB8A170), // Light gold/beige from splash screen
            onSecondary: const Color(0xFF1A3631),
            surface: Colors.white,
            onSurface: const Color(0xFF1A3631),
            error: Colors.red,
            onError: Colors.white,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A3631), // Dark teal background
            foregroundColor: Color(0xFFB8A170), // Gold text
            elevation: 0,
          ),
          scaffoldBackgroundColor: Colors.white,
          primaryColor: const Color(0xFF1A3631),
        ),
        routes: {
          '/': (context) => const AuthenticationWrapper(),
          '/home': (context) => const HomeScaffold(),
          '/group-management': (context) => BlocProvider(
                create: (context) => di.sl<AdminGroupBloc>(),
                child: const GroupManagementPage(),
              ),
          '/group-info': (context) => BlocProvider(
                create: (context) => di.sl<AdminGroupBloc>(),
                child: const GroupInfoPage(),
              ),
          '/join-group': (context) => BlocProvider(
                create: (context) => di.sl<AdminGroupBloc>(),
                child: const JoinGroupPage(),
              ),
          '/exchange-history': (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => di.sl<ExchangeBloc>()),
                  BlocProvider(create: (context) => di.sl<AdminGroupBloc>()),
                ],
                child: const ExchangeHistoryPage(),
              ),
        },
        initialRoute: '/',
      ),
    );
  }
}

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
          // User is authenticated, go directly to home (no onboarding)
          return const HomeScaffold();
        } else {
          // User is not authenticated, show welcome page
          return const WelcomePage();
        }
      },
    );
  }
}

class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _index = 0;
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
    final isAuthenticated = authState.status == AuthStatus.authenticated || authState is AuthAuthenticated;
    final isAdmin = isAuthenticated && authState.user?.isAdmin == true;
    
    // Only update if admin state actually changed
    if (_lastIsAdminState != isAdmin) {
      print('🔵 [HomeScaffold] Admin state changed: $isAdmin, user: ${authState.user?.email}');
      if (mounted) {
        setState(() {
          _lastIsAdminState = isAdmin;
          _cachedPages = null; // Clear cache to rebuild pages
          _index = 0; // Reset to first page
        });
      }
    }
  }

  List<Widget> _buildPages(BuildContext context) {
    // Get current user from auth state - use read to avoid rebuild loops
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated || authState is AuthAuthenticated;
    final isAdmin = isAuthenticated && authState.user?.isAdmin == true;
    
    // Initialize last admin state if not set
    _lastIsAdminState ??= isAdmin;
    
    // Cache pages to prevent recreation on navigation
    // This preserves state including loaded expenses and photos
    if (_cachedPages != null) {
      return _cachedPages!;
    }
    
    final pages = <Widget>[];
    
    // SuperAdmin Navigation: Group Management, Cash, Expenses, Profile (via AppBar)
    if (_flavorConfig.isSuperAdmin) {
      // 1. Group Management
      pages.add(BlocProvider(
        create: (context) => di.sl<AdminGroupBloc>(),
        child: const GroupManagementPage(),
      ));
      
      // 2. SuperAdmin Cash Page (unified cash page with outgoing transfers only)
      // Note: SuperAdmin does not use FundBoxBloc - no fund-box functionality
      if (_flavorConfig.enableSuperAdminCashPage) {
        pages.add(MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => di.sl<TransferBloc>()),
            BlocProvider(create: (context) => di.sl<AdminGroupBloc>()),
          ],
          child: const SuperAdminCashPage(),
        ));
      }
      
      // 3. SuperAdmin Expenses Page (aggregated view by admin group)
      if (_flavorConfig.enableSuperAdminExpensesPage) {
        pages.add(BlocProvider(
          create: (context) => di.sl<SuperAdminAnalyticsBloc>(),
          child: const SuperAdminExpensesPage(),
        ));
      }
      
      // Note: Profile is accessed via AppBar action button, not bottom navigation
      // Currency Exchange, Export, Exchange History, and User Cash Inbox are NOT included for SuperAdmin
    }
    // Admin Navigation
    else if (_flavorConfig.isAdmin) {
      // Group Management (admin only)
      pages.add(BlocProvider(
        create: (context) => di.sl<AdminGroupBloc>(),
        child: const GroupManagementPage(),
      ));
      
      if (_flavorConfig.enableCashModule) {
        pages.add(const CashInboxPage());
      }
      
      if (_flavorConfig.enableCurrencyModule) {
        pages.add(BlocProvider(
          create: (context) => di.sl<ExchangeBloc>(),
          child: const CurrencyToolPage(),
        ));
      }
      
      if (_flavorConfig.enableExpensesModule) {
        pages.add(const ExpensePage());
      }
      
      if (_flavorConfig.enableExportModule) {
        pages.add(BlocProvider(
          create: (context) => di.sl<ExpenseBloc>(),
          child: const ExportPage(),
        ));
      }
    }
    // User Navigation
    else {
      // User Cash Inbox Page (first page for user flavor) - Shows fundbox and incoming transfers
      pages.add(MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<ExchangeBloc>()),
          BlocProvider(create: (context) => di.sl<TransferBloc>()),
        ],
        child: const UserCashInboxPage(),
      ));
      
      if (_flavorConfig.enableCurrencyModule) {
        pages.add(BlocProvider(
          create: (context) => di.sl<ExchangeBloc>(),
          child: const CurrencyToolPage(),
        ));
      }
      
      if (_flavorConfig.enableExpensesModule) {
        pages.add(const ExpensePage());
      }
      
      if (_flavorConfig.enableExportModule) {
        pages.add(BlocProvider(
          create: (context) => di.sl<ExpenseBloc>(),
          child: const ExportPage(),
        ));
      }
      
      // Exchange History (available to user flavor only)
      pages.add(MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => di.sl<ExchangeBloc>()),
          BlocProvider(create: (context) => di.sl<AdminGroupBloc>()),
        ],
        child: const ExchangeHistoryPage(),
      ));
    }
    
    _cachedPages = pages;
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Build pages first to ensure cache is updated
    final pages = _buildPages(context);
    
    // Ensure index is within bounds after pages rebuild
    if (_index >= pages.length) {
      _index = 0;
    }
    
    final destinations = <NavigationDestination>[];
    
    // SuperAdmin Navigation Destinations: Groups, Wallet (Cash), Receipt (Expenses)
    if (_flavorConfig.isSuperAdmin) {
      // 1. Group Management
      destinations.add(NavigationDestination(
        icon: const Icon(Icons.group_outlined),
        selectedIcon: const Icon(Icons.group),
        label: l10n.translate('admin_group.group_management') ?? 'Groups',
      ));
      
      // 2. Cash (SuperAdmin Cash Page)
      if (_flavorConfig.enableSuperAdminCashPage) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet),
          label: l10n.translate('cash'),
        ));
      }
      
      // 3. Expenses (SuperAdmin Expenses Page)
      if (_flavorConfig.enableSuperAdminExpensesPage) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n.translate('expenses'),
        ));
      }
      
      // Note: Profile is accessed via AppBar action button (person icon)
      // Currency Exchange, Export, and Exchange History are NOT shown for SuperAdmin
    }
    // Admin Navigation Destinations
    else if (_flavorConfig.isAdmin) {
      // Group Management (admin only)
      destinations.add(NavigationDestination(
        icon: const Icon(Icons.group_outlined),
        selectedIcon: const Icon(Icons.group),
        label: l10n.translate('admin_group.group_management') ?? 'Groups',
      ));
      
      if (_flavorConfig.enableCashModule) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet),
          label: l10n.translate('cash'),
        ));
      }
      
      if (_flavorConfig.enableCurrencyModule) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.currency_exchange_outlined),
          selectedIcon: const Icon(Icons.currency_exchange),
          label: l10n.translate('convert'),
        ));
      }
      
      if (_flavorConfig.enableExpensesModule) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n.translate('expenses'),
        ));
      }
      
      if (_flavorConfig.enableExportModule) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.ios_share_outlined),
          selectedIcon: const Icon(Icons.ios_share),
          label: l10n.translate('export'),
        ));
      }
    }
    // User Navigation Destinations
    else {
      // User Cash Inbox Page (first page for user flavor)
      destinations.add(NavigationDestination(
        icon: const Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: const Icon(Icons.account_balance_wallet),
        label: l10n.translate('cash'),
      ));
      
      if (_flavorConfig.enableCurrencyModule) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.currency_exchange_outlined),
          selectedIcon: const Icon(Icons.currency_exchange),
          label: l10n.translate('convert'),
        ));
      }
      
      if (_flavorConfig.enableExpensesModule) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n.translate('expenses'),
        ));
      }
      
      if (_flavorConfig.enableExportModule) {
        destinations.add(NavigationDestination(
          icon: const Icon(Icons.ios_share_outlined),
          selectedIcon: const Icon(Icons.ios_share),
          label: l10n.translate('export'),
        ));
      }
      
      // Exchange History (available to user flavor only)
      destinations.add(NavigationDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history),
        label: l10n.translate('exchange_history'),
      ));
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
          title: Text(_flavorConfig.appName),
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
          index: _index,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: destinations,
          onDestinationSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
