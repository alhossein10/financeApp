import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:finance_app/features/transfers/data/datasources/transfer_api_datasource.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';

import 'admin_registration_transfer_flow_test.mocks.dart';

@GenerateMocks([ApiClient, TokenManager])
void main() {
  late MockApiClient mockApiClient;
  late MockTokenManager mockTokenManager;
  late AuthApiDataSourceImpl authDataSource;
  late TransferApiDataSourceImpl transferDataSource;
  late AdminGroupApiDatasource adminGroupDataSource;
  late FundBoxApiDataSourceImpl fundBoxDataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    mockTokenManager = MockTokenManager();
    authDataSource = AuthApiDataSourceImpl(apiClient: mockApiClient);
    transferDataSource = TransferApiDataSourceImpl(apiClient: mockApiClient);
    adminGroupDataSource = AdminGroupApiDatasource(apiClient: mockApiClient);
    fundBoxDataSource = FundBoxApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('Admin Registration with Code → Transfer → Group Management Flow', () {
    test('Complete Admin flow: Register with code → Create transfer → Manage group',
        () async {
      // Step 1: Admin Registration with SuperAdmin group code
      final registrationResponse = {
        'success': true,
        'data': {
          'user': {
            'id': 10,
            'name': 'Admin User',
            'email': 'admin@test.com',
            'role': 'admin',
            'admin_group_id': 1,
          },
          'token': 'admin-token-456',
          'token_type': 'Bearer',
          'admin_group': {
            'id': 1,
            'name': 'Test Admin Group',
            'super_admin_id': 1,
          },
        },
      };

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: registrationResponse,
          ));

      final registrationResult = await authDataSource.register(
        name: 'Admin User',
        email: 'admin@test.com',
        password: 'password123',
        role: 'admin',
        superAdminGroupCode: '123456',
      );

      expect(registrationResult['user']['role'], 'admin');
      expect(registrationResult['user']['admin_group_id'], 1);
      expect(registrationResult['admin_group']['name'], 'Test Admin Group');
      expect(registrationResult['token'], 'admin-token-456');

      // Step 2: Save token
      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
      )).thenAnswer((_) async => {});

      await mockTokenManager.saveToken(
        token: registrationResult['token'],
        tokenType: 'Bearer',
      );

      // Step 3: Get Admin's Fund Box (initial balance)
      final initialFundBoxResponse = {
        'data': {
          'id': 10,
          'user_id': 10,
          'balance_usd': 1000.0,
          'balance_syp': 15000000.0,
          'balance_try': 30000.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: initialFundBoxResponse,
          ));

      final initialFundBox = await fundBoxDataSource.getFundBox();

      expect(initialFundBox.balanceUsd, 1000.0);
      expect(initialFundBox.balanceSyp, 15000000.0);
      expect(initialFundBox.balanceTry, 30000.0);

      // Step 4: Create Transfer to User
      final transferResponse = {
        'data': {
          'id': 1,
          'sender_id': 10,
          'recipient_user_id': 20,
          'amount': 100.0,
          'transfer_date': '2024-11-16',
          'notes': 'Transfer to user',
          'created_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.post(
        '/transfers',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: transferResponse,
          ));

      final transfer = await transferDataSource.createTransfer(
        recipientUserId: 20,
        amount: 100.0,
        transferDate: '2024-11-16',
        notes: 'Transfer to user',
      );

      expect(transfer.senderId, 10);
      expect(transfer.recipientUserId, 20);
      expect(transfer.amount, 100.0);

      // Step 5: Verify Fund Box updated (balance decreased)
      final updatedFundBoxResponse = {
        'data': {
          'id': 10,
          'user_id': 10,
          'balance_usd': 900.0,
          'balance_syp': 15000000.0,
          'balance_try': 30000.0,
          'last_calculated_at': '2024-11-16T10:05:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: updatedFundBoxResponse,
          ));

      final updatedFundBox = await fundBoxDataSource.getFundBox();

      expect(updatedFundBox.balanceUsd, 900.0);

      // Step 6: Get Admin Group Info
      final groupInfoResponse = {
        'data': {
          'id': 1,
          'name': 'Test Admin Group',
          'group_code': 'ABC123',
          'member_count': 5,
          'created_at': '2024-11-15T10:00:00Z',
        },
      };

      when(mockApiClient.get('/admin-group')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: groupInfoResponse,
          ));

      final groupInfo = await adminGroupDataSource.getAdminGroupInfo();

      expect(groupInfo.name, 'Test Admin Group');
      expect(groupInfo.groupCode, 'ABC123');
      expect(groupInfo.memberCount, 5);

      // Step 7: Get Group Members
      final membersResponse = {
        'data': [
          {
            'id': 20,
            'name': 'User 1',
            'email': 'user1@test.com',
            'role': 'user',
            'joined_at': '2024-11-14T10:00:00Z',
          },
          {
            'id': 21,
            'name': 'User 2',
            'email': 'user2@test.com',
            'role': 'user',
            'joined_at': '2024-11-13T10:00:00Z',
          },
        ],
      };

      when(mockApiClient.get('/admin-group/members')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: membersResponse,
          ));

      final members = await adminGroupDataSource.getGroupMembers();

      expect(members.length, 2);
      expect(members[0].name, 'User 1');
      expect(members[1].name, 'User 2');

      // Step 8: Regenerate Group Code
      final regenerateResponse = {
        'data': {
          'group_code': 'XYZ789',
          'message': 'Group code regenerated successfully',
        },
      };

      when(mockApiClient.post('/admin-group/regenerate-code'))
          .thenAnswer((_) async => ApiResponse(
                statusCode: 200,
                data: regenerateResponse,
          ));

      final newCode = await adminGroupDataSource.regenerateGroupCode();

      expect(newCode, 'XYZ789');

      // Step 9: Remove Group Member
      when(mockApiClient.delete('/admin-group/members/21'))
          .thenAnswer((_) async => ApiResponse(
                statusCode: 204,
                data: null,
              ));

      await adminGroupDataSource.removeGroupMember(21);

      verify(mockApiClient.delete('/admin-group/members/21')).called(1);

      // Verify complete flow executed successfully
      print('✅ Admin flow completed successfully');
      print('   - Registration with admin role and group code');
      print('   - Token saved');
      print('   - Initial fund box retrieved (1000 USD)');
      print('   - Transfer created (100 USD to user)');
      print('   - Fund box updated (900 USD remaining)');
      print('   - Group info retrieved');
      print('   - Members listed (2 users)');
      print('   - Group code regenerated');
      print('   - Member removed');
    });

    test('Admin transfer with insufficient balance', () async {
      // Get Fund Box with low balance
      final fundBoxResponse = {
        'data': {
          'id': 10,
          'user_id': 10,
          'balance_usd': 50.0,
          'balance_syp': 0.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: fundBoxResponse,
          ));

      final fundBox = await fundBoxDataSource.getFundBox();
      expect(fundBox.balanceUsd, 50.0);

      // Attempt transfer exceeding balance
      when(mockApiClient.post(
        '/transfers',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 422,
            data: {
              'message': 'Insufficient balance',
              'errors': {
                'amount': ['Insufficient USD balance'],
              },
            },
          ));

      expect(
        () => transferDataSource.createTransfer(
          recipientUserId: 20,
          amount: 100.0,
          transferDate: '2024-11-16',
        ),
        throwsException,
      );
    });

    test('Admin group member pagination', () async {
      // Page 1
      when(mockApiClient.get('/admin-group/members?page=1&per_page=10'))
          .thenAnswer((_) async => ApiResponse(
                statusCode: 200,
                data: {
                  'data': List.generate(
                    10,
                    (i) => {
                      'id': 20 + i,
                      'name': 'User ${i + 1}',
                      'email': 'user${i + 1}@test.com',
                      'role': 'user',
                      'joined_at': '2024-11-16T10:00:00Z',
                    },
                  ),
                  'current_page': 1,
                  'last_page': 2,
                  'per_page': 10,
                  'total': 15,
                },
              ));

      final page1 = await adminGroupDataSource.getGroupMembers(page: 1, perPage: 10);
      expect(page1.length, 10);

      // Page 2
      when(mockApiClient.get('/admin-group/members?page=2&per_page=10'))
          .thenAnswer((_) async => ApiResponse(
                statusCode: 200,
                data: {
                  'data': List.generate(
                    5,
                    (i) => {
                      'id': 30 + i,
                      'name': 'User ${i + 11}',
                      'email': 'user${i + 11}@test.com',
                      'role': 'user',
                      'joined_at': '2024-11-16T10:00:00Z',
                    },
                  ),
                  'current_page': 2,
                  'last_page': 2,
                  'per_page': 10,
                  'total': 15,
                },
              ));

      final page2 = await adminGroupDataSource.getGroupMembers(page: 2, perPage: 10);
      expect(page2.length, 5);
    });
  });
}
