import 'package:flutter/material.dart';
import 'core/config/flavor_config.dart';
import 'core/services/pocketbase_service.dart';
import 'injection_container.dart' as di;
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize user flavor
  FlavorConfig.initialize(AppFlavor.user);
  
  // Initialize PocketBase
  PocketBaseService().initialize();
  
  // Initialize dependencies
  await di.initializeDependencies();
  
  runApp(const app.MyApp());
}
