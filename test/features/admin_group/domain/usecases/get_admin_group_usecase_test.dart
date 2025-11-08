import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/features/admin_group/domain/entities/admin_group.dart';
import 'package:finance_app/features/admin_group/domain/repositories/admin_group_repository.dart';
import 'package:finance_app/features/admin_group/domain/usecases/get_admin_group_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_admin_group_usecase_test.mocks.dart';

@GenerateMocks([AdminGroupRepository])
void main() {
  late GetAdminGroupUseCase useCase;
  late MockAdminGroupRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminGroupRepository();
    useCase = GetAdminGroupUseCase(repository: mockRepository);
  });

  group('GetAdminGroupUseCase', () {
    final tAdminGroup = AdminGroup(
      id: 1,
      adminUserId: 10,
      groupCode: 'ABC123',
      groupName: 'Test Group',
      isActive: true,
      membersCount: 5,
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    );

    test('should return AdminGroup from repository on success', () async {
      // Arrange
      when(mockRepository.getAdminGroup())
          .thenAnswer((_) async => Right(tAdminGroup));

      // Act
      final result = await useCase();

      // Assert
      expect(result, Right(tAdminGroup));
      verify(mockRepository.getAdminGroup());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return UnauthorizedFailure when user is not authenticated', () async {
      // Arrange
      const tFailure = UnauthorizedFailure('Authentication required');
      when(mockRepository.getAdminGroup())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getAdminGroup());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return AuthorizationFailure when user is not an admin', () async {
      // Arrange
      const tFailure = AuthorizationFailure('Access denied. Insufficient permissions.');
      when(mockRepository.getAdminGroup())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getAdminGroup());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NotFoundFailure when admin has no group', () async {
      // Arrange
      const tFailure = NotFoundFailure('Admin group not found');
      when(mockRepository.getAdminGroup())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getAdminGroup());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      const tFailure = NetworkFailure('Network error occurred');
      when(mockRepository.getAdminGroup())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getAdminGroup());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      const tFailure = ServerFailure('Server error occurred');
      when(mockRepository.getAdminGroup())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getAdminGroup());
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
