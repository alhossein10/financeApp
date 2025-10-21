/// Test script to verify Supabase sync is working
/// Run with: dart run test_supabase_sync.dart

import 'package:flutter/material.dart';
import 'lib/core/config/flavor_config.dart';
import 'lib/core/services/supabase_service.dart';
import 'lib/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Supabase Sync Test ===\n');
  
  // Initialize
  FlavorConfig.initialize(AppFlavor.user);
  print('✓ Flavor initialized: ${FlavorConfig.instance.flavor}');
  
  try {
    await SupabaseService().initialize();
    print('✓ Supabase initialized');
  } catch (e) {
    print('✗ Supabase initialization failed: $e');
    return;
  }
  
  await di.initializeDependencies();
  print('✓ Dependencies initialized\n');
  
  final supabaseService = di.sl<SupabaseService>();
  
  // Test 1: Check Supabase connection
  print('Test 1: Checking Supabase connection...');
  try {
    final isAuth = supabaseService.isAuthenticated;
    print('  Current auth status: $isAuth');
    if (isAuth) {
      print('  Current user: ${supabaseService.currentUserEmail}');
    }
    print('✓ Connection OK\n');
  } catch (e) {
    print('✗ Connection failed: $e\n');
  }
  
  // Test 2: Test registration (with test user)
  print('Test 2: Testing registration...');
  final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
  final testPassword = 'Test123456!';
  final testUsername = 'testuser_${DateTime.now().millisecondsSinceEpoch}';
  
  try {
    print('  Registering: $testEmail');
    final response = await supabaseService.signUp(
      email: testEmail,
      password: testPassword,
      username: testUsername,
    );
    
    if (response.user != null) {
      print('✓ Registration successful!');
      print('  User ID: ${response.user!.id}');
      print('  Email: ${response.user!.email}');
      
      // Check if profile was created
      final profile = await supabaseService.getUserProfile(response.user!.id);
      if (profile != null) {
        print('✓ User profile created');
        print('  Username: ${profile['username']}');
        print('  Role: ${profile['role']}');
      } else {
        print('✗ User profile not found');
      }
    } else {
      print('✗ Registration returned null user');
    }
  } catch (e) {
    print('✗ Registration failed: $e');
    print('  This might be expected if:');
    print('  - Email already exists');
    print('  - Supabase credentials are incorrect');
    print('  - Network is unavailable');
  }
  
  print('\n=== Test Complete ===');
  print('\nNext steps:');
  print('1. Check Supabase dashboard > Authentication > Users');
  print('2. Check Supabase dashboard > Table Editor > user_profiles');
  print('3. Try registering in the app and adding an expense');
  print('4. Check Supabase dashboard > Table Editor > expenses');
}
