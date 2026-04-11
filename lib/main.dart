import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'injection_container.dart' as di;
import 'l10n/app_localizations.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/fund_box/presentation/bloc/fund_box_bloc.dart';
import 'features/exchanges/presentation/bloc/exchange_bloc.dart';
import 'features/admin_group/presentation/bloc/admin_group_bloc.dart';
import 'core/config/flavor_config.dart';
import 'core/routing/app_router.dart';
import 'core/bloc/language_bloc.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => di.sl<LanguageBloc>()..add(LanguageLoadRequested()),
        ),
        BlocProvider(
          create: (context) => di.sl<FundBoxBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<ExchangeBloc>(),
        ),
        BlocProvider(
          create: (context) => di.sl<AdminGroupBloc>(),
        ),
      ],
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, languageState) {
          Locale currentLocale = const Locale('ar'); // default
          
          if (languageState is LanguageLoaded) {
            currentLocale = languageState.locale;
          }
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: FlavorConfig.instance.appName,
            locale: currentLocale,
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
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: AppRouter.initialRoute,
          );
        },
      ),
    );
  }
}

