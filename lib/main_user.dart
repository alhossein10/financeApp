import 'package:flutter/material.dart';
import 'core/config/flavor_config.dart';
import 'injection_container.dart' as di;
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize User flavor
  FlavorConfig.initialize(AppFlavor.user);
  
  print('🔵 [MAIN_USER] App starting with User flavor');
  print('🔵 [MAIN_USER] App name: ${FlavorConfig.instance.appName}');
  print('🔵 [MAIN_USER] Cash module enabled: ${FlavorConfig.instance.enableCashModule}');
  print('🔵 [MAIN_USER] Currency module enabled: ${FlavorConfig.instance.enableCurrencyModule}');
  print('🔵 [MAIN_USER] Export module enabled: ${FlavorConfig.instance.enableExportModule}');
  
  // Initialize dependencies (includes Laravel API client and all User services)
  await di.initializeDependencies();
  
  // Restore authentication token on app start
  await di.restoreAuthToken();
  
  runApp(const app.MyApp());
}
