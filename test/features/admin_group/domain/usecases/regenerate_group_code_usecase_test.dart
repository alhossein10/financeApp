import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_cache_datasource.dart';
import 'package:finance_app/features/admin_group/domain/entities/admin_group.dart';
import 'package:finance_app/features/admin_group/domain/repositories/admin_group_repository.dart';
import 'package:finance_app/features/admin_group/domain/usecases/regenerate_group_code_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'regenerate_group_code_usecase_test.mocks.dart';

@GenerateMocks([AdminGroupRepository, AdminGroupCacheDataSource])
void main() {
  late RegenerateGroupCodeUseCase useCase;
  late MockAdminGroupRepository mockRepository;
  late MockAdminGroupCacheDataSource mockCacheDataSource;

  setUp(() {
    mockRepository = MockAdminGroupRepository();
    mockCacheDataSource = MockAdminGroupCacheDataSource();
    useCase = RegenerateGroupCodeUseCase(
      repository: mockRepository,
      cacheDataSource: mockCacheDataSource,
    );
  });

  group('RegenerateGroupCodeUseCase', () {
    final tAdminGroup = AdminGroup(
      id: 1,
      adminUserId: 10,
      groupCode: 'XYZ789',
      groupName: 'Test Group',
      isActive: true,
      membersCount: 5,
      createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
    );

    test('should regenerate code and invalidate cache on success', () async {
      // Arrange
      when(mockRepository.regenerateGroupCode())
          .thenAnswer((_) async => Right(tAdminGroup));
      when(mockCacheDataSource.invalidateAdminGroupCache())
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase();

      // Assert
      expect(result, Right(tAdminGroup));
      verify(mockRepository.regenerateGroupCode());
      verify(mockCacheDataSource.invalidateAdminGroupCache());
      verifyNoMoreInteractions(mockRepository);
      verifyNoMoreInteractions(mockCacheDataSource);
    });

    test('should not invalidate cache on failure', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to regenerate');
      when(mockRepository.regenerateGroupCode())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.regenerateGroupCode());
      verifyNever(mockCacheDataSource.invalidateAdminGroupCache());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return UnauthorizedFailure when user is not authenticated', () async {
      // Arrange
      const tFailure = UnauthorizedFailure('Authentication required');
      when(mockRepository.regenerateGroupCode())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.regenerateGroupCode());
      verifyNever(mockCacheDataSource.invalidateAdminGroupCache());
    });

    test('should return AuthorizationFailure when user is not an admin', () async {
      // Arrange
      const tFailure = AuthorizationFailure('Access denied. Insufficient permissions.');
      when(mockRepository.regenerateGroupCode())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.regenerateGroupCode());
      verifyNever(mockCacheDataSource.invalidateAdminGroupCache());
    });

    test('should return NotFoundFailure when admin has no group', () async {
      // Arrange
      const tFailure = NotFoundFailure('Admin group not found');
      when(mockRepository.regenerateGroupCode())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.regenerateGroupCode());
      verifyNever(mockCacheDataSource.invalidateAdminGroupCache());
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      const tFailure = NetworkFailure('Network error occurred');
      when(mockRepository.regenerateGroupCode())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.regenerateGroupCode());
      verifyNever(mockCacheDataSource.invalidateAdminGroupCache());
    });
  });
}
