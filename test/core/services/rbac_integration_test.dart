import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/services/role_service.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';
import 'package:finance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:finance_app/core/error/failures.dart';

@GenerateMocks([AuthRepository])
import 'rbac_integration_test.mocks.dart';

void main() {
  late RoleService roleService;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    roleService = RoleService(authRepository: mockAuthRepository);
  });

  final adminUser = User(
    id: 1,
    email: 'admin@test.com',
    name: 'Admin User',
    role: UserRole.admin,
    createdAt: DateTime.now(),
  );

  final regularUser = User(
    id: 2,
    email: 'user@test.com',
    name: 'Regular User',
    role: UserRole.user,
    createdAt: DateTime.now(),
  );

  group('RBAC Integration Tests', () {
    group('Admin-Only Features', () {
      test('should allow admin to access fund box', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final canAccess = await roleService.canAccessFundBox();

        // Assert
        expect(canAccess, true);
      });

      test('should deny regular user access to fund box', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final canAccess = await roleService.canAccessFundBox();

        // Assert
        expect(canAccess, false);
      });

      test('should allow admin to access admin dashboard', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final canAccess = await roleService.canAccessAdminDashboard();

        // Assert
        expect(canAccess, true);
      });

      test('should deny regular user access to admin dashboard', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final canAccess = await roleService.canAccessAdminDashboard();

        // Assert
        expect(canAccess, false);
      });

      test('should allow admin to access audit logs', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final canAccess = await roleService.canAccessAuditLogs();

        // Assert
        expect(canAccess, true);
      });

      test('should deny regular user access to audit logs', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final canAccess = await roleService.canAccessAuditLogs();

        // Assert
        expect(canAccess, false);
      });
    });

    group('Permission Enforcement', () {
      test('should not throw exception when admin requires admin permission', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act & Assert
        await expectLater(
          roleService.requireAdminPermission(),
          completes,
        );
      });

      test('should throw InsufficientPermissionsException when regular user requires admin permission', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act & Assert
        await expectLater(
          roleService.requireAdminPermission(),
          throwsA(isA<InsufficientPermissionsException>()),
        );
      });

      test('should throw InsufficientPermissionsException when unauthenticated user requires admin permission', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Left(AuthenticationFailure('Not authenticated')));

        // Act & Assert
        await expectLater(
          roleService.requireAdminPermission(),
          throwsA(isA<InsufficientPermissionsException>()),
        );
      });
    });

    group('Role Checking', () {
      test('should correctly identify admin user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final isAdmin = await roleService.isAdmin();
        final isUser = await roleService.isUser();

        // Assert
        expect(isAdmin, true);
        expect(isUser, false);
      });

      test('should correctly identify regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final isAdmin = await roleService.isAdmin();
        final isUser = await roleService.isUser();

        // Assert
        expect(isAdmin, false);
        expect(isUser, true);
      });

      test('should return correct role for admin', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final role = await roleService.getCurrentUserRole();

        // Assert
        expect(role, UserRole.admin);
      });

      test('should return correct role for regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final role = await roleService.getCurrentUserRole();

        // Assert
        expect(role, UserRole.user);
      });

      test('should return null role when not authenticated', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Left(AuthenticationFailure('Not authenticated')));

        // Act
        final role = await roleService.getCurrentUserRole();

        // Assert
        expect(role, null);
      });
    });

    group('Cached Role Checking', () {
      test('should correctly check cached admin user', () {
        // Act
        final isAdmin = roleService.isCachedUserAdmin(adminUser);

        // Assert
        expect(isAdmin, true);
      });

      test('should correctly check cached regular user', () {
        // Act
        final isAdmin = roleService.isCachedUserAdmin(regularUser);

        // Assert
        expect(isAdmin, false);
      });

      test('should return false for null cached user', () {
        // Act
        final isAdmin = roleService.isCachedUserAdmin(null);

        // Assert
        expect(isAdmin, false);
      });

      test('should get correct cached role for admin', () {
        // Act
        final role = roleService.getCachedUserRole(adminUser);

        // Assert
        expect(role, UserRole.admin);
      });

      test('should get correct cached role for regular user', () {
        // Act
        final role = roleService.getCachedUserRole(regularUser);

        // Assert
        expect(role, UserRole.user);
      });

      test('should return null for null cached user', () {
        // Act
        final role = roleService.getCachedUserRole(null);

        // Assert
        expect(role, null);
      });
    });

    group('403 Forbidden Error Handling', () {
      test('should handle 403 error when regular user accesses admin endpoint', () {
        // Arrange
        final exception = ForbiddenException(
          message: 'Access denied. Admin privileges required.',
        );

        // Assert
        expect(exception.statusCode, 403);
        expect(exception.isForbiddenError, true);
        expect(exception.getUserFriendlyMessage(), contains('do not have permission'));
      });

      test('should provide appropriate error message for insufficient permissions', () {
        // Arrange
        final exception = InsufficientPermissionsException(
          'Admin privileges required',
        );

        // Assert
        expect(exception.message, 'Admin privileges required');
      });
    });

    group('Feature Access Matrix', () {
      final features = [
        ('Fund Box', (RoleService rs) => rs.canAccessFundBox()),
        ('Admin Dashboard', (RoleService rs) => rs.canAccessAdminDashboard()),
        ('Audit Logs', (RoleService rs) => rs.canAccessAuditLogs()),
      ];

      for (final (featureName, checkAccess) in features) {
        test('admin should have access to $featureName', () async {
          // Arrange
          when(mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => Right(adminUser));

          // Act
          final hasAccess = await checkAccess(roleService);

          // Assert
          expect(hasAccess, true,
              reason: 'Admin should have access to $featureName');
        });

        test('regular user should not have access to $featureName', () async {
          // Arrange
          when(mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => Right(regularUser));

          // Act
          final hasAccess = await checkAccess(roleService);

          // Assert
          expect(hasAccess, false,
              reason: 'Regular user should not have access to $featureName');
        });

        test('unauthenticated user should not have access to $featureName', () async {
          // Arrange
          when(mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => Left(AuthenticationFailure('Not authenticated')));

          // Act
          final hasAccess = await checkAccess(roleService);

          // Assert
          expect(hasAccess, false,
              reason: 'Unauthenticated user should not have access to $featureName');
        });
      }
    });

    group('Role Transition', () {
      test('should handle role change from user to admin', () async {
        // Arrange - Start as regular user
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act - Check initial role
        var role = await roleService.getCurrentUserRole();
        expect(role, UserRole.user);

        // Arrange - Promote to admin
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act - Check new role
        role = await roleService.getCurrentUserRole();

        // Assert
        expect(role, UserRole.admin);
      });

      test('should handle role change from admin to user', () async {
        // Arrange - Start as admin
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act - Check initial role
        var role = await roleService.getCurrentUserRole();
        expect(role, UserRole.admin);

        // Arrange - Demote to user
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act - Check new role
        role = await roleService.getCurrentUserRole();

        // Assert
        expect(role, UserRole.user);
      });
    });

    group('Multiple Concurrent Role Checks', () {
      test('should handle multiple concurrent role checks correctly', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act - Perform multiple checks concurrently
        final results = await Future.wait([
          roleService.isAdmin(),
          roleService.canAccessFundBox(),
          roleService.canAccessAdminDashboard(),
          roleService.canAccessAuditLogs(),
        ]);

        // Assert - All should return true for admin
        expect(results, [true, true, true, true]);
      });

      test('should handle mixed role checks for regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act - Perform multiple checks concurrently
        final results = await Future.wait([
          roleService.isAdmin(),
          roleService.isUser(),
          roleService.canAccessFundBox(),
          roleService.canAccessAdminDashboard(),
        ]);

        // Assert
        expect(results, [false, true, false, false]);
      });
    });
  });
}
