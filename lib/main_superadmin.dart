import 'package:flutter/material.dart';
import 'core/config/flavor_config.dart';
import 'injection_container.dart' as di;
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SuperAdmin flavor
  FlavorConfig.initialize(AppFlavor.superAdmin);
  
  print('🔵 [MAIN_SUPERADMIN] App starting with SuperAdmin flavor');
  print('🔵 [MAIN_SUPERADMIN] App name: ${FlavorConfig.instance.appName}');
  print('🔵 [MAIN_SUPERADMIN] SuperAdmin Cash Page enabled: ${FlavorConfig.instance.enableSuperAdminCashPage}');
  print('🔵 [MAIN_SUPERADMIN] SuperAdmin Expenses Page enabled: ${FlavorConfig.instance.enableSuperAdminExpensesPage}');
  print('🔵 [MAIN_SUPERADMIN] Currency Module enabled: ${FlavorConfig.instance.enableCurrencyModule}');
  print('🔵 [MAIN_SUPERADMIN] Export Module enabled: ${FlavorConfig.instance.enableExportModule}');
  
  // Initialize dependencies (includes Laravel API client and all SuperAdmin services)
  await di.initializeDependencies();
  
  // Restore authentication token on app start
  await di.restoreAuthToken();
  
  runApp(const app.MyApp());
}

