import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_member.dart';
import 'package:finance_app/features/admin_group/domain/repositories/admin_group_repository.dart';
import 'package:finance_app/features/admin_group/domain/usecases/get_group_members_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_group_members_usecase_test.mocks.dart';

@GenerateMocks([AdminGroupRepository])
void main() {
  late GetGroupMembersUseCase useCase;
  late MockAdminGroupRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminGroupRepository();
    useCase = GetGroupMembersUseCase(repository: mockRepository);
  });

  group('GetGroupMembersUseCase', () {
    final tMembers = [
      GroupMember(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user',
        organizationName: 'Org 1',
        departmentName: 'IT',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      ),
      GroupMember(
        id: 2,
        name: 'Jane Smith',
        email: 'jane@example.com',
        role: 'user',
        organizationName: 'Org 1',
        departmentName: 'HR',
        createdAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      ),
    ];

    test('should return list of members with default parameters', () async {
      // Arrange
      const tParams = GetGroupMembersParams();
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => Right(tMembers));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tMembers));
      verify(mockRepository.getGroupMembers(page: 1, perPage: 15));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return list of members with custom pagination', () async {
      // Arrange
      const tParams = GetGroupMembersParams(page: 2, perPage: 20);
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => Right(tMembers));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, Right(tMembers));
      verify(mockRepository.getGroupMembers(page: 2, perPage: 20));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return filtered members with search parameter', () async {
      // Arrange
      const tParams = GetGroupMembersParams(search: 'john');
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
      )).thenAnswer((_) async => Right([tMembers[0]]));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (members) {
          expect(members.length, 1);
          expect(members[0].name, 'John Doe');
        },
      );
      verify(mockRepository.getGroupMembers(
        page: 1,
        perPage: 15,
        search: 'john',
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return filtered members with department parameter', () async {
      // Arrange
      const tParams = GetGroupMembersParams(department: 'IT');
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        department: anyNamed('department'),
      )).thenAnswer((_) async => Right([tMembers[0]]));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (members) {
          expect(members.length, 1);
          expect(members[0].departmentName, 'IT');
        },
      );
      verify(mockRepository.getGroupMembers(
        page: 1,
        perPage: 15,
        department: 'IT',
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return filtered members with both search and department', () async {
      // Arrange
      const tParams = GetGroupMembersParams(
        search: 'john',
        department: 'IT',
      );
      final expectedMembers = [tMembers[0]];
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
        search: anyNamed('search'),
        department: anyNamed('department'),
      )).thenAnswer((_) async => Right(expectedMembers));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (members) {
          expect(members.length, 1);
          expect(members[0].name, 'John Doe');
        },
      );
      verify(mockRepository.getGroupMembers(
        page: 1,
        perPage: 15,
        search: 'john',
        department: 'IT',
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when no members found', () async {
      // Arrange
      const tParams = GetGroupMembersParams();
      const List<GroupMember> emptyList = [];
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => const Right(emptyList));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should return Right'),
        (members) {
          expect(members.isEmpty, true);
        },
      );
      verify(mockRepository.getGroupMembers(page: 1, perPage: 15));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return UnauthorizedFailure when user is not authenticated', () async {
      // Arrange
      const tParams = GetGroupMembersParams();
      const tFailure = UnauthorizedFailure('Authentication required');
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getGroupMembers(page: 1, perPage: 15));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return AuthorizationFailure when user is not an admin', () async {
      // Arrange
      const tParams = GetGroupMembersParams();
      const tFailure = AuthorizationFailure('Access denied. Insufficient permissions.');
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getGroupMembers(page: 1, perPage: 15));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure on network error', () async {
      // Arrange
      const tParams = GetGroupMembersParams();
      const tFailure = NetworkFailure('Network error occurred');
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getGroupMembers(page: 1, perPage: 15));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure on server error', () async {
      // Arrange
      const tParams = GetGroupMembersParams();
      const tFailure = ServerFailure('Server error occurred');
      when(mockRepository.getGroupMembers(
        page: anyNamed('page'),
        perPage: anyNamed('perPage'),
      )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getGroupMembers(page: 1, perPage: 15));
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('GetGroupMembersParams', () {
    test('should have default values', () {
      // Arrange & Act
      const params = GetGroupMembersParams();

      // Assert
      expect(params.page, 1);
      expect(params.perPage, 15);
      expect(params.search, null);
      expect(params.department, null);
    });

    test('should create params with custom values', () {
      // Arrange & Act
      const params = GetGroupMembersParams(
        page: 2,
        perPage: 20,
        search: 'test',
        department: 'IT',
      );

      // Assert
      expect(params.page, 2);
      expect(params.perPage, 20);
      expect(params.search, 'test');
      expect(params.department, 'IT');
    });

    test('should copy with updated values', () {
      // Arrange
      const params = GetGroupMembersParams(page: 1, perPage: 15);

      // Act
      final updated = params.copyWith(page: 2, search: 'test');

      // Assert
      expect(updated.page, 2);
      expect(updated.perPage, 15);
      expect(updated.search, 'test');
      expect(updated.department, null);
    });

    test('should copy with null values preserved', () {
      // Arrange
      const params = GetGroupMembersParams(
        page: 2,
        search: 'test',
        department: 'IT',
      );

      // Act
      final updated = params.copyWith(page: 3);

      // Assert
      expect(updated.page, 3);
      expect(updated.perPage, 15);
      expect(updated.search, 'test');
      expect(updated.department, 'IT');
    });
  });
}
