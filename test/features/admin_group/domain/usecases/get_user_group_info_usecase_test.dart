import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_info.dart';
import 'package:finance_app/features/admin_group/domain/repositories/admin_group_repository.dart';
import 'package:finance_app/features/admin_group/domain/usecases/get_user_group_info_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_user_group_info_usecase_test.mocks.dart';

@GenerateMocks([AdminGroupRepository])
void main() {
  late GetUserGroupInfoUseCase useCase;
  late MockAdminGroupRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminGroupRepository();
    useCase = GetUserGroupInfoUseCase(repository: mockRepository);
  });

  group('GetUserGroupInfoUseCase', () {
    final tGroupInfo = GroupInfo(
      groupCode: 'ABC123',
      groupName: 'Test Group',
      adminName: 'Admin User',
      adminEmail: 'admin@example.com',
      membersCount: 5,
      joinedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
    );

    test('should return GroupInfo from repository on success', () async {
      // Arrange
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => Right(tGroupInfo));

      // Act
      final result = await useCase();

      // Assert
      expect(result, Right(tGroupInfo));
      verify(mockRepository.getUserGroupInfo());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return GroupInfo with correct data', () async {
      // Arrange
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => Right(tGroupInfo));

      // Act
      final result = await useCase();

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
          expect(groupInfo.joinedAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
        },
      );
      verify(mockRepository.getUserGroupInfo());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return GroupInfo with null group name', () async {
      // Arrange
      final tGroupInfoWithoutName = GroupInfo(
        groupCode: 'ABC123',
        groupName: null,
        adminName: 'Admin User',
        adminEmail: 'admin@example.com',
        membersCount: 5,
        joinedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => Right(tGroupInfoWithoutName));

      // Act
      final result = await useCase();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (groupInfo) {
          expect(groupInfo.groupCode, 'ABC123');
          expect(groupInfo.groupName, null);
          expect(groupInfo.adminName, 'Admin User');
        },
      );
    });

    test('should return UnauthorizedFailure when user is not authenticated', () async {
      // Arrange
      const tFailure = UnauthorizedFailure('Authentication required');
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getUserGroupInfo());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NotFoundFailure when user is not in any group', () async {
      // Arrange
      const tFailure = NotFoundFailure('You are not in any group');
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getUserGroupInfo());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      const tFailure = NetworkFailure('Network error occurred');
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getUserGroupInfo());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      const tFailure = ServerFailure('Server error occurred');
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getUserGroupInfo());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle multiple consecutive calls', () async {
      // Arrange
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => Right(tGroupInfo));

      // Act
      final result1 = await useCase();
      final result2 = await useCase();
      final result3 = await useCase();

      // Assert
      expect(result1, Right(tGroupInfo));
      expect(result2, Right(tGroupInfo));
      expect(result3, Right(tGroupInfo));
      verify(mockRepository.getUserGroupInfo()).called(3);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle failure after successful call', () async {
      // Arrange
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => Right(tGroupInfo));

      // Act - First call succeeds
      final result1 = await useCase();

      // Arrange - Second call fails
      const tFailure = NetworkFailure('Network error occurred');
      when(mockRepository.getUserGroupInfo())
          .thenAnswer((_) async => const Left(tFailure));

      // Act - Second call
      final result2 = await useCase();

      // Assert
      expect(result1, Right(tGroupInfo));
      expect(result2, const Left(tFailure));
      verify(mockRepository.getUserGroupInfo()).called(2);
    });
  });
}
