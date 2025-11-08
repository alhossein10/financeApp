import 'package:flutter/material.dart';
import 'injection_container.dart' as di;
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/profile/domain/usecases/get_user_profile_usecase.dart';
import 'features/expenses/domain/usecases/create_expense_usecase.dart';
import 'features/expenses/domain/entities/expense.dart';

/// Simple test script to diagnose profile and expense issues
/// Run with: flutter run test_profile_and_expenses.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Profile and Expense Diagnostic Test ===\n');
  
  // Initialize dependencies
  print('1. Initializing dependencies...');
  await di.initializeDependencies();
  print('   ✅ Dependencies initialized\n');
  
  // Test 1: Check if services are registered
  print('2. Checking service registration...');
  try {
    final authRepo = di.sl<AuthRepository>();
    print('   ✅ AuthRepository registered');
    
    final profileUseCase = di.sl<GetUserProfileUseCase>();
    print('   ✅ GetUserProfileUseCase registered');
    
    final expenseUseCase = di.sl<CreateExpenseUseCase>();
    print('   ✅ CreateExpenseUseCase registered');
  } catch (e) {
    print('   ❌ Service registration error: $e');
    return;
  }
  print('');
  
  // Test 2: Check current user
  print('3. Checking current user...');
  try {
    final authRepo = di.sl<AuthRepository>();
    final userResult = await authRepo.getCurrentUser();
    
    userResult.fold(
      (failure) {
        print('   ❌ No user logged in: ${failure.message}');
        print('   ℹ️  Please login first before running this test');
      },
      (user) {
        print('   ✅ User logged in:');
        print('      - ID: ${user.id}');
        print('      - Username: ${user.username}');
        print('      - Email: ${user.email}');
        print('      - Role: ${user.role}');
      },
    );
  } catch (e) {
    print('   ❌ Error checking user: $e');
  }
  print('');
  
  // Test 3: Try to load profile
  print('4. Testing profile loading...');
  try {
    final profileUseCase = di.sl<GetUserProfileUseCase>();
    final result = await profileUseCase();
    
    result.fold(
      (failure) {
        print('   ❌ Profile load failed: ${failure.message}');
        print('   ℹ️  This is the issue causing profile page crash');
      },
      (profileData) {
        print('   ✅ Profile loaded successfully:');
        print('      - User: ${profileData.user.username}');
        print('      - Total Expenses: ${profileData.statistics.totalExpenses}');
        print('      - Total Incoming: ${profileData.statistics.totalIncoming}');
        print('      - Total Transfers: ${profileData.statistics.totalTransfers}');
        print('      - Pending: ${profileData.statistics.pendingExpenses}');
      },
    );
  } catch (e) {
    print('   ❌ Unexpected error: $e');
  }
  print('');
  
  // Test 4: Try to create a test expense
  print('5. Testing expense creation...');
  try {
    final authRepo = di.sl<AuthRepository>();
    final userResult = await authRepo.getCurrentUser();
    
    if (userResult.isRight()) {
      final user = userResult.getOrElse(() => throw Exception());
      final expenseUseCase = di.sl<CreateExpenseUseCase>();
      
      final params = CreateExpenseParams(
        userId: user.id,
        description: 'Test Expense from Diagnostic',
        priceUsd: 10.0,
        invoiceStatus: InvoiceStatus.noInvoice,
        expenseDate: DateTime.now(),
      );
      
      print('   Creating test expense...');
      final result = await expenseUseCase(params);
      
      result.fold(
        (failure) {
          print('   ❌ Expense creation failed: ${failure.message}');
          print('   ℹ️  This is why expenses don\'t save');
        },
        (expense) {
          print('   ✅ Expense created successfully:');
          print('      - ID: ${expense.id}');
          print('      - Description: ${expense.description}');
          print('      - Amount: \$${expense.priceUsd}');
          print('      - Sync Status: ${expense.syncStatus}');
        },
      );
    } else {
      print('   ⚠️  Skipped - no user logged in');
    }
  } catch (e) {
    print('   ❌ Unexpected error: $e');
  }
  print('');
  
  print('=== Diagnostic Test Complete ===\n');
  print('Summary:');
  print('- If profile loading failed, check backend /profile and /profile/statistics endpoints');
  print('- If expense creation failed, check backend /expenses POST endpoint');
  print('- Check console logs above for specific error messages');
  print('- Make sure Laravel backend is running on http://192.168.137.1:8000');
}
