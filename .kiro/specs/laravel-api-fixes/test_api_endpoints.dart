/// Manual API Testing Script
/// 
/// This script helps verify that all API endpoints are working correctly
/// Run this script to test the Laravel API integration
/// 
/// Usage: dart run .kiro/specs/laravel-api-fixes/test_api_endpoints.dart

import 'dart:io';
import 'dart:convert';

const String baseUrl = 'http://localhost:8000/api/v1';
String? authToken;

void main() async {
  print('='.repeat(80));
  print('Laravel API Integration Testing Script');
  print('='.repeat(80));
  print('');

  try {
    // Test 1: Authentication
    await testAuthentication();
    
    if (authToken == null) {
      print('❌ Authentication failed. Cannot proceed with other tests.');
      return;
    }

    // Test 2: Transfers
    await testTransfers();

    // Test 3: Incoming
    await testIncoming();

    // Test 4: Expenses
    await testExpenses();

    // Test 5: Fund Box (Admin only)
    await testFundBox();

    // Test 6: Admin Dashboard (Admin only)
    await testAdminDashboard();

    // Test 7: Profile
    await testProfile();

    // Test 8: Export
    await testExport();

    // Test 9: Audit Logs (Admin only)
    await testAuditLogs();

    print('');
    print('='.repeat(80));
    print('Testing Complete!');
    print('='.repeat(80));
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}

Future<void> testAuthentication() async {
  print('\n📝 Testing Authentication...');
  print('-'.repeat(80));

  try {
    // Test login
    final loginData = {
      'email': 'admin@test.com',
      'password': 'password',
    };

    final response = await makeRequest(
      'POST',
      '/auth/login',
      body: loginData,
      requiresAuth: false,
    );

    if (response['success'] == true && response['data']?['token'] != null) {
      authToken = response['data']['token'];
      print('✅ Login successful');
      print('   Token: ${authToken!.substring(0, 20)}...');
      print('   User: ${response['data']['user']['name']}');
      print('   Role: ${response['data']['user']['role']}');
    } else {
      print('❌ Login failed: ${response['message']}');
    }
  } catch (e) {
    print('❌ Authentication test failed: $e');
  }
}

Future<void> testTransfers() async {
  print('\n📝 Testing Transfers...');
  print('-'.repeat(80));

  try {
    // Create transfer
    final transferData = {
      'amount': 100.50,
      'from_account': 'Savings Account',
      'to_account': 'Checking Account',
      'description': 'Test transfer',
      'date': '2024-01-15',
    };

    final createResponse = await makeRequest(
      'POST',
      '/transfers',
      body: transferData,
    );

    if (createResponse['success'] == true) {
      print('✅ Create transfer successful');
      final transfer = createResponse['data'];
      print('   ID: ${transfer['id']}');
      print('   Amount: ${transfer['amount']}');
      print('   From: ${transfer['from_account']}');
      print('   To: ${transfer['to_account']}');
      print('   Date: ${transfer['date']}');

      // Verify field mappings
      if (transfer['from_account'] == transferData['from_account'] &&
          transfer['to_account'] == transferData['to_account']) {
        print('✅ Field mappings correct');
      } else {
        print('❌ Field mappings incorrect!');
      }

      // List transfers
      final listResponse = await makeRequest('GET', '/transfers?per_page=15');
      if (listResponse['success'] == true) {
        print('✅ List transfers successful');
        print('   Total: ${listResponse['data']['total']}');
        print('   Per Page: ${listResponse['data']['per_page']}');
      }
    } else {
      print('❌ Create transfer failed: ${createResponse['message']}');
    }
  } catch (e) {
    print('❌ Transfer test failed: $e');
  }
}

Future<void> testIncoming() async {
  print('\n📝 Testing Incoming (Income)...');
  print('-'.repeat(80));

  try {
    // Create incoming
    final incomingData = {
      'amount': 500.00,
      'source': 'Salary',
      'payment_method': 'bank_transfer',
      'description': 'Monthly salary',
      'date': '2024-01-15',
    };

    final createResponse = await makeRequest(
      'POST',
      '/incoming',
      body: incomingData,
    );

    if (createResponse['success'] == true) {
      print('✅ Create incoming successful');
      final incoming = createResponse['data'];
      print('   ID: ${incoming['id']}');
      print('   Amount: ${incoming['amount']}');
      print('   Source: ${incoming['source']}');
      print('   Payment Method: ${incoming['payment_method']}');
      print('   Date: ${incoming['date']}');

      // Verify field mappings
      if (incoming['source'] == incomingData['source'] &&
          incoming['payment_method'] == incomingData['payment_method']) {
        print('✅ Field mappings correct');
      } else {
        print('❌ Field mappings incorrect!');
      }

      // Test payment methods
      for (final method in ['cash', 'card', 'bank_transfer']) {
        final testData = {...incomingData, 'payment_method': method};
        final testResponse = await makeRequest('POST', '/incoming', body: testData);
        if (testResponse['success'] == true) {
          print('✅ Payment method "$method" works');
        } else {
          print('❌ Payment method "$method" failed');
        }
      }
    } else {
      print('❌ Create incoming failed: ${createResponse['message']}');
    }
  } catch (e) {
    print('❌ Incoming test failed: $e');
  }
}

Future<void> testExpenses() async {
  print('\n📝 Testing Expenses...');
  print('-'.repeat(80));

  try {
    // Create expense
    final expenseData = {
      'amount': 50.00,
      'category': 'Food',
      'payment_method': 'cash',
      'description': 'Lunch',
      'date': '2024-01-15',
    };

    final createResponse = await makeRequest(
      'POST',
      '/expenses',
      body: expenseData,
    );

    if (createResponse['success'] == true) {
      print('✅ Create expense successful');
      final expense = createResponse['data'];
      print('   ID: ${expense['id']}');
      print('   Amount: ${expense['amount']}');
      print('   Category: ${expense['category']}');
      print('   Payment Method: ${expense['payment_method']}');

      // List with filters
      final listResponse = await makeRequest(
        'GET',
        '/expenses?category=Food&per_page=15',
      );
      if (listResponse['success'] == true) {
        print('✅ List expenses with filters successful');
      }
    } else {
      print('❌ Create expense failed: ${createResponse['message']}');
    }
  } catch (e) {
    print('❌ Expense test failed: $e');
  }
}

Future<void> testFundBox() async {
  print('\n📝 Testing Fund Box (Admin Only)...');
  print('-'.repeat(80));

  try {
    // Get fund box
    final getResponse = await makeRequest('GET', '/fund-box');

    if (getResponse['success'] == true) {
      print('✅ Get fund box successful');
      final fundBox = getResponse['data'];
      print('   Total Balance: ${fundBox['total_balance']}');
      print('   Last Updated: ${fundBox['last_updated']}');

      // Verify field mappings
      if (fundBox.containsKey('total_balance') &&
          fundBox.containsKey('last_updated')) {
        print('✅ Field mappings correct (total_balance, last_updated)');
      } else {
        print('❌ Field mappings incorrect!');
      }

      // Update fund box
      final updateData = {'total_balance': 15000.00};
      final updateResponse = await makeRequest(
        'PUT',
        '/fund-box',
        body: updateData,
      );

      if (updateResponse['success'] == true) {
        print('✅ Update fund box successful');
      }
    } else if (getResponse['message']?.contains('403') == true ||
        getResponse['message']?.contains('Forbidden') == true) {
      print('⚠️  Fund box access denied (403) - Expected for non-admin users');
    } else {
      print('❌ Get fund box failed: ${getResponse['message']}');
    }
  } catch (e) {
    if (e.toString().contains('403')) {
      print('⚠️  Fund box access denied (403) - Expected for non-admin users');
    } else {
      print('❌ Fund box test failed: $e');
    }
  }
}

Future<void> testAdminDashboard() async {
  print('\n📝 Testing Admin Dashboard (Admin Only)...');
  print('-'.repeat(80));

  try {
    // Get dashboard stats
    final statsResponse = await makeRequest('GET', '/admin/dashboard/stats');

    if (statsResponse['success'] == true) {
      print('✅ Get dashboard stats successful');
      final stats = statsResponse['data'];
      print('   Total Users: ${stats['total_users']}');
      print('   Total Expenses: ${stats['total_expenses']}');
      print('   Total Income: ${stats['total_income']}');
      print('   Total Transfers: ${stats['total_transfers']}');
      print('   Fund Box Balance: ${stats['fund_box_balance']}');

      // Verify all required fields
      final requiredFields = [
        'total_users',
        'total_expenses',
        'total_income',
        'total_transfers',
        'total_amount_expenses',
        'total_amount_income',
        'fund_box_balance',
      ];

      final allFieldsPresent = requiredFields.every((field) => stats.containsKey(field));
      if (allFieldsPresent) {
        print('✅ All required fields present');
      } else {
        print('❌ Missing required fields!');
      }

      // Get user activity
      final usersResponse = await makeRequest('GET', '/admin/dashboard/users');
      if (usersResponse['success'] == true) {
        print('✅ Get user activity successful');
      }

      // Get expense summaries
      final expensesResponse = await makeRequest('GET', '/admin/dashboard/expenses');
      if (expensesResponse['success'] == true) {
        print('✅ Get expense summaries successful');
        final data = expensesResponse['data'];
        if (data.containsKey('by_category') && data.containsKey('by_payment_method')) {
          print('✅ Expense summaries have correct structure');
        }
      }
    } else if (statsResponse['message']?.contains('403') == true) {
      print('⚠️  Admin dashboard access denied (403) - Expected for non-admin users');
    } else {
      print('❌ Get dashboard stats failed: ${statsResponse['message']}');
    }
  } catch (e) {
    if (e.toString().contains('403')) {
      print('⚠️  Admin dashboard access denied (403) - Expected for non-admin users');
    } else {
      print('❌ Admin dashboard test failed: $e');
    }
  }
}

Future<void> testProfile() async {
  print('\n📝 Testing Profile...');
  print('-'.repeat(80));

  try {
    // Get profile
    final getResponse = await makeRequest('GET', '/profile');

    if (getResponse['success'] == true) {
      print('✅ Get profile successful');
      final profile = getResponse['data'];
      print('   ID: ${profile['id']}');
      print('   Name: ${profile['name']}');
      print('   Email: ${profile['email']}');
      print('   Role: ${profile['role']}');

      // Verify required fields
      if (profile.containsKey('id') &&
          profile.containsKey('name') &&
          profile.containsKey('email') &&
          profile.containsKey('role')) {
        print('✅ All required fields present');
      }
    } else {
      print('❌ Get profile failed: ${getResponse['message']}');
    }
  } catch (e) {
    print('❌ Profile test failed: $e');
  }
}

Future<void> testExport() async {
  print('\n📝 Testing Export...');
  print('-'.repeat(80));

  try {
    // Request PDF export
    final exportData = {
      'format': 'pdf',
      'date_from': '2024-01-01',
      'date_to': '2024-01-31',
    };

    final exportResponse = await makeRequest(
      'POST',
      '/export/expenses/pdf',
      body: exportData,
    );

    if (exportResponse['success'] == true) {
      print('✅ Request PDF export successful');
      final export = exportResponse['data'];
      print('   ID: ${export['id']}');
      print('   Format: ${export['format']}');
      print('   Status: ${export['status']}');

      // Verify required fields
      if (export.containsKey('id') &&
          export.containsKey('format') &&
          export.containsKey('status')) {
        print('✅ All required fields present');
      }
    } else {
      print('❌ Request export failed: ${exportResponse['message']}');
    }
  } catch (e) {
    print('❌ Export test failed: $e');
  }
}

Future<void> testAuditLogs() async {
  print('\n📝 Testing Audit Logs (Admin Only)...');
  print('-'.repeat(80));

  try {
    // Get audit logs
    final logsResponse = await makeRequest('GET', '/audit-logs?per_page=10');

    if (logsResponse['success'] == true) {
      print('✅ Get audit logs successful');
      final data = logsResponse['data'];
      print('   Total: ${data['total']}');
      print('   Per Page: ${data['per_page']}');
      print('   Current Page: ${data['current_page']}');

      if (data['data'] != null && (data['data'] as List).isNotEmpty) {
        final log = data['data'][0];
        print('   Sample log:');
        print('     Action: ${log['action']}');
        print('     Entity Type: ${log['entity_type']}');
        print('     User ID: ${log['user_id']}');
      }
    } else if (logsResponse['message']?.contains('403') == true) {
      print('⚠️  Audit logs access denied (403) - Expected for non-admin users');
    } else {
      print('❌ Get audit logs failed: ${logsResponse['message']}');
    }
  } catch (e) {
    if (e.toString().contains('403')) {
      print('⚠️  Audit logs access denied (403) - Expected for non-admin users');
    } else {
      print('❌ Audit logs test failed: $e');
    }
  }
}

Future<Map<String, dynamic>> makeRequest(
  String method,
  String endpoint, {
  Map<String, dynamic>? body,
  bool requiresAuth = true,
}) async {
  final client = HttpClient();
  
  try {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = await client.openUrl(method, uri);

    // Set headers
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');

    if (requiresAuth && authToken != null) {
      request.headers.set('Authorization', 'Bearer $authToken');
    }

    // Add body if present
    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    return jsonDecode(responseBody);
  } catch (e) {
    return {
      'success': false,
      'message': 'Request failed: $e',
    };
  } finally {
    client.close();
  }
}

extension StringRepeat on String {
  String repeat(int count) => List.filled(count, this).join();
}
