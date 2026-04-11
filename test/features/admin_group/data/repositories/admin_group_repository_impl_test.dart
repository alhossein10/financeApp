import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/core/error/failures.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_cache_datasource.dart';
import 'package:finance_app/features/admin_group/data/models/admin_group_dto.dart';
import 'package:finance_app/features/admin_group/data/models/group_member_dto.dart';
import 'package:finance_app/features/admin_group/data/models/group_info_dto.dart';
import 'package:finance_app/features/admin_group/data/repositories/admin_group_repository_impl.dart';
import 'package:finance_app/features/admin_group/domain/entities/admin_group.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_member.dart';
import 'package:finance_app/features/admin_group/domain/entities/group_info.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'admin_group_repository_impl_test.mocks.dart';

@GenerateMocks([AdminGroupApiDataSource, AdminGroupCacheDataSource])
void main() {
  late AdminGroupRepositoryImpl repository;
  late MockAdminGroupApiDataSource mockApiDataSource;
  late MockAdminGroupCacheDataSource mockCacheDataSource;

  setUp(() {
    mockApiDataSource = MockAdminGroupApiDataSource();
    mockCacheDataSource = MockAdminGroupCacheDataSource();
    repository = AdminGroupRepositoryImpl(
      apiDataSource: mockApiDataSource,
      cacheDataSource: mockCacheDataSource,
    );
  });

  group('AdminGroupRepository', () {
    group('getAdminGroup', () {
      final tAdminGroupDto = AdminGroupDto(
        id: 1,
        adminUserId: 10,
        groupCode: 'ABC123',
        groupName: 'Test Group',
        isActive: true,
        membersCount: 5,
        createdAt: '2024-01-01T00:00:00.000000Z',
        updatedAt: '2024-01-01T00:00:00.000000Z',
      );

      test('should return cached data when cache is available', () async {
        // Arrange
        when(mockCacheDataSource.getCachedAdminGroup())
            .thenAnswer((_) async => tAdminGroupDto);

        // Act
        final result = await repository.getAdminGroup();

        // Assert
        verify(mockCacheDataSource.getCachedAdminGroup());
        verifyNever(mockApiDataSource.getAdminGroup());
        verifyNever(mockCacheDataSource.cacheAdminGroup(any));
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (adminGroup) {
            expect(adminGroup, isA<AdminGroup>());
            expect(adminGroup.id, 1);
            expect(adminGroup.groupCode, 'ABC123');
            expect(adminGroup.groupName, 'Test Group');
            expect(adminGroup.membersCount, 5);
          },
        );
      });

      test('should fetch from API and cache when cache is empty', () async {
        // Arrange
        when(mockCacheDataSource.getCachedAdminGroup())
            .thenAnswer((_) async => null);
        when(mockApiDataSource.getAdminGroup())
            .thenAnswer((_) async => tAdminGroupDto);
        when(mockCacheDataSource.cacheAdminGroup(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getAdminGroup();

        // Assert
        verify(mockCacheDataSource.getCachedAdminGroup());
        verify(mockApiDataSource.getAdminGroup());
        verify(mockCacheDataSource.cacheAdminGroup(tAdminGroupDto));
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (adminGroup) {
            expect(adminGroup.id, 1);
            expect(adminGroup.groupCode, 'ABC123');
          },
        );
      });

      test('should return UnauthorizedFailure on 401 error', () async {
        // Arrange
        when(mockCacheDataSource.getCachedAdminGroup())
            .thenAnswer((_) async => null);
        when(mockApiDataSource.getAdminGroup())
            .thenThrow(ApiException(
              message: 'Unauthorized',
              statusCode: 401,
            ));

        // Act
        final result = await repository.getAdminGroup();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<UnauthorizedFailure>());
            expect(failure.message, 'Authentication required');
          },
          (adminGroup) => fail('Should return Left'),
        );
      });

      test('should return AuthorizationFailure on 403 error', () async {
        // Arrange
        when(mockCacheDataSource.getCachedAdminGroup())
            .thenAnswer((_) async => null);
        when(mockApiDataSource.getAdminGroup())
            .thenThrow(ApiException(
              message: 'Forbidden',
              statusCode: 403,
            ));

        // Act
        final result = await repository.getAdminGroup();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<AuthorizationFailure>());
            expect(failure.message, 'Access denied. Insufficient permissions.');
          },
          (adminGroup) => fail('Should return Left'),
        );
      });

      test('should return ServerFailure on generic exception', () async {
        // Arrange
        when(mockCacheDataSource.getCachedAdminGroup())
            .thenAnswer((_) async => null);
        when(mockApiDataSource.getAdminGroup())
            .thenThrow(Exception('Something went wrong'));

        // Act
        final result = await repository.getAdminGroup();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to get admin group'));
          },
          (adminGroup) => fail('Should return Left'),
        );
      });
    });

    group('regenerateGroupCode', () {
      final tAdminGroupDto = AdminGroupDto(
        id: 1,
        adminUserId: 10,
        groupCode: 'XYZ789',
        groupName: 'Test Group',
        isActive: true,
        membersCount: 5,
        createdAt: '2024-01-01T00:00:00.000000Z',
        updatedAt: '2024-01-02T00:00:00.000000Z',
      );

      test('should regenerate code and update cache', () async {
        // Arrange
        when(mockApiDataSource.regenerateGroupCode())
            .thenAnswer((_) async => tAdminGroupDto);
        when(mockCacheDataSource.invalidateAdminGroupCache())
            .thenAnswer((_) async => {});
        when(mockCacheDataSource.cacheAdminGroup(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.regenerateGroupCode();

        // Assert
        verify(mockApiDataSource.regenerateGroupCode());
        verify(mockCacheDataSource.invalidateAdminGroupCache());
        verify(mockCacheDataSource.cacheAdminGroup(tAdminGroupDto));
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (adminGroup) {
            expect(adminGroup.groupCode, 'XYZ789');
          },
        );
      });

      test('should return ServerFailure on error', () async {
        // Arrange
        when(mockApiDataSource.regenerateGroupCode())
            .thenThrow(Exception('Failed to regenerate'));

        // Act
        final result = await repository.regenerateGroupCode();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to regenerate group code'));
          },
          (adminGroup) => fail('Should return Left'),
        );
      });
    });

    group('getGroupMembers', () {
      final tMemberDtos = [
        GroupMemberDto(
          id: 1,
          name: 'John Doe',
          email: 'john@example.com',
          role: 'user',
          organizationName: 'Org 1',
          departmentName: 'IT',
          createdAt: '2024-01-01T00:00:00.000000Z',
        ),
        GroupMemberDto(
          id: 2,
          name: 'Jane Smith',
          email: 'jane@example.com',
          role: 'user',
          organizationName: 'Org 1',
          departmentName: 'HR',
          createdAt: '2024-01-02T00:00:00.000000Z',
        ),
      ];

      final tMemberListResponse = GroupMemberListResponse(
        data: tMemberDtos,
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 2,
      );

      test('should return cached members for first page without filters', () async {
        // Arrange
        when(mockCacheDataSource.getCachedGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenAnswer((_) async => tMemberListResponse);

        // Act
        final result = await repository.getGroupMembers(page: 1, perPage: 15);

        // Assert
        verify(mockCacheDataSource.getCachedGroupMembers(page: 1, perPage: 15));
        verifyNever(mockApiDataSource.getGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        ));
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (members) {
            expect(members, isA<List<GroupMember>>());
            expect(members.length, 2);
            expect(members[0].name, 'John Doe');
            expect(members[1].name, 'Jane Smith');
          },
        );
      });

      test('should fetch from API when cache is empty', () async {
        // Arrange
        when(mockCacheDataSource.getCachedGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenAnswer((_) async => null);
        when(mockApiDataSource.getGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenAnswer((_) async => tMemberListResponse);
        when(mockCacheDataSource.cacheGroupMembers(
          any,
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenAnswer((_) async => {});

        // Act
        final result = await repository.getGroupMembers(page: 1, perPage: 15);

        // Assert
        verify(mockApiDataSource.getGroupMembers(page: 1, perPage: 15));
        verify(mockCacheDataSource.cacheGroupMembers(
          tMemberListResponse,
          page: 1,
          perPage: 15,
        ));
        
        expect(result.isRight(), true);
      });

      test('should skip cache when search filter is provided', () async {
        // Arrange
        when(mockApiDataSource.getGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          search: anyNamed('search'),
        )).thenAnswer((_) async => tMemberListResponse);

        // Act
        final result = await repository.getGroupMembers(
          page: 1,
          perPage: 15,
          search: 'john',
        );

        // Assert
        verifyNever(mockCacheDataSource.getCachedGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        ));
        verify(mockApiDataSource.getGroupMembers(
          page: 1,
          perPage: 15,
          search: 'john',
        ));
        verifyNever(mockCacheDataSource.cacheGroupMembers(
          any,
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        ));
        
        expect(result.isRight(), true);
      });

      test('should skip cache when department filter is provided', () async {
        // Arrange
        when(mockApiDataSource.getGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          department: anyNamed('department'),
        )).thenAnswer((_) async => tMemberListResponse);

        // Act
        final result = await repository.getGroupMembers(
          page: 1,
          perPage: 15,
          department: 'IT',
        );

        // Assert
        verifyNever(mockCacheDataSource.getCachedGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        ));
        verify(mockApiDataSource.getGroupMembers(
          page: 1,
          perPage: 15,
          department: 'IT',
        ));
        
        expect(result.isRight(), true);
      });

      test('should skip cache for pages other than first', () async {
        // Arrange
        when(mockApiDataSource.getGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenAnswer((_) async => tMemberListResponse);

        // Act
        final result = await repository.getGroupMembers(page: 2, perPage: 15);

        // Assert
        verifyNever(mockCacheDataSource.getCachedGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        ));
        verify(mockApiDataSource.getGroupMembers(page: 2, perPage: 15));
        
        expect(result.isRight(), true);
      });

      test('should return ServerFailure on error', () async {
        // Arrange
        when(mockCacheDataSource.getCachedGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenAnswer((_) async => null);
        when(mockApiDataSource.getGroupMembers(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenThrow(Exception('Failed to fetch'));

        // Act
        final result = await repository.getGroupMembers();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to get group members'));
          },
          (members) => fail('Should return Left'),
        );
      });
    });

    group('removeMember', () {
      test('should remove member and invalidate caches', () async {
        // Arrange
        when(mockApiDataSource.removeMember(any))
            .thenAnswer((_) async => {});
        when(mockCacheDataSource.invalidateGroupMembersCache())
            .thenAnswer((_) async => {});
        when(mockCacheDataSource.invalidateAdminGroupCache())
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.removeMember(123);

        // Assert
        verify(mockApiDataSource.removeMember(123));
        verify(mockCacheDataSource.invalidateGroupMembersCache());
        verify(mockCacheDataSource.invalidateAdminGroupCache());
        
        expect(result.isRight(), true);
      });

      test('should return AuthorizationFailure when trying to remove self', () async {
        // Arrange
        when(mockApiDataSource.removeMember(any))
            .thenThrow(ApiException(
              message: 'You cannot remove yourself from the group',
              statusCode: 403,
            ));

        // Act
        final result = await repository.removeMember(123);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<AuthorizationFailure>());
            expect(failure.message, contains('cannot remove'));
          },
          (_) => fail('Should return Left'),
        );
      });

      test('should return NotFoundFailure on 404 error', () async {
        // Arrange
        when(mockApiDataSource.removeMember(any))
            .thenThrow(ApiException(
              message: 'User not found',
              statusCode: 404,
            ));

        // Act
        final result = await repository.removeMember(123);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<NotFoundFailure>());
          },
          (_) => fail('Should return Left'),
        );
      });

      test('should return ServerFailure on generic error', () async {
        // Arrange
        when(mockApiDataSource.removeMember(any))
            .thenThrow(Exception('Failed to remove'));

        // Act
        final result = await repository.removeMember(123);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to remove member'));
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('joinGroup', () {
      final tGroupInfoDto = GroupInfoDto(
        groupCode: 'ABC123',
        groupName: 'Test Group',
        adminName: 'Admin User',
        adminEmail: 'admin@example.com',
        membersCount: 5,
        joinedAt: '2024-01-01T00:00:00.000000Z',
      );

      test('should join group and cache result', () async {
        // Arrange
        when(mockApiDataSource.joinGroup(any))
            .thenAnswer((_) async => tGroupInfoDto);
        when(mockCacheDataSource.cacheUserGroupInfo(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.joinGroup('ABC123');

        // Assert
        verify(mockApiDataSource.joinGroup('ABC123'));
        verify(mockCacheDataSource.cacheUserGroupInfo(tGroupInfoDto));
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (groupInfo) {
            expect(groupInfo, isA<GroupInfo>());
            expect(groupInfo.groupCode, 'ABC123');
            expect(groupInfo.adminName, 'Admin User');
          },
        );
      });

      test('should return ValidationFailure when group code is empty', () async {
        // Act
        final result = await repository.joinGroup('');

        // Assert
        verifyNever(mockApiDataSource.joinGroup(any));
        
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'The group code field is required');
          },
          (groupInfo) => fail('Should return Left'),
        );
      });

      test('should return ValidationFailure when group code is not 6 characters', () async {
        // Act
        final result = await repository.joinGroup('ABC12');

        // Assert
        verifyNever(mockApiDataSource.joinGroup(any));
        
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, 'Group code must be exactly 6 characters');
          },
          (groupInfo) => fail('Should return Left'),
        );
      });

      test('should return ValidationFailure on 422 error', () async {
        // Arrange
        when(mockApiDataSource.joinGroup(any))
            .thenThrow(ApiException(
              message: 'The selected group code is invalid',
              statusCode: 422,
            ));

        // Act
        final result = await repository.joinGroup('ABC123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('invalid'));
          },
          (groupInfo) => fail('Should return Left'),
        );
      });

      test('should return ApiFailure when already in group', () async {
        // Arrange
        when(mockApiDataSource.joinGroup(any))
            .thenThrow(ApiException(
              message: 'You are already in a group',
              statusCode: 400,
            ));

        // Act
        final result = await repository.joinGroup('ABC123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ApiFailure>());
            expect(failure.message, contains('already in'));
          },
          (groupInfo) => fail('Should return Left'),
        );
      });

      test('should return AuthorizationFailure when admin tries to join', () async {
        // Arrange
        when(mockApiDataSource.joinGroup(any))
            .thenThrow(ApiException(
              message: 'Admins cannot join other groups',
              statusCode: 403,
            ));

        // Act
        final result = await repository.joinGroup('ABC123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<AuthorizationFailure>());
            expect(failure.message, 'Admins cannot join other groups');
          },
          (groupInfo) => fail('Should return Left'),
        );
      });

      test('should return ServerFailure on generic error', () async {
        // Arrange
        when(mockApiDataSource.joinGroup(any))
            .thenThrow(Exception('Failed to join'));

        // Act
        final result = await repository.joinGroup('ABC123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to join group'));
          },
          (groupInfo) => fail('Should return Left'),
        );
      });
    });

    group('getUserGroupInfo', () {
      final tGroupInfoDto = GroupInfoDto(
        groupCode: 'ABC123',
        groupName: 'Test Group',
        adminName: 'Admin User',
        adminEmail: 'admin@example.com',
        membersCount: 5,
        joinedAt: '2024-01-01T00:00:00.000000Z',
      );

      test('should return cached group info when available', () async {
        // Arrange
        when(mockCacheDataSource.getCachedUserGroupInfo())
            .thenAnswer((_) async => tGroupInfoDto);

        // Act
        final result = await repository.getUserGroupInfo();

        // Assert
        verify(mockCacheDataSource.getCachedUserGroupInfo());
        verifyNever(mockApiDataSource.getUserGroupInfo());
        
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (groupInfo) {
            expect(groupInfo.groupCode, 'ABC123');
            expect(groupInfo.adminName, 'Admin User');
          },
        );
      });

      test('should fetch from API and cache when cache is empty', () async {
        // Arrange
        when(mockCacheDataSource.getCachedUserGroupInfo())
            .thenAnswer((_) async => null);
        when(mockApiDataSource.getUserGroupInfo())
            .thenAnswer((_) async => tGroupInfoDto);
        when(mockCacheDataSource.cacheUserGroupInfo(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.getUserGroupInfo();

        // Assert
        verify(mockCacheDataSource.getCachedUserGroupInfo());
        verify(mockApiDataSource.getUserGroupInfo());
        verify(mockCacheDataSource.cacheUserGroupInfo(tGroupInfoDto));
        
        expect(result.isRight(), true);
      });

      test('should return NotFoundFailure when user not in group', () async {
        // Arrange
        when(mockCacheDataSource.getCachedUserGroupInfo())
            .thenAnswer((_) async => null);
        when(mockApiDataSource.getUserGroupInfo())
            .thenThrow(ApiException(
              message: 'You are not in any group',
              statusCode: 404,
            ));

        // Act
        final result = await repository.getUserGroupInfo();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<NotFoundFailure>());
          },
          (groupInfo) => fail('Should return Left'),
        );
      });

      test('should return NetworkFailure on network error', () async {
        // Arrange
        when(mockCacheDataSource.getCachedUserGroupInfo())
            .thenAnswer((_) async => null);
        when(mockApiDataSource.getUserGroupInfo())
            .thenThrow(ApiException(
              message: 'Network error',
              statusCode: null,
            ));

        // Act
        final result = await repository.getUserGroupInfo();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'Network error occurred');
          },
          (groupInfo) => fail('Should return Left'),
        );
      });

      test('should return ServerFailure on 500 error', () async {
        // Arrange
        when(mockCacheDataSource.getCachedUserGroupInfo())
            .thenAnswer((_) async => null);
        when(mockApiDataSource.getUserGroupInfo())
            .thenThrow(ApiException(
              message: 'Internal server error',
              statusCode: 500,
            ));

        // Act
        final result = await repository.getUserGroupInfo();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
          },
          (groupInfo) => fail('Should return Left'),
        );
      });
    });
  });
}
