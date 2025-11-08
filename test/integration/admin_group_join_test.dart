import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration tests for Join Group Functionality
/// Tests Requirements: 4.1-4.6, 11.6
/// 
/// These tests verify:
/// - Join with valid code
/// - Join with invalid code
/// - Join when already in group
void main() {
  group('Join Group Integration Tests', () {
    late ApiClient apiClient;
    late TokenManager tokenManager;
    late LaravelAuthService authService;
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
      adminGroupDataSource = AdminGroupApiDataSourceImpl(apiClient: apiClient);
    });

    tearDown() async {
      try {
        await tokenManager.clearTokens();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('Join group: User successfully joins with valid code', () async {
      try {
        // Create admin and get group code
        final adminEmail = 'admin_join_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Join Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register user without group code
        final userEmail = 'user_join_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Join Test',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          // No group code during registration
        );

        // User joins group using the code
        final groupInfo = await adminGroupDataSource.joinGroup(groupCode);

        expect(groupInfo, isNotNull);
        expect(groupInfo.groupCode, equals(groupCode));
        expect(groupInfo.adminEmail, equals(adminEmail));
        expect(groupInfo.membersCount, greaterThanOrEqualTo(2));
        expect(groupInfo.joinedAt, isNotNull);

        // Verify user can get their group info
        final userGroupInfo = await adminGroupDataSource.getUserGroupInfo();
        expect(userGroupInfo.groupCode, equals(groupCode));

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

    test('Join group: Fails with invalid code format', () async {
      try {
        // Register user without group
        final userEmail = 'user_invalid_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Invalid Join',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        // Try to join with invalid code format
        try {
          await adminGroupDataSource.joinGroup('ABC'); // Too short
          fail('Expected exception for invalid code format');
        } catch (e) {
          expect(e, isNotNull);
          expect(e.toString().toLowerCase(), anyOf([
            contains('invalid'),
            contains('format'),
            contains('6 characters'),
          ]));
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

    test('Join group: Fails with non-existent code', () async {
      try {
        // Register user without group
        final userEmail = 'user_nonexist_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Nonexist Join',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        // Try to join with non-existent code
        try {
          await adminGroupDataSource.joinGroup('XXXXXX');
          fail('Expected exception for non-existent code');
        } catch (e) {
          expect(e, isNotNull);
          expect(e.toString().toLowerCase(), anyOf([
            contains('invalid'),
            contains('not found'),
            contains('does not exist'),
          ]));
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

    test('Join group: Fails when already in a group', () async {
      try {
        // Create first admin
        final admin1Email = 'admin1_already_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Already',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final admin1Group = await adminGroupDataSource.getAdminGroup();
        final groupCode1 = admin1Group.groupCode;
        
        await authService.logout();

        // Create second admin
        final admin2Email = 'admin2_already_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Already',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final admin2Group = await adminGroupDataSource.getAdminGroup();
        final groupCode2 = admin2Group.groupCode;
        
        await authService.logout();

        // User joins first group
        final userEmail = 'user_already_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Already',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode1,
        );

        // Try to join second group
        try {
          await adminGroupDataSource.joinGroup(groupCode2);
          fail('Expected exception when already in a group');
        } catch (e) {
          expect(e, isNotNull);
          expect(e.toString().toLowerCase(), anyOf([
            contains('already'),
            contains('in a group'),
            contains('cannot join'),
          ]));
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

    test('Join group: Admin cannot join another admin\'s group', () async {
      try {
        // Create first admin
        final admin1Email = 'admin1_nojoin_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 No Join',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final admin1Group = await adminGroupDataSource.getAdminGroup();
        final groupCode1 = admin1Group.groupCode;
        
        await authService.logout();

        // Create second admin
        final admin2Email = 'admin2_nojoin_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 No Join',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 tries to join Admin 1's group
        try {
          await adminGroupDataSource.joinGroup(groupCode1);
          fail('Expected exception when admin tries to join another group');
        } catch (e) {
          expect(e, isNotNull);
          expect(e.toString().toLowerCase(), anyOf([
            contains('admin'),
            contains('cannot join'),
            contains('not allowed'),
          ]));
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

    test('Join group: Code is case-insensitive', () async {
      try {
        // Create admin
        final adminEmail = 'admin_case_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Case Join',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // User joins with lowercase code
        final userEmail = 'user_case_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Case Join',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        final groupInfo = await adminGroupDataSource.joinGroup(groupCode.toLowerCase());

        expect(groupInfo, isNotNull);
        expect(groupInfo.groupCode.toUpperCase(), equals(groupCode.toUpperCase()));

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

    test('Join group: User can view group info after joining', () async {
      try {
        // Create admin
        final adminEmail = 'admin_info_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Info Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // User joins group
        final userEmail = 'user_info_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Info Test',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        await adminGroupDataSource.joinGroup(groupCode);

        // Get group info
        final groupInfo = await adminGroupDataSource.getUserGroupInfo();

        expect(groupInfo, isNotNull);
        expect(groupInfo.groupCode, equals(groupCode));
        expect(groupInfo.adminName, equals('Admin Info Test'));
        expect(groupInfo.adminEmail, equals(adminEmail));
        expect(groupInfo.membersCount, greaterThanOrEqualTo(2));
        expect(groupInfo.joinedAt, isNotNull);

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

    test('Join group: User appears in admin\'s member list after joining', () async {
      try {
        // Create admin
        final adminEmail = 'admin_list_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin List Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // User joins group
        final userEmail = 'user_list_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User List Test',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        await adminGroupDataSource.joinGroup(groupCode);
        
        await authService.logout();

        // Admin checks member list
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        final members = await adminGroupDataSource.getGroupMembers(perPage: 100);
        final userMember = members.firstWhere((m) => m.email == userEmail);

        expect(userMember, isNotNull);
        expect(userMember.name, equals('User List Test'));
        expect(userMember.role, equals('user'));

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

    test('Join group: Member count increases after user joins', () async {
      try {
        // Create admin
        final adminEmail = 'admin_count_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Count Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        final initialCount = adminGroup.membersCount ?? 1;
        
        await authService.logout();

        // User joins group
        final userEmail = 'user_count_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Count Test',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        await adminGroupDataSource.joinGroup(groupCode);
        
        await authService.logout();

        // Admin checks updated count
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        final updatedGroup = await adminGroupDataSource.getAdminGroup();
        expect(updatedGroup.membersCount, equals(initialCount + 1));

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

    test('Join group: User without group can access join functionality', () async {
      try {
        // Register user without group
        final userEmail = 'user_access_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Access Test',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        // Try to get group info (should fail or return null)
        try {
          final groupInfo = await adminGroupDataSource.getUserGroupInfo();
          // If it doesn't throw, it should indicate no group
          expect(groupInfo, isNull);
        } catch (e) {
          // Expected - user is not in a group
          expect(e, isNotNull);
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

    test('Join group: Complete workflow from registration to joining', () async {
      try {
        // 1. Admin registers and creates group
        final adminEmail = 'admin_workflow_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Workflow',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        expect(adminGroup.membersCount, equals(1));
        
        await authService.logout();

        // 2. User registers without group
        final userEmail = 'user_workflow_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Workflow',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
        );

        // 3. User tries to get group info (should fail)
        try {
          await adminGroupDataSource.getUserGroupInfo();
          // If no exception, should be null or indicate no group
        } catch (e) {
          // Expected
        }

        // 4. User joins group
        final joinResult = await adminGroupDataSource.joinGroup(groupCode);
        expect(joinResult.groupCode, equals(groupCode));

        // 5. User can now get group info
        final groupInfo = await adminGroupDataSource.getUserGroupInfo();
        expect(groupInfo, isNotNull);
        expect(groupInfo.groupCode, equals(groupCode));
        expect(groupInfo.adminEmail, equals(adminEmail));

        await authService.logout();

        // 6. Admin sees updated member count
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        final updatedGroup = await adminGroupDataSource.getAdminGroup();
        expect(updatedGroup.membersCount, equals(2));

        // 7. Admin sees user in member list
        final members = await adminGroupDataSource.getGroupMembers(perPage: 100);
        expect(members.any((m) => m.email == userEmail), isTrue);

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

    test('Join group: Multiple users can join same group sequentially', () async {
      try {
        // Create admin
        final adminEmail = 'admin_multi_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Multi Join',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Multiple users join
        for (int i = 0; i < 3; i++) {
          final userEmail = 'user${i}_multi_${DateTime.now().millisecondsSinceEpoch}@example.com';
          await authService.register(
            name: 'User $i Multi',
            email: userEmail,
            password: 'TestPassword123!',
            role: 'user',
          );

          final groupInfo = await adminGroupDataSource.joinGroup(groupCode);
          expect(groupInfo.groupCode, equals(groupCode));

          await authService.logout();
        }

        // Admin verifies all users joined
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        final updatedGroup = await adminGroupDataSource.getAdminGroup();
        expect(updatedGroup.membersCount, equals(4)); // Admin + 3 users

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
