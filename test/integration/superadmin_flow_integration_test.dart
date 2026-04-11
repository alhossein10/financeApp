import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:finance_app/features/superadmin/data/datasources/superadmin_analytics_api_datasource.dart';
import 'package:finance_app/features/superadmin/data/datasources/superadmin_group_api_datasource.dart';

import 'superadmin_flow_integration_test.mocks.dart';

@GenerateMocks([ApiClient, TokenManager])
void main() {
  late MockApiClient mockApiClient;
  late MockTokenManager mockTokenManager;
  late AuthApiDataSourceImpl authDataSource;
  late SuperAdminAnalyticsApiDatasource analyticsDataSource;
  late SuperAdminGroupApiDatasource groupDataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    mockTokenManager = MockTokenManager();
    authDataSource = AuthApiDataSourceImpl(apiClient: mockApiClient);
    analyticsDataSource = SuperAdminAnalyticsApiDatasource(apiClient: mockApiClient);
    groupDataSource = SuperAdminGroupApiDatasource(apiClient: mockApiClient);
  });

  group('SuperAdmin Flow Integration Tests', () {
    test('Complete SuperAdmin registration → Analytics → Group management flow',
        () async {
      // Step 1: SuperAdmin Registration
      final registrationResponse = {
        'success': true,
        'data': {
          'user': {
            'id': 1,
            'name': 'Super Admin',
            'email': 'superadmin@test.com',
            'role': 'superAdmin',
          },
          'token': 'superadmin-token-123',
          'token_type': 'Bearer',
          'super_admin_group_code': '123456',
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
        name: 'Super Admin',
        email: 'superadmin@test.com',
        password: 'password123',
        role: 'superAdmin',
        organizationName: 'Test Org',
        adminGroupName: 'Test SuperAdmin Group',
      );

      expect(registrationResult['user']['role'], 'superAdmin');
      expect(registrationResult['super_admin_group_code'], '123456');
      expect(registrationResult['token'], 'superadmin-token-123');

      // Step 2: Save token
      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
      )).thenAnswer((_) async => {});

      await mockTokenManager.saveToken(
        token: registrationResult['token'],
        tokenType: 'Bearer',
      );

      verify(mockTokenManager.saveToken(
        token: 'superadmin-token-123',
        tokenType: 'Bearer',
      )).called(1);

      // Step 3: Fetch Analytics (with Bearer token)
      final analyticsResponse = {
        'data': {
          'period': '15days',
          'admin_groups': [
            {
              'admin_group_id': 1,
              'admin_group_name': 'Group A',
              'total_transfers': 10,
              'total_transfer_amount': 5000.0,
              'total_expenses': 20,
              'total_expense_amount': 3000.0,
            },
            {
              'admin_group_id': 2,
              'admin_group_name': 'Group B',
              'total_transfers': 5,
              'total_transfer_amount': 2500.0,
              'total_expenses': 15,
              'total_expense_amount': 1500.0,
            },
          ],
        },
      };

      when(mockApiClient.get(
        '/super-admin/analytics',
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: analyticsResponse,
          ));

      final analytics = await analyticsDataSource.getAnalytics(period: '15days');

      expect(analytics.period, '15days');
      expect(analytics.adminGroups.length, 2);
      expect(analytics.adminGroups[0].adminGroupName, 'Group A');
      expect(analytics.adminGroups[0].totalTransfers, 10);

      // Step 4: Get Group Info
      final groupInfoResponse = {
        'data': {
          'id': 1,
          'name': 'Test SuperAdmin Group',
          'group_code': '123456',
          'member_count': 3,
          'created_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get('/superadmin/group')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: groupInfoResponse,
          ));

      final groupInfo = await groupDataSource.getGroupInfo();

      expect(groupInfo.name, 'Test SuperAdmin Group');
      expect(groupInfo.groupCode, '123456');
      expect(groupInfo.memberCount, 3);

      // Step 5: Get Group Members
      final membersResponse = {
        'data': [
          {
            'id': 2,
            'name': 'Admin 1',
            'email': 'admin1@test.com',
            'role': 'admin',
            'joined_at': '2024-11-15T10:00:00Z',
          },
          {
            'id': 3,
            'name': 'Admin 2',
            'email': 'admin2@test.com',
            'role': 'admin',
            'joined_at': '2024-11-14T10:00:00Z',
          },
        ],
        'current_page': 1,
        'last_page': 1,
        'per_page': 15,
        'total': 2,
      };

      when(mockApiClient.get(
        '/superadmin/group/members',
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: membersResponse,
          ));

      final members = await groupDataSource.getMembers(page: 1, perPage: 15);

      expect(members.data.length, 2);
      expect(members.data[0].name, 'Admin 1');
      expect(members.data[1].name, 'Admin 2');
      expect(members.total, 2);

      // Step 6: Regenerate Group Code
      final regenerateResponse = {
        'data': {
          'id': 1,
          'name': 'Test SuperAdmin Group',
          'group_code': '789012',
          'member_count': 3,
          'created_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.post('/superadmin/group/regenerate-code'))
          .thenAnswer((_) async => ApiResponse(
                statusCode: 200,
                data: regenerateResponse,
              ));

      final newGroupInfo = await groupDataSource.regenerateCode();

      expect(newGroupInfo.groupCode, '789012');
      expect(newGroupInfo.name, 'Test SuperAdmin Group');

      // Step 7: Remove Member
      when(mockApiClient.delete('/superadmin/group/members/3'))
          .thenAnswer((_) async => ApiResponse(
                statusCode: 204,
                data: null,
              ));

      await groupDataSource.removeMember(3);

      verify(mockApiClient.delete('/superadmin/group/members/3')).called(1);

      // Verify complete flow executed successfully
      print('✅ SuperAdmin flow completed successfully');
      print('   - Registration with superAdmin role');
      print('   - Token saved');
      print('   - Analytics fetched (2 admin groups)');
      print('   - Group info retrieved');
      print('   - Members listed (2 members)');
      print('   - Group code regenerated');
      print('   - Member removed');
    });

    test('SuperAdmin analytics with different periods', () async {
      // Test 15days period
      when(mockApiClient.get(
        '/super-admin/analytics',
        queryParams: {'period': '15days'},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: {
              'data': {
                'period': '15days',
                'admin_groups': [],
              },
            },
          ));

      final analytics15days = await analyticsDataSource.getAnalytics(period: '15days');
      expect(analytics15days.period, '15days');

      // Test month period
      when(mockApiClient.get(
        '/super-admin/analytics',
        queryParams: {'period': 'month'},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: {
              'data': {
                'period': 'month',
                'admin_groups': [],
              },
            },
          ));

      final analyticsMonth = await analyticsDataSource.getAnalytics(period: 'month');
      expect(analyticsMonth.period, 'month');

      // Test all period
      when(mockApiClient.get(
        '/super-admin/analytics',
        queryParams: {'period': 'all'},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: {
              'data': {
                'period': 'all',
                'admin_groups': [],
              },
            },
          ));

      final analyticsAll = await analyticsDataSource.getAnalytics(period: 'all');
      expect(analyticsAll.period, 'all');
    });

    test('SuperAdmin group member pagination', () async {
      // Page 1
      when(mockApiClient.get(
        '/superadmin/group/members',
        queryParams: {'page': 1, 'per_page': 2},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: {
              'data': [
                {
                  'id': 2,
                  'name': 'Admin 1',
                  'email': 'admin1@test.com',
                  'role': 'admin',
                  'joined_at': '2024-11-15T10:00:00Z',
                },
                {
                  'id': 3,
                  'name': 'Admin 2',
                  'email': 'admin2@test.com',
                  'role': 'admin',
                  'joined_at': '2024-11-14T10:00:00Z',
                },
              ],
              'current_page': 1,
              'last_page': 2,
              'per_page': 2,
              'total': 4,
            },
          ));

      final page1 = await groupDataSource.getMembers(page: 1, perPage: 2);
      expect(page1.data.length, 2);
      expect(page1.currentPage, 1);
      expect(page1.hasMore, true);

      // Page 2
      when(mockApiClient.get(
        '/superadmin/group/members',
        queryParams: {'page': 2, 'per_page': 2},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: {
              'data': [
                {
                  'id': 4,
                  'name': 'Admin 3',
                  'email': 'admin3@test.com',
                  'role': 'admin',
                  'joined_at': '2024-11-13T10:00:00Z',
                },
                {
                  'id': 5,
                  'name': 'Admin 4',
                  'email': 'admin4@test.com',
                  'role': 'admin',
                  'joined_at': '2024-11-12T10:00:00Z',
                },
              ],
              'current_page': 2,
              'last_page': 2,
              'per_page': 2,
              'total': 4,
            },
          ));

      final page2 = await groupDataSource.getMembers(page: 2, perPage: 2);
      expect(page2.data.length, 2);
      expect(page2.currentPage, 2);
      expect(page2.hasMore, false);
    });
  });
}
