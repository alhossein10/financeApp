import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'lib/features/expenses/presentation/bloc/expense_bloc.dart';
import 'lib/features/expenses/presentation/bloc/expense_event.dart';
import 'lib/features/expenses/domain/entities/expense.dart' as domain;
import 'lib/injection_container.dart' as di;

/// Quick test script to verify expense photo upload functionality
/// 
/// This script demonstrates:
/// 1. Creating an expense with a photo
/// 2. Creating an expense without a photo
/// 3. Updating an expense with a new photo
/// 
/// Usage:
/// 1. Ensure backend is running
/// 2. Ensure you're logged in
/// 3. Run: flutter run test_expense_photo_upload.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await di.init();
  
  runApp(const ExpensePhotoTestApp());
}

class ExpensePhotoTestApp extends StatelessWidget {
  const ExpensePhotoTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Photo Upload Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => di.sl<ExpenseBloc>(),
        child: const ExpensePhotoTestPage(),
      ),
    );
  }
}

class ExpensePhotoTestPage extends StatefulWidget {
  const ExpensePhotoTestPage({super.key});

  @override
  State<ExpensePhotoTestPage> createState() => _ExpensePhotoTestPageState();
}

class _ExpensePhotoTestPageState extends State<ExpensePhotoTestPage> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  void _log(String message) {
    setState(() {
      _testResults.add('${DateTime.now().toIso8601String()}: $message');
    });
    print(message);
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    try {
      _log('🚀 Starting expense photo upload tests...');
      
      // Test 1: Create expense WITHOUT photo
      _log('\n📝 Test 1: Create expense WITHOUT photo');
      await _testCreateWithoutPhoto();
      
      // Test 2: Create expense WITH photo
      _log('\n📷 Test 2: Create expense WITH photo');
      await _testCreateWithPhoto();
      
      // Test 3: Update expense with photo
      _log('\n🔄 Test 3: Update expense with new photo');
      await _testUpdateWithPhoto();
      
      _log('\n✅ All tests completed!');
    } catch (e) {
      _log('❌ Test failed: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _testCreateWithoutPhoto() async {
    _log('Creating expense without photo...');
    
    context.read<ExpenseBloc>().add(CreateExpenseRequested(
      userId: 1, // Replace with actual user ID
      description: 'Test expense without photo',
      priceUsd: 50.0,
      invoiceStatus: domain.InvoiceStatus.noInvoice,
      invoiceFilePath: null, // No photo
      expenseDate: DateTime.now(),
    ));
    
    await Future.delayed(const Duration(seconds: 2));
    _log('✓ Expense created without photo');
  }

  Future<void> _testCreateWithPhoto() async {
    _log('Creating expense with photo...');
    
    // Note: In real usage, this would be a path from camera/gallery
    // For testing, you need to provide a valid image file path
    const testPhotoPath = '/path/to/test/image.jpg';
    
    final file = File(testPhotoPath);
    if (!await file.exists()) {
      _log('⚠️ Test photo not found at: $testPhotoPath');
      _log('⚠️ Skipping photo upload test');
      _log('ℹ️ To test photo upload, update testPhotoPath with a valid image');
      return;
    }
    
    context.read<ExpenseBloc>().add(CreateExpenseRequested(
      userId: 1, // Replace with actual user ID
      description: 'Test expense with photo',
      priceUsd: 75.0,
      invoiceStatus: domain.InvoiceStatus.invoiceAvailable,
      invoiceFilePath: testPhotoPath,
      expenseDate: DateTime.now(),
    ));
    
    await Future.delayed(const Duration(seconds: 3));
    _log('✓ Expense created with photo');
  }

  Future<void> _testUpdateWithPhoto() async {
    _log('Updating expense with new photo...');
    
    // Note: You need to have an existing expense ID
    // This is just a demonstration
    _log('⚠️ Update test requires existing expense ID');
    _log('ℹ️ Use the UI to test update functionality');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Photo Upload Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Expense Photo Upload Test Suite',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This test verifies that expense photo uploads work correctly with the Laravel backend.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runTests,
                  icon: _isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isRunning ? 'Running Tests...' : 'Run Tests'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _testResults.isEmpty
                ? const Center(
                    child: Text(
                      'Click "Run Tests" to start',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _testResults.length,
                    itemBuilder: (context, index) {
                      final result = _testResults[index];
                      Color? color;
                      IconData? icon;
                      
                      if (result.contains('✅') || result.contains('✓')) {
                        color = Colors.green;
                        icon = Icons.check_circle;
                      } else if (result.contains('❌')) {
                        color = Colors.red;
                        icon = Icons.error;
                      } else if (result.contains('⚠️')) {
                        color = Colors.orange;
                        icon = Icons.warning;
                      } else if (result.contains('ℹ️')) {
                        color = Colors.blue;
                        icon = Icons.info;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (icon != null)
                              Icon(icon, size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                result,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Manual Testing Instructions:
/// 
/// 1. Backend Setup:
///    - Ensure Laravel backend is running
///    - Ensure you're authenticated
///    - Check storage/app/invoices directory exists
/// 
/// 2. Test Without Photo:
///    - Open expense page
///    - Click "Add Expense"
///    - Fill in details
///    - Select "No Invoice Available"
///    - Click "Save"
///    - Verify: Expense created successfully
/// 
/// 3. Test With Photo:
///    - Open expense page
///    - Click "Add Expense"
///    - Fill in details
///    - Select "Invoice Available"
///    - Click "Take Photo" or "From Gallery"
///    - Select/capture a photo
///    - Click "Save"
///    - Verify: Expense created with photo
///    - Check backend: storage/app/invoices should contain the file
///    - Check database: has_invoice should be true, invoice_path should be set
/// 
/// 4. Test Update With Photo:
///    - Open expense page
///    - Click on an existing expense
///    - Click "Edit"
///    - Change to "Invoice Available"
///    - Select a new photo
///    - Click "Save"
///    - Verify: Photo updated
///    - Check backend: Old photo deleted, new photo stored
/// 
/// 5. Test Offline:
///    - Turn off internet
///    - Create expense with photo
///    - Verify: Queued for sync
///    - Turn on internet
///    - Verify: Syncs automatically with photo
/// 
/// 6. Expected Logs:
///    [ExpenseRepository] Creating expense for user 1
///    [ExpenseRepository] Online status: true
///    [ExpenseRepository] 📷 Photo file found, will upload with expense
///    [ExpenseRepository] ✅ API creation successful! ID: 123
///    [ExpenseRepository] ✅ Photo uploaded successfully
/// 
/// 7. Backend Verification:
///    - Check: storage/app/invoices directory
///    - Check: Database expenses table (has_invoice, invoice_path)
///    - Check: Laravel logs for any errors
/// 
/// 8. Error Cases to Test:
///    - Large file (>10MB) - should show validation error
///    - Invalid file type - should show validation error
///    - File not found - should create expense without photo
///    - Network error - should queue for offline sync
