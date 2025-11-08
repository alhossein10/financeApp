/// Supabase Integration Test
/// 
/// This file tests the complete Supabase integration
/// Run this to verify your setup is working correctly

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/core/config/flavor_config.dart';
import 'lib/core/services/supabase_service.dart';
import 'lib/injection_container.dart' as di;

void main() {
  group('Supabase Integration Tests', () {
    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize user flavor for testing
      FlavorConfig.initialize(AppFlavor.user);
      
      // Initialize Supabase
      await SupabaseService().initialize();
      
      // Initialize dependencies
      await di.initializeDependencies();
    });

    test('Supabase Service Initialization', () async {
      final supabaseService = di.sl<SupabaseService>();
      
      // Test that Supabase is initialized
      expect(supabaseService.isInitialized, true);
      
      // Test connection
      final isConnected = await supabaseService.testConnection();
      expect(isConnected, true);
      
      print('✅ Supabase Service initialized successfully');
    });

    test('Authentication Flow', () async {
      final supabaseService = di.sl<SupabaseService>();
      
      // Test user registration
      try {
        final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final testPassword = 'TestPassword123!';
        
        print('🧪 Testing user registration...');
        final user = await supabaseService.signUp(
          email: testEmail,
          password: testPassword,
          username: 'testuser',
        );
        
        expect(user, isNotNull);
        print('✅ User registration successful');
        
        // Test user login
        print('🧪 Testing user login...');
        await supabaseService.signOut(); // Sign out first
        
        final loginUser = await supabaseService.signIn(
          email: testEmail,
          password: testPassword,
        );
        
        expect(loginUser, isNotNull);
        print('✅ User login successful');
        
        // Test getting current user
        final currentUser = supabaseService.getCurrentUser();
        expect(currentUser, isNotNull);
        expect(currentUser?.email, testEmail);
        print('✅ Get current user successful');
        
        // Clean up - delete test user
        await supabaseService.signOut();
        
      } catch (e) {
        print('❌ Authentication test failed: $e');
        rethrow;
      }
    });

    test('Database Operations', () async {
      final supabaseService = di.sl<SupabaseService>();
      
      // First, create and sign in a test user
      final testEmail = 'dbtest_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'TestPassword123!';
      
      await supabaseService.signUp(
        email: testEmail,
        password: testPassword,
        username: 'dbtestuser',
      );
      
      try {
        print('🧪 Testing database operations...');
        
        // Test creating an expense
        final expenseData = {
          'description': 'Test Expense',
          'price_usd': 10.50,
          'price_syp': 25000.0,
          'price_try': 300.0,
          'expense_date': DateTime.now().toIso8601String(),
          'local_expense_id': 1,
        };
        
        final expense = await supabaseService.createExpense(expenseData);
        expect(expense, isNotNull);
        print('✅ Expense creation successful');
        
        // Test fetching expenses
        final expenses = await supabaseService.getExpenses();
        expect(expenses, isNotEmpty);
        expect(expenses.first['description'], 'Test Expense');
        print('✅ Expense fetching successful');
        
        // Test updating expense
        final updatedExpense = await supabaseService.updateExpense(
          expense['id'],
          {'description': 'Updated Test Expense'},
        );
        expect(updatedExpense['description'], 'Updated Test Expense');
        print('✅ Expense update successful');
        
      } catch (e) {
        print('❌ Database operations test failed: $e');
        rethrow;
      } finally {
        await supabaseService.signOut();
      }
    });

    test('File Upload Operations', () async {
      final supabaseService = di.sl<SupabaseService>();
      
      // Create and sign in a test user
      final testEmail = 'filetest_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'TestPassword123!';
      
      await supabaseService.signUp(
        email: testEmail,
        password: testPassword,
        username: 'filetestuser',
      );
      
      try {
        print('🧪 Testing file upload operations...');
        
        // Create a test file (simulate image data)
        final testFileData = List<int>.generate(1000, (i) => i % 256);
        final fileName = 'test_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Test file upload
        final fileUrl = await supabaseService.uploadFile(
          bucketName: 'invoice-images',
          fileName: fileName,
          fileData: testFileData,
        );
        
        expect(fileUrl, isNotNull);
        expect(fileUrl, contains(fileName));
        print('✅ File upload successful');
        
        // Test file download
        final downloadedData = await supabaseService.downloadFile(
          bucketName: 'invoice-images',
          fileName: fileName,
        );
        
        expect(downloadedData, isNotNull);
        expect(downloadedData.length, testFileData.length);
        print('✅ File download successful');
        
      } catch (e) {
        print('❌ File operations test failed: $e');
        rethrow;
      } finally {
        await supabaseService.signOut();
      }
    });

    test('Real-time Sync Test', () async {
      final supabaseService = di.sl<SupabaseService>();
      
      // Create and sign in a test user
      final testEmail = 'synctest_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'TestPassword123!';
      
      await supabaseService.signUp(
        email: testEmail,
        password: testPassword,
        username: 'synctestuser',
      );
      
      try {
        print('🧪 Testing real-time sync...');
        
        bool updateReceived = false;
        
        // Subscribe to real-time updates
        final subscription = supabaseService.subscribeToExpenses((payload) {
          print('📡 Real-time update received: ${payload.eventType}');
          updateReceived = true;
        });
        
        // Wait a moment for subscription to be established
        await Future.delayed(const Duration(seconds: 2));
        
        // Create an expense to trigger real-time update
        await supabaseService.createExpense({
          'description': 'Real-time Test Expense',
          'price_usd': 5.00,
          'expense_date': DateTime.now().toIso8601String(),
          'local_expense_id': 999,
        });
        
        // Wait for real-time update
        await Future.delayed(const Duration(seconds: 3));
        
        // Clean up subscription
        subscription.unsubscribe();
        
        expect(updateReceived, true);
        print('✅ Real-time sync successful');
        
      } catch (e) {
        print('❌ Real-time sync test failed: $e');
        rethrow;
      } finally {
        await supabaseService.signOut();
      }
    });
  });
}

