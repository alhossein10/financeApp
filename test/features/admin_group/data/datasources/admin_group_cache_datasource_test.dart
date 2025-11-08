import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/services/cache_service.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_cache_datasource.dart';
import 'package:finance_app/features/admin_group/data/models/admin_group_dto.dart';
import 'package:finance_app/features/admin_group/data/models/group_member_dto.dart';
import 'package:finance_app/features/admin_group/data/models/group_info_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'admin_group_cache_datasource_test.mocks.dart';

@GenerateMocks([CacheService])
void main() {
  late AdminGroupCacheDataSourceImpl dataSource;
  late MockCacheService mockCacheService;

  setUp(() {
    mockCacheService = MockCacheService();
    dataSource = AdminGroupCacheDataSourceImpl(cacheService: mockCacheService);
  });

  group('AdminGroupCacheDataSource', () {
    group('getCachedAdminGroup', () {
      test('should return AdminGroupDto when cache exists', () async {
        // Arrange
        final cachedData = {
          'id': 1,
          'admin_user_id': 10,
          'group_code': 'ABC123',
          'group_name': 'Test Group',
          'is_active': true,
          'members_count': 5,
          'created_at': '2024-01-01T00:00:00.000000Z',
          'updated_at': '2024-01-01T00:00:00.000000Z',
        };

        when(mockCacheService.get<Map<String, dynamic>>(any))
            .thenAnswer((_) async => cachedData);

        // Act
        final result = await dataSource.getCachedAdminGroup();

        // Assert
        verify(mockCacheService.get<Map<String, dynamic>>('admin_group'));
        expect(result, isNotNull);
        expect(result!.id, 1);
        expect(result.groupCode, 'ABC123');
      });

      test('should return null when cache is empty', () async {
        // Arrange
        when(mockCacheService.get<Map<String, dynamic>>(any))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getCachedAdminGroup();

        // Assert
        expect(result, isNull);
      });

      test('should return null when cache throws exception', () async {
        // Arrange
        when(mockCacheService.get<Map<String, dynamic>>(any))
            .thenThrow(Exception('Cache error'));

        // Act
        final result = await dataSource.getCachedAdminGroup();

        // Assert
        expect(result, isNull);
      });
    });

    group('cacheAdminGroup', () {
      test('should cache admin group with correct TTL', () async {
        // Arrange
        final groupDto = AdminGroupDto(
          id: 1,
          adminUserId: 10,
          groupCode: 'ABC123',
          groupName: 'Test Group',
          isActive: true,
          membersCount: 5,
          createdAt: '2024-01-01T00:00:00.000000Z',
          updatedAt: '2024-01-01T00:00:00.000000Z',
        );

        when(mockCacheService.set(any, any, ttl: anyNamed('ttl')))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.cacheAdminGroup(groupDto);

        // Assert
        final captured = verify(mockCacheService.set(
          'admin_group',
          captureAny,
          ttl: captureAnyNamed('ttl'),
        )).captured;

        final cachedData = captured[0] as Map<String, dynamic>;
        final ttl = captured[1] as Duration;

        expect(cachedData['group_code'], 'ABC123');
        expect(ttl, const Duration(minutes: 5));
      });

      test('should not throw when caching fails', () async {
        // Arrange
        final groupDto = AdminGroupDto(
          id: 1,
          adminUserId: 10,
          groupCode: 'ABC123',
          isActive: true,
          createdAt: '2024-01-01T00:00:00.000000Z',
          updatedAt: '2024-01-01T00:00:00.000000Z',
        );

        when(mockCacheService.set(any, any, ttl: anyNamed('ttl')))
            .thenThrow(Exception('Cache error'));

        // Act & Assert
        expect(() => dataSource.cacheAdminGroup(groupDto), returnsNormally);
      });
    });

    group('getCachedGroupMembers', () {
      test('should return cached members list', () async {
        // Arrange
        final cachedData = {
          'data': [
            {
              'id': 1,
              'name': 'John Doe',
              'email': 'john@example.com',
              'role': 'user',
              'organization_name': 'Org 1',
              'department_name': 'IT',
              'created_at': '2024-01-01T00:00:00.000000Z',
            },
          ],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 1,
        };

        when(mockCacheService.get<Map<String, dynamic>>(any))
            .thenAnswer((_) async => cachedData);

        // Act
        final result = await dataSource.getCachedGroupMembers();

        // Assert
        verify(mockCacheService.get<Map<String, dynamic>>('group_members_1_15'));
        expect(result, isNotNull);
        expect(result!.data.length, 1);
        expect(result.data[0].name, 'John Doe');
      });

      test('should use correct cache key for different pages', () async {
        // Arrange
        when(mockCacheService.get<Map<String, dynamic>>(any))
            .thenAnswer((_) async => null);

        // Act
        await dataSource.getCachedGroupMembers(page: 2, perPage: 25);

        // Assert
        verify(mockCacheService.get<Map<String, dynamic>>('group_members_2_25'));
      });

      test('should return null when cache is empty', () async {
        // Arrange
        when(mockCacheService.get<Map<String, dynamic>>(any))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getCachedGroupMembers();

        // Assert
        expect(result, isNull);
      });
    });

    group('cacheGroupMembers', () {
      test('should cache members list with correct TTL', () async {
        // Arrange
        final response = GroupMemberListResponse(
          data: [
            GroupMemberDto(
              id: 1,
              name: 'John Doe',
              email: 'john@example.com',
              role: 'user',
              organizationName: 'Org 1',
              departmentName: 'IT',
              createdAt: '2024-01-01T00:00:00.000000Z',
            ),
          ],
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
        );

        when(mockCacheService.set(any, any, ttl: anyNamed('ttl')))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.cacheGroupMembers(response);

        // Assert
        final captured = verify(mockCacheService.set(
          'group_members_1_15',
          captureAny,
          ttl: captureAnyNamed('ttl'),
        )).captured;

        final cachedData = captured[0] as Map<String, dynamic>;
        final ttl = captured[1] as Duration;

        expect(cachedData['total'], 1);
        expect(ttl, const Duration(minutes: 2));
      });

      test('should use correct cache key for different pages', () async {
        // Arrange
        final response = GroupMemberListResponse(
          data: [],
          currentPage: 3,
          lastPage: 5,
          perPage: 25,
          total: 100,
        );

        when(mockCacheService.set(any, any, ttl: anyNamed('ttl')))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.cacheGroupMembers(response, page: 3, perPage: 25);

        // Assert
        verify(mockCacheService.set(
          'group_members_3_25',
          any,
          ttl: anyNamed('ttl'),
        ));
      });
    });

    group('getCachedUserGroupInfo', () {
      test('should return cached user group info', () async {
        // Arrange
        final cachedData = {
          'group_code': 'ABC123',
          'group_name': 'Test Group',
          'admin_name': 'Admin User',
          'admin_email': 'admin@example.com',
          'members_count': 5,
          'joined_at': '2024-01-01T00:00:00.000000Z',
        };

        when(mockCacheService.get<Map<String, dynamic>>(any))
            .thenAnswer((_) async => cachedData);

        // Act
        final result = await dataSource.getCachedUserGroupInfo();

        // Assert
        verify(mockCacheService.get<Map<String, dynamic>>('user_group_info'));
        expect(result, isNotNull);
        expect(result!.groupCode, 'ABC123');
        expect(result.adminName, 'Admin User');
      });

      test('should return null when cache is empty', () async {
        // Arrange
        when(mockCacheService.get<Map<String, dynamic>>(any))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getCachedUserGroupInfo();

        // Assert
        expect(result, isNull);
      });
    });

    group('cacheUserGroupInfo', () {
      test('should cache user group info with correct TTL', () async {
        // Arrange
        final groupInfo = GroupInfoDto(
          groupCode: 'ABC123',
          groupName: 'Test Group',
          adminName: 'Admin User',
          adminEmail: 'admin@example.com',
          membersCount: 5,
          joinedAt: '2024-01-01T00:00:00.000000Z',
        );

        when(mockCacheService.set(any, any, ttl: anyNamed('ttl')))
            .thenAnswer((_) async => {});

        // Act
        await dataSource.cacheUserGroupInfo(groupInfo);

        // Assert
        final captured = verify(mockCacheService.set(
          'user_group_info',
          captureAny,
          ttl: captureAnyNamed('ttl'),
        )).captured;

        final cachedData = captured[0] as Map<String, dynamic>;
        final ttl = captured[1] as Duration;

        expect(cachedData['group_code'], 'ABC123');
        expect(ttl, const Duration(minutes: 10));
      });
    });

    group('invalidateAdminGroupCache', () {
      test('should delete admin group cache', () async {
        // Arrange
        when(mockCacheService.delete(any)).thenAnswer((_) async => {});

        // Act
        await dataSource.invalidateAdminGroupCache();

        // Assert
        verify(mockCacheService.delete('admin_group'));
      });

      test('should not throw when deletion fails', () async {
        // Arrange
        when(mockCacheService.delete(any)).thenThrow(Exception('Delete error'));

        // Act & Assert
        expect(() => dataSource.invalidateAdminGroupCache(), returnsNormally);
      });
    });

    group('invalidateGroupMembersCache', () {
      test('should delete multiple member cache keys', () async {
        // Arrange
        when(mockCacheService.delete(any)).thenAnswer((_) async => {});

        // Act
        await dataSource.invalidateGroupMembersCache();

        // Assert
        // Should delete cache for common pagination combinations
        verify(mockCacheService.delete('group_members_1_15')).called(1);
        verify(mockCacheService.delete('group_members_1_25')).called(1);
        verify(mockCacheService.delete('group_members_1_50')).called(1);
      });

      test('should not throw when deletion fails', () async {
        // Arrange
        when(mockCacheService.delete(any)).thenThrow(Exception('Delete error'));

        // Act & Assert
        expect(() => dataSource.invalidateGroupMembersCache(), returnsNormally);
      });
    });

    group('invalidateUserGroupInfoCache', () {
      test('should delete user group info cache', () async {
        // Arrange
        when(mockCacheService.delete(any)).thenAnswer((_) async => {});

        // Act
        await dataSource.invalidateUserGroupInfoCache();

        // Assert
        verify(mockCacheService.delete('user_group_info'));
      });
    });

    group('clearAllCache', () {
      test('should clear all group-related caches', () async {
        // Arrange
        when(mockCacheService.delete(any)).thenAnswer((_) async => {});

        // Act
        await dataSource.clearAllCache();

        // Assert
        verify(mockCacheService.delete('admin_group')).called(1);
        verify(mockCacheService.delete('user_group_info')).called(1);
        // Member cache keys should also be deleted
        verify(mockCacheService.delete(argThat(startsWith('group_members_')))).called(greaterThan(0));
      });

      test('should not throw when clearing fails', () async {
        // Arrange
        when(mockCacheService.delete(any)).thenThrow(Exception('Clear error'));

        // Act & Assert
        expect(() => dataSource.clearAllCache(), returnsNormally);
      });
    });
  });
}
