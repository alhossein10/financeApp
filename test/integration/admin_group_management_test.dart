import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration tests for Admin Group Management
/// Tests Requirements: 2.1-2.8, 11.6
/// 
/// These tests verify:
/// - Load and display group information
/// - Load and display member list
/// - Remove member flow
/// - Regenerate code flow
void main() {
  group('Admin Group Management Integration Tests', () {
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

    test('Load group information: Admin can retrieve their group details', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_load_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Load Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Load group information
        final adminGroup = await adminGroupDataSource.getAdminGroup();

        expect(adminGroup, isNotNull);
        expect(adminGroup.groupCode, isNotNull);
        expect(adminGroup.groupCode.length, equals(6));
        expect(adminGroup.isActive, isTrue);
        expect(adminGroup.membersCount, greaterThanOrEqualTo(1));
        expect(adminGroup.createdAt, isNotNull);
        expect(adminGroup.updatedAt, isNotNull);

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

    test('Load member list: Admin can retrieve all group members', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_members_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Members Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Add some users to the group
        final user1Email = 'user1_members_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Test User 1',
          email: user1Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          organizationName: 'Org 1',
          departmentName: 'Dept A',
        );
        await authService.logout();

        final user2Email = 'user2_members_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Test User 2',
          email: user2Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          organizationName: 'Org 1',
          departmentName: 'Dept B',
        );
        await authService.logout();

        // Login as admin and get member list
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        final members = await adminGroupDataSource.getGroupMembers(perPage: 100);

        expect(members, isNotNull);
        expect(members.length, greaterThanOrEqualTo(3)); // Admin + 2 users

        // Verify admin is in the list
        final adminMember = members.firstWhere((m) => m.email == adminEmail);
        expect(adminMember.name, equals('Admin Members Test'));
        expect(adminMember.role, equals('admin'));

        // Verify users are in the list
        final user1Member = members.firstWhere((m) => m.email == user1Email);
        expect(user1Member.name, equals('Test User 1'));
        expect(user1Member.role, equals('user'));
        expect(user1Member.organizationName, equals('Org 1'));
        expect(user1Member.departmentName, equals('Dept A'));

        final user2Member = members.firstWhere((m) => m.email == user2Email);
        expect(user2Member.name, equals('Test User 2'));
        expect(user2Member.departmentName, equals('Dept B'));

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

    test('Member list pagination: Admin can paginate through members', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_page_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Pagination Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Add multiple users
        for (int i = 0; i < 5; i++) {
          final userEmail = 'user${i}_page_${DateTime.now().millisecondsSinceEpoch}@example.com';
          await authService.register(
            name: 'Test User $i',
            email: userEmail,
            password: 'TestPassword123!',
            role: 'user',
            groupCode: groupCode,
          );
          await authService.logout();
        }

        // Login as admin and test pagination
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        // Get first page with 3 items per page
        final page1 = await adminGroupDataSource.getGroupMembers(page: 1, perPage: 3);
        expect(page1.length, equals(3));

        // Get second page
        final page2 = await adminGroupDataSource.getGroupMembers(page: 2, perPage: 3);
        expect(page2.length, greaterThanOrEqualTo(1));

        // Verify no duplicate members between pages
        final page1Ids = page1.map((m) => m.id).toSet();
        final page2Ids = page2.map((m) => m.id).toSet();
        expect(page1Ids.intersection(page2Ids).isEmpty, isTrue);

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

    test('Member list search: Admin can search members by name', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_search_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Search Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Add users with distinct names
        final user1Email = 'user1_search_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Alice Johnson',
          email: user1Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
        );
        await authService.logout();

        final user2Email = 'user2_search_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Bob Smith',
          email: user2Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
        );
        await authService.logout();

        // Login as admin and search
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        // Search for "Alice"
        final searchResults = await adminGroupDataSource.getGroupMembers(
          search: 'Alice',
          perPage: 100,
        );

        expect(searchResults, isNotNull);
        expect(searchResults.any((m) => m.name.contains('Alice')), isTrue);
        // Bob should not be in results
        expect(searchResults.any((m) => m.name.contains('Bob')), isFalse);

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

    test('Member list filter: Admin can filter members by department', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_filter_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Filter Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Add users with different departments
        final user1Email = 'user1_filter_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Sales',
          email: user1Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          departmentName: 'Sales',
        );
        await authService.logout();

        final user2Email = 'user2_filter_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Marketing',
          email: user2Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          departmentName: 'Marketing',
        );
        await authService.logout();

        // Login as admin and filter
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        // Filter by Sales department
        final salesMembers = await adminGroupDataSource.getGroupMembers(
          department: 'Sales',
          perPage: 100,
        );

        expect(salesMembers, isNotNull);
        expect(salesMembers.any((m) => m.departmentName == 'Sales'), isTrue);
        // Marketing user should not be in results
        expect(salesMembers.any((m) => m.departmentName == 'Marketing'), isFalse);

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

    test('Remove member: Admin can remove a user from the group', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_remove_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Remove Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        final initialMemberCount = adminGroup.membersCount ?? 1;
        
        await authService.logout();

        // Add a user
        final userEmail = 'user_remove_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User To Remove',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
        );
        
        // Get user ID
        final userGroupInfo = await adminGroupDataSource.getUserGroupInfo();
        await authService.logout();

        // Login as admin
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        // Get member list and find the user
        final membersBeforeRemove = await adminGroupDataSource.getGroupMembers(perPage: 100);
        final userToRemove = membersBeforeRemove.firstWhere((m) => m.email == userEmail);
        final userId = userToRemove.id;

        // Remove the user
        await adminGroupDataSource.removeMember(userId);

        // Verify user is removed
        final membersAfterRemove = await adminGroupDataSource.getGroupMembers(perPage: 100);
        expect(membersAfterRemove.any((m) => m.id == userId), isFalse);

        // Verify member count decreased
        final updatedGroup = await adminGroupDataSource.getAdminGroup();
        expect(updatedGroup.membersCount, lessThan(initialMemberCount + 1));

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

    test('Remove member: Admin cannot remove themselves', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_self_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final adminUser = await authService.register(
          name: 'Admin Self Remove',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Try to remove self
        try {
          await adminGroupDataSource.removeMember(adminUser.id);
          fail('Expected exception when admin tries to remove themselves');
        } catch (e) {
          // Expect error
          expect(e, isNotNull);
          expect(e.toString().toLowerCase(), anyOf([
            contains('cannot remove'),
            contains('yourself'),
            contains('self'),
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

    test('Remove member: Cannot remove user from different group', () async {
      try {
        // Create Admin 1
        final admin1Email = 'admin1_cross_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Cross',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final admin1Group = await adminGroupDataSource.getAdminGroup();
        final groupCode1 = admin1Group.groupCode;
        
        await authService.logout();

        // Add user to Admin 1's group
        final user1Email = 'user1_cross_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User 1 Cross',
          email: user1Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode1,
        );
        await authService.logout();

        // Login as Admin 1 and get user ID
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        final members1 = await adminGroupDataSource.getGroupMembers(perPage: 100);
        final user1 = members1.firstWhere((m) => m.email == user1Email);
        final user1Id = user1.id;
        await authService.logout();

        // Create Admin 2
        final admin2Email = 'admin2_cross_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Cross',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 tries to remove user from Admin 1's group
        try {
          await adminGroupDataSource.removeMember(user1Id);
          fail('Expected exception when removing user from different group');
        } catch (e) {
          // Expect error
          expect(e, isNotNull);
          expect(e.toString().toLowerCase(), anyOf([
            contains('not found'),
            contains('not in your group'),
            contains('unauthorized'),
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

    test('Regenerate code: Admin can regenerate group code', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_regen_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Regenerate Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Get original code
        final originalGroup = await adminGroupDataSource.getAdminGroup();
        final originalCode = originalGroup.groupCode;

        // Regenerate code
        final regeneratedGroup = await adminGroupDataSource.regenerateGroupCode();
        final newCode = regeneratedGroup.groupCode;

        expect(newCode, isNotNull);
        expect(newCode.length, equals(6));
        expect(newCode, isNot(equals(originalCode)));

        // Verify new code is active
        final verifyGroup = await adminGroupDataSource.getAdminGroup();
        expect(verifyGroup.groupCode, equals(newCode));

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

    test('Regenerate code: Old code becomes invalid after regeneration', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_invalid_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Invalid Code Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Get original code
        final originalGroup = await adminGroupDataSource.getAdminGroup();
        final originalCode = originalGroup.groupCode;

        // Regenerate code
        await adminGroupDataSource.regenerateGroupCode();
        
        await authService.logout();

        // Try to register user with old code
        final userEmail = 'user_invalid_${DateTime.now().millisecondsSinceEpoch}@example.com';
        try {
          await authService.register(
            name: 'User Invalid Code',
            email: userEmail,
            password: 'TestPassword123!',
            role: 'user',
            groupCode: originalCode, // Old code
          );
          fail('Expected exception for invalid old code');
        } catch (e) {
          // Expect validation error
          expect(e, isNotNull);
          expect(e.toString().toLowerCase(), anyOf([
            contains('invalid'),
            contains('not found'),
            contains('group code'),
          ]));
        }
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Regenerate code: Existing members remain in group', () async {
      try {
        // Register as admin
        final adminEmail = 'admin_remain_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Remain Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final originalGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = originalGroup.groupCode;
        
        await authService.logout();

        // Add a user
        final userEmail = 'user_remain_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User Remain',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
        );
        await authService.logout();

        // Login as admin and regenerate code
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        final membersBeforeRegen = await adminGroupDataSource.getGroupMembers(perPage: 100);
        final memberCountBefore = membersBeforeRegen.length;

        await adminGroupDataSource.regenerateGroupCode();

        // Verify members are still there
        final membersAfterRegen = await adminGroupDataSource.getGroupMembers(perPage: 100);
        expect(membersAfterRegen.length, equals(memberCountBefore));
        expect(membersAfterRegen.any((m) => m.email == userEmail), isTrue);

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

    test('Group management: Complete workflow from creation to member management', () async {
      try {
        // 1. Admin registers and group is created
        final adminEmail = 'admin_workflow_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Workflow',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        expect(adminGroup, isNotNull);
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // 2. Multiple users join the group
        final user1Email = 'user1_workflow_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User 1 Workflow',
          email: user1Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          departmentName: 'Sales',
        );
        await authService.logout();

        final user2Email = 'user2_workflow_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'User 2 Workflow',
          email: user2Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          departmentName: 'Marketing',
        );
        await authService.logout();

        // 3. Admin views member list
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        
        final members = await adminGroupDataSource.getGroupMembers(perPage: 100);
        expect(members.length, equals(3)); // Admin + 2 users

        // 4. Admin filters by department
        final salesMembers = await adminGroupDataSource.getGroupMembers(
          department: 'Sales',
          perPage: 100,
        );
        expect(salesMembers.length, equals(1));

        // 5. Admin removes one member
        final user1 = members.firstWhere((m) => m.email == user1Email);
        await adminGroupDataSource.removeMember(user1.id);

        final membersAfterRemove = await adminGroupDataSource.getGroupMembers(perPage: 100);
        expect(membersAfterRemove.length, equals(2));

        // 6. Admin regenerates code
        final newGroup = await adminGroupDataSource.regenerateGroupCode();
        expect(newGroup.groupCode, isNot(equals(groupCode)));

        // 7. Verify remaining member is still in group
        expect(membersAfterRemove.any((m) => m.email == user2Email), isTrue);

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