/// Helper function to run integration tests manually
Future<void> runSupabaseIntegrationTests() async {
  print('🚀 Starting Supabase Integration Tests...\n');
  
  try {
    // Initialize
    WidgetsFlutterBinding.ensureInitialized();
    FlavorConfig.initialize(AppFlavor.user);
    await SupabaseService().initialize();
    await di.initializeDependencies();
    
    final supabaseService = di.sl<SupabaseService>();
    
    // Test 1: Service Initialization
    print('1️⃣ Testing Service Initialization...');
    assert(supabaseService.isInitialized, 'Supabase not initialized');
    final isConnected = await supabaseService.testConnection();
    assert(isConnected, 'Supabase connection failed');
    print('✅ Service initialization passed\n');
    
    // Test 2: Authentication
    print('2️⃣ Testing Authentication...');
    final testEmail = 'integration_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final testPassword = 'TestPassword123!';
    
    // Sign up
    final user = await supabaseService.signUp(
      email: testEmail,
      password: testPassword,
      username: 'integrationtest',
    );
    assert(user != null, 'User registration failed');
    
    // Sign out and sign in
    await supabaseService.signOut();
    final loginUser = await supabaseService.signIn(
      email: testEmail,
      password: testPassword,
    );
    assert(loginUser != null, 'User login failed');
    print('✅ Authentication passed\n');
    
    // Test 3: Database Operations
    print('3️⃣ Testing Database Operations...');
    final expense = await supabaseService.createExpense({
      'description': 'Integration Test Expense',
      'price_usd': 15.75,
      'expense_date': DateTime.now().toIso8601String(),
      'local_expense_id': 1001,
    });
    assert(expense != null, 'Expense creation failed');
    
    final expenses = await supabaseService.getExpenses();
    assert(expenses.isNotEmpty, 'Expense fetching failed');
    print('✅ Database operations passed\n');
    
    print('🎉 All Supabase Integration Tests Passed!\n');
    print('Your Supabase setup is working correctly! 🚀');
    
  } catch (e, stackTrace) {
    print('❌ Integration test failed: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}