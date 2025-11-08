import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_cache_datasource.dart';
import 'package:finance_app/features/admin_group/domain/repositories/admin_group_repository.dart';
import 'package:finance_app/features/admin_group/domain/usecases/remove_group_member_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'remove_group_member_usecase_test.mocks.dart';

@GenerateMocks([AdminGroupRepository, AdminGroupCacheDataSource])
void main() {
  late RemoveGroupMemberUseCase useCase;
  late MockAdminGroupRepository mockRepository;
  late MockAdminGroupCacheDataSource mockCacheDataSource;

  setUp(() {
    mockRepository = MockAdminGroupRepository();
    mockCacheDataSource = MockAdminGroupCacheDataSource();
    useCase = RemoveGroupMemberUseCase(
      repository: mockRepository,
      cacheDataSource: mockCacheDataSource,
    );
  });

  group('RemoveGroupMemberUseCase', () {
    const tUserId = 123;

    test('should remove member and invalidate cache on success', () async {
      // Arrange
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Right(null));
      when(mockCacheDataSource.invalidateGroupMembersCache())
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Right(null));
      verify(mockRepository.removeMember(tUserId));
      verify(mockCacheDataSource.invalidateGroupMembersCache());
      verifyNoMoreInteractions(mockRepository);
      verifyNoMoreInteractions(mockCacheDataSource);
    });

    test('should not invalidate cache on failure', () async {
      // Arrange
      const tFailure = ServerFailure('Failed to remove member');
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.removeMember(tUserId));
      verifyNever(mockCacheDataSource.invalidateGroupMembersCache());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return UnauthorizedFailure when user is not authenticated', () async {
      // Arrange
      const tFailure = UnauthorizedFailure('Authentication required');
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.removeMember(tUserId));
      verifyNever(mockCacheDataSource.invalidateGroupMembersCache());
    });

    test('should return AuthorizationFailure when user is not an admin', () async {
      // Arrange
      const tFailure = AuthorizationFailure('Access denied. Insufficient permissions.');
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.removeMember(tUserId));
      verifyNever(mockCacheDataSource.invalidateGroupMembersCache());
    });

    test('should return AuthorizationFailure when trying to remove self', () async {
      // Arrange
      const tFailure = AuthorizationFailure('You cannot remove yourself from the group');
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.removeMember(tUserId));
      verifyNever(mockCacheDataSource.invalidateGroupMembersCache());
    });

    test('should return NotFoundFailure when member not found', () async {
      // Arrange
      const tFailure = NotFoundFailure('User not found or not in your group');
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.removeMember(tUserId));
      verifyNever(mockCacheDataSource.invalidateGroupMembersCache());
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      const tFailure = NetworkFailure('Network error occurred');
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.removeMember(tUserId));
      verifyNever(mockCacheDataSource.invalidateGroupMembersCache());
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      const tFailure = ServerFailure('Server error occurred');
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tUserId);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.removeMember(tUserId));
      verifyNever(mockCacheDataSource.invalidateGroupMembersCache());
    });

    test('should handle different user IDs correctly', () async {
      // Arrange
      const tUserId1 = 100;
      const tUserId2 = 200;
      when(mockRepository.removeMember(any))
          .thenAnswer((_) async => const Right(null));
      when(mockCacheDataSource.invalidateGroupMembersCache())
          .thenAnswer((_) async => {});

      // Act
      final result1 = await useCase(tUserId1);
      final result2 = await useCase(tUserId2);

      // Assert
      expect(result1, const Right(null));
      expect(result2, const Right(null));
      verify(mockRepository.removeMember(tUserId1));
      verify(mockRepository.removeMember(tUserId2));
      verify(mockCacheDataSource.invalidateGroupMembersCache()).called(2);
    });
  });
}
