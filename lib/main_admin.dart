import 'package:flutter/material.dart';
import 'core/config/flavor_config.dart';
import 'injection_container.dart' as di;
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Admin flavor
  FlavorConfig.initialize(AppFlavor.admin);
  
  print('🔵 [MAIN_ADMIN] App starting with Admin flavor');
  print('🔵 [MAIN_ADMIN] App name: ${FlavorConfig.instance.appName}');
  print('🔵 [MAIN_ADMIN] Cash module enabled: ${FlavorConfig.instance.enableCashModule}');
  print('🔵 [MAIN_ADMIN] Currency module enabled: ${FlavorConfig.instance.enableCurrencyModule}');
  print('🔵 [MAIN_ADMIN] Export module enabled: ${FlavorConfig.instance.enableExportModule}');
  
  // Initialize dependencies (includes Laravel API client and all Admin services)
  await di.initializeDependencies();
  
  // Restore authentication token on app start
  await di.restoreAuthToken();
  
  runApp(const app.MyApp());
}
