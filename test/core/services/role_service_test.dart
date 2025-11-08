import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/services/role_service.dart';
import 'package:finance_app/features/auth/domain/entities/user.dart';
import 'package:finance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:finance_app/core/error/failures.dart';

@GenerateMocks([AuthRepository])
import 'role_service_test.mocks.dart';

void main() {
  late RoleService roleService;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    roleService = RoleService(authRepository: mockAuthRepository);
  });

  group('RoleService', () {
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

    group('isAdmin', () {
      test('should return true when user is admin', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final result = await roleService.isAdmin();

        // Assert
        expect(result, true);
        verify(mockAuthRepository.getCurrentUser());
      });

      test('should return false when user is not admin', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final result = await roleService.isAdmin();

        // Assert
        expect(result, false);
        verify(mockAuthRepository.getCurrentUser());
      });

      test('should return false when user is not authenticated', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Left(AuthenticationFailure('Not authenticated')));

        // Act
        final result = await roleService.isAdmin();

        // Assert
        expect(result, false);
        verify(mockAuthRepository.getCurrentUser());
      });
    });

    group('isUser', () {
      test('should return true when user has user role', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final result = await roleService.isUser();

        // Assert
        expect(result, true);
        verify(mockAuthRepository.getCurrentUser());
      });

      test('should return false when user is admin', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final result = await roleService.isUser();

        // Assert
        expect(result, false);
        verify(mockAuthRepository.getCurrentUser());
      });
    });

    group('getCurrentUserRole', () {
      test('should return admin role for admin user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final result = await roleService.getCurrentUserRole();

        // Assert
        expect(result, UserRole.admin);
        verify(mockAuthRepository.getCurrentUser());
      });

      test('should return user role for regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final result = await roleService.getCurrentUserRole();

        // Assert
        expect(result, UserRole.user);
        verify(mockAuthRepository.getCurrentUser());
      });

      test('should return null when not authenticated', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Left(AuthenticationFailure('Not authenticated')));

        // Act
        final result = await roleService.getCurrentUserRole();

        // Assert
        expect(result, null);
        verify(mockAuthRepository.getCurrentUser());
      });
    });

    group('canAccessAdminFeatures', () {
      test('should return true for admin user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final result = await roleService.canAccessAdminFeatures();

        // Assert
        expect(result, true);
      });

      test('should return false for regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final result = await roleService.canAccessAdminFeatures();

        // Assert
        expect(result, false);
      });
    });

    group('canAccessFundBox', () {
      test('should return true for admin user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final result = await roleService.canAccessFundBox();

        // Assert
        expect(result, true);
      });

      test('should return false for regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final result = await roleService.canAccessFundBox();

        // Assert
        expect(result, false);
      });
    });

    group('canAccessAdminDashboard', () {
      test('should return true for admin user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final result = await roleService.canAccessAdminDashboard();

        // Assert
        expect(result, true);
      });

      test('should return false for regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final result = await roleService.canAccessAdminDashboard();

        // Assert
        expect(result, false);
      });
    });

    group('canAccessAuditLogs', () {
      test('should return true for admin user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act
        final result = await roleService.canAccessAuditLogs();

        // Assert
        expect(result, true);
      });

      test('should return false for regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act
        final result = await roleService.canAccessAuditLogs();

        // Assert
        expect(result, false);
      });
    });

    group('requireAdminPermission', () {
      test('should not throw exception for admin user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(adminUser));

        // Act & Assert
        expect(
          () async => await roleService.requireAdminPermission(),
          returnsNormally,
        );
      });

      test('should throw InsufficientPermissionsException for regular user', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Right(regularUser));

        // Act & Assert
        expect(
          () async => await roleService.requireAdminPermission(),
          throwsA(isA<InsufficientPermissionsException>()),
        );
      });

      test('should throw InsufficientPermissionsException when not authenticated', () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => Left(AuthenticationFailure('Not authenticated')));

        // Act & Assert
        expect(
          () async => await roleService.requireAdminPermission(),
          throwsA(isA<InsufficientPermissionsException>()),
        );
      });
    });

    group('getCachedUserRole', () {
      test('should return admin role for admin user', () {
        // Act
        final result = roleService.getCachedUserRole(adminUser);

        // Assert
        expect(result, UserRole.admin);
      });

      test('should return user role for regular user', () {
        // Act
        final result = roleService.getCachedUserRole(regularUser);

        // Assert
        expect(result, UserRole.user);
      });

      test('should return null for null user', () {
        // Act
        final result = roleService.getCachedUserRole(null);

        // Assert
        expect(result, null);
      });
    });

    group('isCachedUserAdmin', () {
      test('should return true for admin user', () {
        // Act
        final result = roleService.isCachedUserAdmin(adminUser);

        // Assert
        expect(result, true);
      });

      test('should return false for regular user', () {
        // Act
        final result = roleService.isCachedUserAdmin(regularUser);

        // Assert
        expect(result, false);
      });

      test('should return false for null user', () {
        // Act
        final result = roleService.isCachedUserAdmin(null);

        // Assert
        expect(result, false);
      });
    });
  });
}
