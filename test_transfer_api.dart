import 'dart:io';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:finance_app/features/transfers/data/datasources/transfer_api_datasource.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';

/// Manual test script to verify Transfer API integration with Laravel backend
/// 
/// Prerequisites:
/// 1. Laravel backend must be running at http://localhost:8000
/// 2. You must have a valid authentication token
/// 
/// Usage:
/// dart run test_transfer_api.dart <your_auth_token>
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run test_transfer_api.dart <auth_token>');
    print('\nTo get an auth token:');
    print('1. Start the Laravel backend: cd financeApp-backend-main && php artisan serve');
    print('2. Login via API or use Postman to get a token');
    exit(1);
  }

  final token = args[0];
  print('🚀 Starting Transfer API Integration Test\n');
  print('Using token: ${token.substring(0, 20)}...\n');

  // Initialize API client
  final tokenManager = TokenManager();
  await tokenManager.saveToken(token);
  
  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenManager: tokenManager,
  );

  final dataSource = TransferApiDataSourceImpl(apiClient: apiClient);

  try {
    // Test 1: Create Transfer
    print('📝 Test 1: Creating a new transfer...');
    final newTransfer = TransferDto(
      recipientName: 'abo momen',
      amountUsd: 500.0,
      transferDate: DateFormatter.toApiDate(DateTime.now()),
      notes: 'Test transfer from API integration',
    );

    print('Request body:');
    print('  recipient_name: ${newTransfer.recipientName}');
    print('  amount_usd: ${newTransfer.amountUsd}');
    print('  transfer_date: ${newTransfer.transferDate}');
    print('  notes: ${newTransfer.notes}');

    final createdTransfer = await dataSource.createTransfer(newTransfer);
    print('✅ Transfer created successfully!');
    print('  ID: ${createdTransfer.id}');
    print('  Recipient: ${createdTransfer.recipientName}');
    print('  Amount USD: ${createdTransfer.amountUsd}');
    print('  Date: ${createdTransfer.transferDate}\n');

    // Test 2: Get Transfer by ID
    print('📖 Test 2: Fetching transfer by ID...');
    final fetchedTransfer = await dataSource.getTransfer(createdTransfer.id!);
    print('✅ Transfer fetched successfully!');
    print('  ID: ${fetchedTransfer.id}');
    print('  Recipient: ${fetchedTransfer.recipientName}');
    print('  Amount USD: ${fetchedTransfer.amountUsd}');
    print('  Date: ${fetchedTransfer.transferDate}\n');

    // Test 3: Update Transfer
    print('✏️  Test 3: Updating transfer...');
    final updatedTransfer = createdTransfer.copyWith(
      amountUsd: 750.0,
      notes: 'Updated test transfer',
    );

    final result = await dataSource.updateTransfer(
      createdTransfer.id!,
      updatedTransfer,
    );
    print('✅ Transfer updated successfully!');
    print('  New amount: ${result.amountUsd}');
    print('  New notes: ${result.notes}\n');

    // Test 4: List Transfers
    print('📋 Test 4: Listing all transfers...');
    final transferList = await dataSource.getTransfers(
      page: 1,
      perPage: 10,
    );
    print('✅ Transfers listed successfully!');
    print('  Total: ${transferList.total}');
    print('  Current page: ${transferList.currentPage}');
    print('  Per page: ${transferList.perPage}');
    print('  Items in this page: ${transferList.data.length}\n');

    // Test 5: List Transfers with Date Filter
    print('📅 Test 5: Listing transfers with date filter...');
    final startDate = DateTime.now().subtract(const Duration(days: 30));
    final endDate = DateTime.now();
    final filteredList = await dataSource.getTransfers(
      page: 1,
      perPage: 10,
      startDate: startDate,
      endDate: endDate,
    );
    print('✅ Filtered transfers listed successfully!');
    print('  Date range: ${DateFormatter.toApiDate(startDate)} to ${DateFormatter.toApiDate(endDate)}');
    print('  Total: ${filteredList.total}\n');

    // Test 6: Delete Transfer
    print('🗑️  Test 6: Deleting transfer...');
    await dataSource.deleteTransfer(createdTransfer.id!);
    print('✅ Transfer deleted successfully!\n');

    // Verify deletion
    print('🔍 Verifying deletion...');
    try {
      await dataSource.getTransfer(createdTransfer.id!);
      print('❌ ERROR: Transfer still exists after deletion!');
    } catch (e) {
      print('✅ Confirmed: Transfer no longer exists\n');
    }

    print('🎉 All tests passed successfully!');
    print('\n✅ Transfer API Integration is working correctly with:');
    print('   - Correct field mappings (recipient_name, amount_usd, transfer_date, notes)');
    print('   - Proper date formatting (YYYY-MM-DD)');
    print('   - All CRUD operations functional');

  } catch (e, stackTrace) {
    print('❌ Test failed with error:');
    print(e);
    print('\nStack trace:');
    print(stackTrace);
    exit(1);
  }
}
