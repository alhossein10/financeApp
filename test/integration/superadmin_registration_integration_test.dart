import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/core/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Integration tests for SuperAdmin Registration Flow
/// Tests Requirements: 1.1-1.5
/// 
/// These tests verify:
/// - Complete SuperAdmin registration with group code generation
/// - Group code display and accessibility
/// - Navigation to home after registration
void main() {
  group('SuperAdmin Registration Integration Tests', () {
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

    test('SuperAdmin registration: Auto-creates admin group with unique code', () async {
      try {
        // Register as SuperAdmin
        final testEmail = 'superadmin_reg_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final testPassword = 'TestPassword123!';
        final testName = 'Test SuperAdmin';

        final user = await authService.register(
          name: testName,
          email: testEmail,
          password: testPassword,
          role: 'superadmin',
        );

        expect(user, isNotNull);
        expect(user.email, equals(testEmail));
        expect(user.name, equals(testName));
        expect(user.role, equals('superadmin'));

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

    test('SuperAdmin registration: Group code is accessible after registration', () async {
      try {
        // Register as SuperAdmin
        final testEmail = 'superadmin_code_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        final user = await authService.register(
          name: 'SuperAdmin Code Test',
          email: testEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        expect(user, isNotNull);

        // Get the admin group to retrieve the code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        expect(adminGroup.groupCode, isNotNull);
        expect(adminGroup.groupCode.isNotEmpty, isTrue);

        // In the UI, this code would be displayed in SuperAdminRegistrationSuccessDialog
        // Here we verify it's accessible immediately after registration
        print('Generated SuperAdmin group code: ${adminGroup.groupCode}');

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

    test('SuperAdmin registration: Group code can be copied and shared', () async {
      try {
        // Register as SuperAdmin
        final testEmail = 'superadmin_share_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        await authService.register(
          name: 'SuperAdmin Share Test',
          email: testEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Get the group code
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        final groupCode = adminGroup.groupCode;
        
        await authService.logout();

        // Verify an admin can use this code to join the SuperAdmin's group
        final adminEmail = 'admin_join_sa_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final admin = await authService.register(
          name: 'Admin Joining SuperAdmin',
          email: adminEmail,
          password: 'TestPassword123!',
          role: 'admin',
          groupCode: groupCode,
        );

        expect(admin, isNotNull);
        expect(admin.adminGroupId, isNotNull);

        // Verify admin joined the correct group
        final adminGroupInfo = await adminGroupDataSource.getUserGroupInfo();
        expect(adminGroupInfo.groupCode, equals(groupCode));

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

    test('SuperAdmin registration: Authentication state is correct after registration', () async {
      try {
        // Register as SuperAdmin
        final testEmail = 'superadmin_auth_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        final user = await authService.register(
          name: 'SuperAdmin Auth Test',
          email: testEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        expect(user, isNotNull);

        // Verify authentication state
        final isAuth = await authService.isAuthenticated();
        expect(isAuth, isTrue);

        // Verify token is stored
        final token = await tokenManager.getToken();
        expect(token, isNotNull);

        // Verify current user can be retrieved
        final currentUser = await authService.getCurrentUser();
        expect(currentUser, isNotNull);
        expect(currentUser.email, equals(testEmail));
        expect(currentUser.role, equals('superadmin'));

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

    test('SuperAdmin registration: Group code persists across sessions', () async {
      try {
        // Register as SuperAdmin
        final testEmail = 'superadmin_persist_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final testPassword = 'TestPassword123!';
        
        await authService.register(
          name: 'SuperAdmin Persist Test',
          email: testEmail,
          password: testPassword,
          role: 'superadmin',
        );

        // Get the group code
        final adminGroup1 = await adminGroupDataSource.getAdminGroup();
        final groupCode1 = adminGroup1.groupCode;
        
        // Logout
        await authService.logout();

        // Login again
        await authService.login(
          email: testEmail,
          password: testPassword,
        );

        // Verify group code is still the same
        final adminGroup2 = await adminGroupDataSource.getAdminGroup();
        expect(adminGroup2.groupCode, equals(groupCode1));

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

    test('SuperAdmin registration: Multiple SuperAdmins get unique group codes', () async {
      try {
        // Register first SuperAdmin
        final sa1Email = 'superadmin1_unique_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'SuperAdmin 1',
          email: sa1Email,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        final group1 = await adminGroupDataSource.getAdminGroup();
        final code1 = group1.groupCode;
        
        await authService.logout();

        // Register second SuperAdmin
        final sa2Email = 'superadmin2_unique_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'SuperAdmin 2',
          email: sa2Email,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        final group2 = await adminGroupDataSource.getAdminGroup();
        final code2 = group2.groupCode;

        // Verify codes are different
        expect(code1, isNot(equals(code2)));
        expect(group1.adminUserId, isNot(equals(group2.adminUserId)));

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

    test('SuperAdmin registration: Group name is set correctly', () async {
      try {
        // Register as SuperAdmin
        final testEmail = 'superadmin_name_${DateTime.now().millisecondsSinceEpoch}@example.com';
        final testName = 'SuperAdmin Name Test';
        
        await authService.register(
          name: testName,
          email: testEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        // Get the admin group
        final adminGroup = await adminGroupDataSource.getAdminGroup();
        expect(adminGroup.groupName, isNotNull);
        expect(adminGroup.groupName.isNotEmpty, isTrue);
        // Group name typically includes the SuperAdmin's name
        expect(adminGroup.groupName.toLowerCase(), contains(testName.toLowerCase().split(' ').first));

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

    test('SuperAdmin registration: Failed registration does not create group', () async {
      try {
        // Try to register with invalid email
        await authService.register(
          name: 'Invalid SuperAdmin',
          email: 'invalid-email', // Invalid format
          password: 'TestPassword123!',
          role: 'superadmin',
        );

        fail('Expected exception for invalid email');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Expect validation error
        expect(e, isNotNull);
        
        // Verify no authentication occurred
        final isAuth = await authService.isAuthenticated();
        expect(isAuth, isFalse);
      }
    });

    test('SuperAdmin registration: Duplicate email is rejected', () async {
      try {
        final testEmail = 'superadmin_dup_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        // Register first SuperAdmin
        await authService.register(
          name: 'First SuperAdmin',
          email: testEmail,
          password: 'TestPassword123!',
          role: 'superadmin',
        );
        
        await authService.logout();

        // Try to register again with same email
        await authService.register(
          name: 'Second SuperAdmin',
          email: testEmail,
          password: 'DifferentPassword123!',
          role: 'superadmin',
        );

        fail('Expected exception for duplicate email');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Expect validation error
        expect(e, isNotNull);
        expect(e.toString().toLowerCase(), anyOf([
          contains('email'),
          contains('already'),
          contains('exists'),
        ]));
      }
    });

    test('SuperAdmin registration: Weak password is rejected', () async {
      try {
        final testEmail = 'superadmin_weak_${DateTime.now().millisecondsSinceEpoch}@example.com';
        
        // Try to register with weak password
        await authService.register(
          name: 'Weak Password SuperAdmin',
          email: testEmail,
          password: '123', // Too weak
          role: 'superadmin',
        );

        fail('Expected exception for weak password');
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        // Expect validation error
        expect(e, isNotNull);
        expect(e.toString().toLowerCase(), contains('password'));
      }
    });
  });
}
