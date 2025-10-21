import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'injection_container.dart' as di;
import 'l10n/app_localizations.dart';
import 'ui/cash_inbox_page.dart';
import 'ui/currency_tool_page.dart';
import 'ui/expense_page.dart';
import 'ui/export_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/fund_box/presentation/bloc/fund_box_bloc.dart';
import 'features/transfers/presentation/bloc/transfer_bloc.dart';
import 'features/incoming/presentation/bloc/incoming_bloc.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'core/services/onboarding_service.dart';
import 'core/services/supabase_service.dart';
import 'core/config/flavor_config.dart';

// This main is kept for backward compatibility
// Use main_admin.dart or main_user.dart for flavor-specific builds
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Default to admin flavor if not initialized
  try {
    FlavorConfig.instance;
  } catch (e) {
    FlavorConfig.initialize(AppFlavor.admin);
  }
  
  // Initialize Supabase
  await SupabaseService().initialize();
  
  await di.initializeDependencies();
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        routes: {
          '/': (context) => const AuthenticationWrapper(),
          '/home': (context) => const HomeScaffold(),
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
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final onboardingService = di.sl<OnboardingService>();
    final completed = await onboardingService.isOnboardingCompleted();
    setState(() {
      _onboardingCompleted = completed;
    });
  }

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
        if (state is AuthLoading || state is AuthInitial || _onboardingCompleted == null) {
          // Show loading screen while checking authentication and onboarding
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is AuthAuthenticated) {
          // User is authenticated, check onboarding
          if (!_onboardingCompleted!) {
            return const OnboardingPage();
          }
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

  List<Widget> get _pages {
    final pages = <Widget>[];
    
    // Admin dashboard (admin only)
    if (_flavorConfig.isAdmin) {
      pages.add(BlocProvider(
        create: (context) => di.sl<AdminBloc>(),
        child: const AdminDashboardPage(),
      ));
    }
    
    if (_flavorConfig.enableCashModule) {
      pages.add(const CashInboxPage());
    }
    
    if (_flavorConfig.enableCurrencyModule) {
      pages.add(const CurrencyToolPage());
    }
    
    if (_flavorConfig.enableExpensesModule) {
      pages.add(const ExpensePage());
    }
    
    if (_flavorConfig.enableExportModule) {
      pages.add(const ExportPage());
    }
    
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    final destinations = <NavigationDestination>[];
    
    // Admin dashboard (admin only)
    if (_flavorConfig.isAdmin) {
      destinations.add(NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.translate('admin_dashboard'),
      ));
    }
    
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
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: destinations,
          onDestinationSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
