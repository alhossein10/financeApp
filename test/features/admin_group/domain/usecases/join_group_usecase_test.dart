import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_cache_datasource.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_info.dart';
import 'package:finance_app/features/admin_group/domain/repositories/admin_group_repository.dart';
import 'package:finance_app/features/admin_group/domain/usecases/join_group_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'join_group_usecase_test.mocks.dart';

@GenerateMocks([AdminGroupRepository, AdminGroupCacheDataSource])
void main() {
  late JoinGroupUseCase useCase;
  late MockAdminGroupRepository mockRepository;
  late MockAdminGroupCacheDataSource mockCacheDataSource;

  setUp(() {
    mockRepository = MockAdminGroupRepository();
    mockCacheDataSource = MockAdminGroupCacheDataSource();
    useCase = JoinGroupUseCase(
      repository: mockRepository,
      cacheDataSource: mockCacheDataSource,
    );
  });

  group('JoinGroupUseCase', () {
    final tGroupInfo = GroupInfo(
      groupCode: 'ABC123',
      groupName: 'Test Group',
      adminName: 'Admin User',
      adminEmail: 'admin@example.com',
      membersCount: 5,
      joinedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    );

    group('validation', () {
      test('should return ValidationFailure when group code is empty', () async {
        // Act
        final result = await useCase('');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'The group code field is required');
          },
          (groupInfo) => fail('Should return Left'),
        );
        verifyNever(mockRepository.joinGroup(any));
        verifyNever(mockCacheDataSource.invalidateUserGroupInfoCache());
      });

      test('should return ValidationFailure when group code is only whitespace', () async {
        // Act
        final result = await useCase('   ');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'The group code field is required');
          },
          (groupInfo) => fail('Should return Left'),
        );
        verifyNever(mockRepository.joinGroup(any));
      });

      test('should return ValidationFailure when group code is less than 6 characters', () async {
        // Act
        final result = await useCase('ABC12');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Group code must be exactly 6 alphanumeric characters');
          },
          (groupInfo) => fail('Should return Left'),
        );
        verifyNever(mockRepository.joinGroup(any));
      });

      test('should return ValidationFailure when group code is more than 6 characters', () async {
        // Act
        final result = await useCase('ABC1234');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Group code must be exactly 6 alphanumeric characters');
          },
          (groupInfo) => fail('Should return Left'),
        );
        verifyNever(mockRepository.joinGroup(any));
      });

      test('should return ValidationFailure when group code contains special characters', () async {
        // Act
        final result = await useCase('ABC@12');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Group code must be exactly 6 alphanumeric characters');
          },
          (groupInfo) => fail('Should return Left'),
        );
        verifyNever(mockRepository.joinGroup(any));
      });

      test('should return ValidationFailure when group code contains spaces', () async {
        // Act
        final result = await useCase('ABC 12');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Group code must be exactly 6 alphanumeric characters');
          },
          (groupInfo) => fail('Should return Left'),
        );
        verifyNever(mockRepository.joinGroup(any));
      });

      test('should accept valid alphanumeric group code', () async {
        // Arrange
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => Right(tGroupInfo));
        when(mockCacheDataSource.invalidateUserGroupInfoCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result.isRight(), true);
        verify(mockRepository.joinGroup('ABC123'));
      });

      test('should accept group code with uppercase letters', () async {
        // Arrange
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => Right(tGroupInfo));
        when(mockCacheDataSource.invalidateUserGroupInfoCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await useCase('ABCDEF');

        // Assert
        expect(result.isRight(), true);
        verify(mockRepository.joinGroup('ABCDEF'));
      });

      test('should accept group code with lowercase letters', () async {
        // Arrange
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => Right(tGroupInfo));
        when(mockCacheDataSource.invalidateUserGroupInfoCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await useCase('abcdef');

        // Assert
        expect(result.isRight(), true);
        verify(mockRepository.joinGroup('abcdef'));
      });

      test('should accept group code with only numbers', () async {
        // Arrange
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => Right(tGroupInfo));
        when(mockCacheDataSource.invalidateUserGroupInfoCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await useCase('123456');

        // Assert
        expect(result.isRight(), true);
        verify(mockRepository.joinGroup('123456'));
      });

      test('should trim whitespace from group code', () async {
        // Arrange
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => Right(tGroupInfo));
        when(mockCacheDataSource.invalidateUserGroupInfoCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await useCase('  ABC123  ');

        // Assert
        expect(result.isRight(), true);
        verify(mockRepository.joinGroup('ABC123'));
      });
    });

    group('successful join', () {
      test('should join group and invalidate cache on success', () async {
        // Arrange
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => Right(tGroupInfo));
        when(mockCacheDataSource.invalidateUserGroupInfoCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result, Right(tGroupInfo));
        verify(mockRepository.joinGroup('ABC123'));
        verify(mockCacheDataSource.invalidateUserGroupInfoCache());
        verifyNoMoreInteractions(mockRepository);
        verifyNoMoreInteractions(mockCacheDataSource);
      });

      test('should return GroupInfo with correct data', () async {
        // Arrange
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => Right(tGroupInfo));
        when(mockCacheDataSource.invalidateUserGroupInfoCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (groupInfo) {
            expect(groupInfo.groupCode, 'ABC123');
            expect(groupInfo.groupName, 'Test Group');
            expect(groupInfo.adminName, 'Admin User');
            expect(groupInfo.adminEmail, 'admin@example.com');
            expect(groupInfo.membersCount, 5);
          },
        );
      });
    });

    group('error handling', () {
      test('should not invalidate cache on failure', () async {
        // Arrange
        const tFailure = ServerFailure('Failed to join group');
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result, const Left(tFailure));
        verify(mockRepository.joinGroup('ABC123'));
        verifyNever(mockCacheDataSource.invalidateUserGroupInfoCache());
      });

      test('should return UnauthorizedFailure when user is not authenticated', () async {
        // Arrange
        const tFailure = UnauthorizedFailure('Authentication required');
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result, const Left(tFailure));
        verify(mockRepository.joinGroup('ABC123'));
        verifyNever(mockCacheDataSource.invalidateUserGroupInfoCache());
      });

      test('should return AuthorizationFailure when admin tries to join', () async {
        // Arrange
        const tFailure = AuthorizationFailure('Admins cannot join other groups');
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result, const Left(tFailure));
        verify(mockRepository.joinGroup('ABC123'));
        verifyNever(mockCacheDataSource.invalidateUserGroupInfoCache());
      });

      test('should return ApiFailure when user is already in a group', () async {
        // Arrange
        const tFailure = ApiFailure('You are already in a group');
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result, const Left(tFailure));
        verify(mockRepository.joinGroup('ABC123'));
        verifyNever(mockCacheDataSource.invalidateUserGroupInfoCache());
      });

      test('should return NotFoundFailure when group code does not exist', () async {
        // Arrange
        const tFailure = NotFoundFailure('Group not found');
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result, const Left(tFailure));
        verify(mockRepository.joinGroup('ABC123'));
        verifyNever(mockCacheDataSource.invalidateUserGroupInfoCache());
      });

      test('should return NetworkFailure on network error', () async {
        // Arrange
        const tFailure = NetworkFailure('Network error occurred');
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result, const Left(tFailure));
        verify(mockRepository.joinGroup('ABC123'));
        verifyNever(mockCacheDataSource.invalidateUserGroupInfoCache());
      });

      test('should return ServerFailure on server error', () async {
        // Arrange
        const tFailure = ServerFailure('Server error occurred');
        when(mockRepository.joinGroup(any))
            .thenAnswer((_) async => const Left(tFailure));

        // Act
        final result = await useCase('ABC123');

        // Assert
        expect(result, const Left(tFailure));
        verify(mockRepository.joinGroup('ABC123'));
        verifyNever(mockCacheDataSource.invalidateUserGroupInfoCache());
      });
    });
  });
}
