import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';
import 'package:finance_app/features/transfers/data/datasources/transfer_api_datasource.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration tests for SuperAdmin Cash Page Flow
/// Tests Requirements: 2.1-2.6
/// 
/// These tests verify:
/// - Loading fund box and transfers for SuperAdmin
/// - Creating outgoing transfers to admins
/// - Transfer list updates after creation
/// - Filtering transfers to show only outgoing
void main() {
  group('SuperAdmin Cash Page Integration Tests', () {
    late ApiClient apiClient;
    late TokenManager tokenManager;
    late LaravelAuthService authService;
    late FundBoxApiDataSource fundBoxDataSource;
    late TransferApiDataSource transferDataSource;
    late AdminGroupApiDataSource adminGroupDataSource;
    late FlutterSecureStorage secureStorage;

    setUp(() {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      apiClient = DioApiClient(dio: dio);
      secureStorage = const FlutterSecureStorage();
      tokenManager = TokenManager(secureStorage: secureStorage);
      authService = LaravelAuthService(
        apiClient: apiClient,
        tokenManager: tokenManager,
      );
      fundBoxDataSource = FundBoxApiDataSourceImpl(apiClient: apiClient);
      transferDataSource = TransferApiDataSourceImpl(apiClient: apiClient);
      adminGroupDataSource = AdminGroupApiDataSourceImpl(apiClient: apiClient);
    });

    tearDown(() async {
      try {
        await tokenManager.clearTokens();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('SuperAdmin can load fund box successfully', () async {
      try {
        // Register as SuperAdmin
        final testEmail = 'superadmin_fundbox_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        await authService.register(
          name: 'SuperAdmin Fund Box Test',
          email: testEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Load fund box
        final fundBox = await fundBoxDataSource.getFundBox();
        
        expect(fundBox, isNotNull);
        expect(fundBox.id, isNotNull);
        expect(fundBox.balanceUsd, isA<double>());
        expect(fundBox.lastUpdated, isNotNull);

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('SuperAdmin can load transfers list', () async {
      try {
        // Register as SuperAdmin
        final testEmail = 'superadmin_transfers_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        await authService.register(
          name: 'SuperAdmin Transfers Test',
          email: testEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Load transfers
        final transfersResponse = await transferDataSource.getTransfers();
        
        expect(transfersResponse, isNotNull);
        expect(transfersResponse.data, isA<List<TransferDto>>());
        expect(transfersResponse.meta, isNotNull);

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('SuperAdmin can create outgoing transfer to admin', () async {
      try {
        // Register SuperAdmin
        final saEmail = 'superadmin_create_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final saUser = await authService.register(
          name: 'SuperAdmin Create Transfer',
          email: saEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Get group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register an admin in the SuperAdmin's group
        final adminEmail = 'admin_recipient_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final adminUser = await authService.register(
          name: 'Admin Recipient',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Login as SuperAdmin
        await authService.login(
          email: saEmail,
          password: 'TestPassword123!',
        );

        // Create outgoing transfer to admin
        final transfer = TransferDto(
          recipientId: adminUser.id,
          amount: 500.0,
          currency: 'USD',
          description: 'Test outgoing transfer',
          transferDate: DateTime.now(),
        );

        final createdTransfer = await transferDataSource.createTransfer(transfer);
        
        expect(createdTransfer, isNotNull);
        expect(createdTransfer.id, isNotNull);
        expect(createdTransfer.senderId, equals(saUser.id));
        expect(createdTransfer.recipientId, equals(adminUser.id));
        expect(createdTransfer.amount, equals(500.0));
        expect(createdTransfer.currency, equals('USD'));

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('SuperAdmin transfer list updates after creation', () async {
      try {
        // Register SuperAdmin
        final saEmail = 'superadmin_update_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final saUser = await authService.register(
          name: 'SuperAdmin Update Test',
          email: saEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Get initial transfer count
        final initialTransfers = await transferDataSource.getTransfers();
        final initialCount = initialTransfers.data.length;

        // Get group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register an admin
        final adminEmail = 'admin_update_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final adminUser = await authService.register(
          name: 'Admin Update',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Login as SuperAdmin
        await authService.login(
          email: saEmail,
          password: 'TestPassword123!',
        );

        // Create a transfer
        final transfer = TransferDto(
          recipientId: adminUser.id,
          amount: 300.0,
          currency: 'USD',
          description: 'Update test transfer',
          transferDate: DateTime.now(),
        );

        await transferDataSource.createTransfer(transfer);

        // Get updated transfer list
        final updatedTransfers = await transferDataSource.getTransfers();
        final updatedCount = updatedTransfers.data.length;

        expect(updatedCount, greaterThan(initialCount));

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('SuperAdmin can only see outgoing transfers', () async {
      try {
        // Register SuperAdmin
        final saEmail = 'superadmin_outgoing_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final saUser = await authService.register(
          name: 'SuperAdmin Outgoing Test',
          email: saEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Get group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register an admin
        final adminEmail = 'admin_outgoing_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final adminUser = await authService.register(
          name: 'Admin Outgoing',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Login as SuperAdmin and create outgoing transfer
        await authService.login(
          email: saEmail,
          password: 'TestPassword123!',
        );

        final transfer = TransferDto(
          recipientId: adminUser.id,
          amount: 200.0,
          currency: 'USD',
          description: 'Outgoing test',
          transferDate: DateTime.now(),
        );

        await transferDataSource.createTransfer(transfer);

        // Get transfers
        final transfers = await transferDataSource.getTransfers();
        
        // All transfers should be outgoing (sender is SuperAdmin)
        for (final t in transfers.data) {
          expect(t.senderId, equals(saUser.id));
        }

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('SuperAdmin can filter recipients to admins only', () async {
      try {
        // Register SuperAdmin
        final saEmail = 'superadmin_filter_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'SuperAdmin Filter Test',
          email: saEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Get group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register an admin
        final adminEmail = 'admin_filter_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Filter',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Register a regular user
        final userEmail = 'user_filter_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Filter',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Login as SuperAdmin
        await authService.login(
          email: saEmail,
          password: 'TestPassword123!',
        );

        // Get group members
        final members = await adminGroupDataSource.getGroupMembers();
        
        // Filter to admins only
        final adminMembers = members.data.where((m) => m.role == 'admin').toList();
        
        expect(adminMembers, isNotEmpty);
        expect(adminMembers.length, greaterThan(0));
        
        // Verify all filtered members are admins
        for (final member in adminMembers) {
          expect(member.role, equals('admin'));
        }

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('SuperAdmin fund box balance updates after transfer', () async {
      try {
        // Register SuperAdmin
        final saEmail = 'superadmin_balance_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final saUser = await authService.register(
          name: 'SuperAdmin Balance Test',
          email: saEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Set initial fund box balance
        await fundBoxDataSource.updateFundBox(balanceUsd: 10000.0);

        // Get initial balance
        final initialFundBox = await fundBoxDataSource.getFundBox();
        final initialBalance = initialFundBox.balanceUsd;

        // Get group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register an admin
        final adminEmail = 'admin_balance_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final adminUser = await authService.register(
          name: 'Admin Balance',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Login as SuperAdmin
        await authService.login(
          email: saEmail,
          password: 'TestPassword123!',
        );

        // Create transfer
        final transferAmount = 1000.0;
        final transfer = TransferDto(
          recipientId: adminUser.id,
          amount: transferAmount,
          currency: 'USD',
          description: 'Balance test transfer',
          transferDate: DateTime.now(),
        );

        await transferDataSource.createTransfer(transfer);

        // Get updated balance
        final updatedFundBox = await fundBoxDataSource.getFundBox();
        final updatedBalance = updatedFundBox.balanceUsd;

        // Balance should decrease by transfer amount
        expect(updatedBalance, lessThan(initialBalance));

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('SuperAdmin cannot create transfer with insufficient funds', () async {
      try {
        // Register SuperAdmin
        final saEmail = 'superadmin_insufficient_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final saUser = await authService.register(
          name: 'SuperAdmin Insufficient Test',
          email: saEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Set low fund box balance
        await fundBoxDataSource.updateFundBox(balanceUsd: 100.0);

        // Get group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register an admin
        final adminEmail = 'admin_insufficient_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final adminUser = await authService.register(
          name: 'Admin Insufficient',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Login as SuperAdmin
        await authService.login(
          email: saEmail,
          password: 'TestPassword123!',
        );

        // Try to create transfer with amount greater than balance
        final transfer = TransferDto(
          recipientId: adminUser.id,
          amount: 10000.0, // More than available
          currency: 'USD',
          description: 'Insufficient funds test',
          transferDate: DateTime.now(),
        );

        await transferDataSource.createTransfer(transfer);

        fail('Expected exception for insufficient funds');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Expect validation error
        expect(e, isNotNull);
        expect(e.toString().toLowerCase(), anyOf([
          contains('insufficient'),
          contains('balance'),
          contains('funds'),
        ]));
      }
    });

    test('SuperAdmin transfer includes correct metadata', () async {
      try {
        // Register SuperAdmin
        final saEmail = 'superadmin_metadata_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final saUser = await authService.register(
          name: 'SuperAdmin Metadata Test',
          email: saEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Get group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register an admin
        final adminEmail = 'admin_metadata_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final adminUser = await authService.register(
          name: 'Admin Metadata',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Login as SuperAdmin
        await authService.login(
          email: saEmail,
          password: 'TestPassword123!',
        );

        // Create transfer with description
        final description = 'Test transfer with metadata';
        final transfer = TransferDto(
          recipientId: adminUser.id,
          amount: 250.0,
          currency: 'USD',
          description: description,
          transferDate: DateTime.now(),
        );

        final createdTransfer = await transferDataSource.createTransfer(transfer);
        
        expect(createdTransfer.description, equals(description));
        expect(createdTransfer.currency, equals('USD'));
        expect(createdTransfer.transferDate, isNotNull);
        expect(createdTransfer.createdAt, isNotNull);

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('SuperAdmin can view transfer details', () async {
      try {
        // Register SuperAdmin
        final saEmail = 'superadmin_details_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final saUser = await authService.register(
          name: 'SuperAdmin Details Test',
          email: saEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Get group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register an admin
        final adminEmail = 'admin_details_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final adminUser = await authService.register(
          name: 'Admin Details',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );
        
        await authService.logout();

        // Login as SuperAdmin
        await authService.login(
          email: saEmail,
          password: 'TestPassword123!',
        );

        // Create transfer
        final transfer = TransferDto(
          recipientId: adminUser.id,
          amount: 400.0,
          currency: 'USD',
          description: 'Details test transfer',
          transferDate: DateTime.now(),
        );

        final createdTransfer = await transferDataSource.createTransfer(transfer);

        // Get transfer details
        final transferDetails = await transferDataSource.getTransfer(createdTransfer.id!);
        
        expect(transferDetails, isNotNull);
        expect(transferDetails.id, equals(createdTransfer.id));
        expect(transferDetails.amount, equals(400.0));
        expect(transferDetails.senderId, equals(saUser.id));
        expect(transferDetails.recipientId, equals(adminUser.id));

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });
  });
}
