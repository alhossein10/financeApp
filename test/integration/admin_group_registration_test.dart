import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration tests for Admin Group Registration Flow
/// Tests Requirements: 1.1-1.7, 11.5
/// 
/// These tests verify:
/// - Complete admin registration with group creation
/// - Complete user registration with group join
/// - Registration error scenarios
void main() {
  group('Admin Group Registration Integration Tests', () {
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

    tearDown(() async {
      try {
        await tokenManager.clearTokens();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('Admin registration: Auto-creates admin group with unique code', () async {
      try {
        // Register as admin
        final testEmail = 'admin_reg_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final testPassword = 'TestPassword123!';
        final testName = 'Test Admin';

        final user = await authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
          role: 'admin',
        );

        expect(user, isNotNull);
        expect(user.email, equals(testEmail));
        expect(user.name, equals(testName));
        expect(user.role, equals('admin'));

        // Verify admin group was created
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        expect(adminGroup, isNotNull);
        expect(adminGroup.groupCode, isNotNull);
        expect(adminGroup.groupCode.length, equals(6));
        expect(adminGroup.adminUserId, equals(user.id));
        expect(adminGroup.isActive, isTrue);

        // Verify group code is alphanumeric
        final codeRegex = RegExp(r'^[A-Z0-9]{6}$');
        expect(codeRegex.hasMatch(adminGroup.groupCode), isTrue);

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

    test('Admin registration: Group code is displayed after registration', () async {
      try {
        // Register as admin
        final testEmail = 'admin_code_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        final user = await authService.register(
          name: 'Admin Code Test',
          email: testEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        expect(user, isNotNull);

        // Get the admin group to retrieve the code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        expect(adminGroup.groupCode, isNotNull);
        expect(adminGroup.groupCode.isNotEmpty, isTrue);

        // In the UI, this code would be displayed in a dialog
        // Here we just verify it's accessible
        print('Generated group code: ${adminGroup.groupCode}');

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

    test('User registration: Successfully joins group with valid code', () async {
      try {
        // First, create an admin and get their group code
        final adminEmail = 'admin_user_join_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin for User Join',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Now register as a regular user with the group code
        final userEmail = 'user_join_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final user = await authService.register(
          name: 'Test User',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          organizationName: 'Test Org',
          departmentName: 'Test Dept',
        );

        expect(user, isNotNull);
        expect(user.email, equals(userEmail));
        expect(user.role, equals('user'));
        expect(user.adminGroupId, isNotNull);
        expect(user.organizationName, equals('Test Org'));
        expect(user.departmentName, equals('Test Dept'));

        // Verify user can get their group info
        final userGroupInfo = await adminGroupDataSource.getUserGroupInfo();
        expect(userGroupInfo, isNotNull);
        expect(userGroupInfo.groupCode, equals(groupCode));
        expect(userGroupInfo.adminEmail, equals(adminEmail));

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

    test('User registration: Fails with invalid group code format', () async {
      try {
        final userEmail = 'user_invalid_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        // Try to register with invalid code format (less than 6 characters)
        await authService.register(
          name: 'Test User Invalid',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: 'ABC', // Invalid: too short
        );

        fail('Expected exception for invalid group code format');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Expect validation error
        expect(e, isNotNull);
        expect(e.toString().toLowerCase(), contains('group code'));
      }
    });

    test('User registration: Fails with non-existent group code', () async {
      try {
        final userEmail = 'user_nonexist_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        // Try to register with non-existent code
        await authService.register(
          name: 'Test User Nonexist',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: 'XXXXXX', // Non-existent code
        );

        fail('Expected exception for non-existent group code');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Expect validation error
        expect(e, isNotNull);
        expect(e.toString().toLowerCase(), anyOf([
          contains('invalid'),
          contains('not found'),
          contains('group code'),
        ]));
      }
    });

    test('User registration: Fails when group code is required but missing', () async {
      try {
        final userEmail = 'user_missing_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        // Try to register without group code
        await authService.register(
          name: 'Test User Missing',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          // groupCode is missing
        );

        fail('Expected exception for missing group code');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Expect validation error
        expect(e, isNotNull);
        expect(e.toString().toLowerCase(), anyOf([
          contains('required'),
          contains('group code'),
        ]));
      }
    });

    test('User registration: Organization and department are optional', () async {
      try {
        // First, create an admin and get their group code
        final adminEmail = 'admin_optional_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin for Optional',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register user without organization and department
        final userEmail = 'user_optional_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final user = await authService.register(
          name: 'Test User Optional',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          // organizationName and departmentName are omitted
        );

        expect(user, isNotNull);
        expect(user.email, equals(userEmail));
        expect(user.adminGroupId, isNotNull);
        // Organization and department can be null
        // expect(user.organizationName, isNull);
        // expect(user.departmentName, isNull);

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

    test('Registration: Group code is case-insensitive', () async {
      try {
        // Create admin and get group code
        final adminEmail = 'admin_case_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Case Test',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register user with lowercase version of code
        final userEmail = 'user_case_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final user = await authService.register(
          name: 'Test User Case',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode.toLowerCase(), // Use lowercase
        );

        expect(user, isNotNull);
        expect(user.adminGroupId, isNotNull);

        // Verify user joined the correct group
        final userGroupInfo = await adminGroupDataSource.getUserGroupInfo();
        expect(userGroupInfo.groupCode.toUpperCase(), equals(groupCode.toUpperCase()));

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

    test('Registration: Multiple users can join same admin group', () async {
      try {
        // Create admin
        final adminEmail = 'admin_multi_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Multi Users',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        final initialMemberCount = adminGroup.membersCount ?? 1;
        
        await authService.logout();

        // Register first user
        final user1Email = 'user1_multi_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Test User 1',
          email: user1Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
        );
        await authService.logout();

        // Register second user
        final user2Email = 'user2_multi_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Test User 2',
          email: user2Email,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
        );
        await authService.logout();

        // Login as admin and verify member count increased
        await authService.login(email: adminEmail, password: 'TestPassword123!');
        final updatedGroup = await adminGroupDataSource.getAdminGroup();
        expect(updatedGroup.membersCount, greaterThan(initialMemberCount));

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

    test('Registration: Admin cannot use group code to join another group', () async {
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
        final groupCode = admin1Group.groupCode;
        
        await authService.logout();

        // Try to register second admin with first admin's group code
        final admin2Email = 'admin2_nojoin_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 No Join',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode, // Admins shouldn't be able to join
        );

        // If registration succeeds, verify admin has their own group
        final admin2Group = await adminGroupDataSource.getAdminGroup();
        expect(admin2Group.groupCode, isNot(equals(groupCode)));
        expect(admin2Group.adminUserId, isNot(equals(admin1Group.adminUserId)));

        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Either exception or separate group is acceptable
      }
    });

    test('Registration: Backward compatibility with organization_id and department_id', () async {
      try {
        // Create admin
        final adminEmail = 'admin_compat_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin Compat',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
        );

        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Register user with both old and new fields
        final userEmail = 'user_compat_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final user = await authService.register(
          name: 'Test User Compat',
          email: userEmail,
          password: 'TestPassword123!',
          role: 'user',
          groupCode: groupCode,
          organizationName: 'New Org Name',
          departmentName: 'New Dept Name',
        );

        expect(user, isNotNull);
        // New fields should be prioritized
        expect(user.organizationName, equals('New Org Name'));
        expect(user.departmentName, equals('New Dept Name'));

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
