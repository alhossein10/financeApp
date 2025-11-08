import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:finance_app/core/services/batch_sync_service.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/models/sync_request_dto.dart';
import 'package:finance_app/core/models/sync_response_dto.dart';
import 'package:finance_app/core/models/sync_changes_dto.dart';
import 'package:finance_app/core/api/api_exception.dart';

@GenerateMocks([ApiClient])
import 'batch_sync_service_test.mocks.dart';

void main() {
  late BatchSyncService service;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    service = BatchSyncService(apiClient: mockApiClient);
  });

  group('BatchSyncService - batchSync', () {
    test('should successfully sync data and return response', () async {
      // Arrange
      final lastSync = DateTime.parse('2024-10-23T09:00:00.000Z');
      final data = SyncDataDto(
        expenses: [
          {
            'local_id': 'temp-1',
            'amount': 50.0,
            'category': 'Food',
            'date': '2024-10-23'
          }
        ],
      );

      final mockResponse = {
        'data': {
          'synced_at': '2024-10-23T10:00:00.000000Z',
          'expenses': {
            'created': [
              {
                'local_id': 'temp-1',
                'server_id': 456,
                'data': {
                  'id': 456,
                  'amount': 50.0,
                  'category': 'Food'
                }
              }
            ],
            'conflicts': []
          },
          'incoming': {
            'created': [],
            'conflicts': []
          },
          'transfers': {
            'created': [],
            'conflicts': []
          }
        }
      };

      when(mockApiClient.post(
        any,
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse(
            statusCode: 200,
            data: mockResponse,
          ));

      // Act
      final result = await service.batchSync(
        lastSync: lastSync,
        data: data,
      );

      // Assert
      expect(result, isA<SyncResponseDto>());
      expect(result.expenses.created.length, 1);
      expect(result.expenses.created.first.localId, 'temp-1');
      expect(result.expenses.created.first.serverId, 456);
      expect(result.totalCreated, 1);
      expect(result.totalConflicts, 0);

      verify(mockApiClient.post(
        '/sync/batch',
        body: anyNamed('body'),
      )).called(1);
    });

    test('should handle conflicts in response', () async {
      // Arrange
      final lastSync = DateTime.parse('2024-10-23T09:00:00.000Z');
      final data = SyncDataDto(
        expenses: [
          {'local_id': 'temp-1', 'amount': 50.0}
        ],
      );

      final mockResponse = {
        'data': {
          'synced_at': '2024-10-23T10:00:00.000000Z',
          'expenses': {
            'created': [],
            'conflicts': [
              {
                'local_id': 'temp-1',
                'local_data': {'amount': 50.0},
                'server_data': {'amount': 60.0},
                'reason': 'Data mismatch'
              }
            ]
          },
          'incoming': {
            'created': [],
            'conflicts': []
          },
          'transfers': {
            'created': [],
            'conflicts': []
          }
        }
      };

      when(mockApiClient.post(
        any,
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse(
            statusCode: 200,
            data: mockResponse,
          ));

      // Act
      final result = await service.batchSync(
        lastSync: lastSync,
        data: data,
      );

      // Assert
      expect(result.hasConflicts, true);
      expect(result.totalConflicts, 1);
      expect(result.expenses.conflicts.first.reason, 'Data mismatch');
    });

    test('should throw ApiException on error', () async {
      // Arrange
      final lastSync = DateTime.parse('2024-10-23T09:00:00.000Z');
      final data = SyncDataDto(expenses: []);

      when(mockApiClient.post(
        any,
        body: anyNamed('body'),
      )).thenThrow(ApiException(
        statusCode: 500,
        message: 'Server error',
      ));

      // Act & Assert
      expect(
        () => service.batchSync(lastSync: lastSync, data: data),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('BatchSyncService - getChanges', () {
    test('should successfully fetch changes', () async {
      // Arrange
      final since = DateTime.parse('2024-10-23T09:00:00.000Z');

      final mockResponse = {
        'data': {
          'timestamp': '2024-10-23T10:00:00.000000Z',
          'changes': {
            'expenses': {
              'created': [
                {
                  'id': 456,
                  'amount': 50.0,
                  'created_at': '2024-10-23T09:30:00.000000Z'
                }
              ],
              'updated': [],
              'deleted': [123]
            },
            'incoming': {
              'created': [],
              'updated': [],
              'deleted': []
            },
            'transfers': {
              'created': [],
              'updated': [],
              'deleted': []
            }
          }
        }
      };

      when(mockApiClient.get(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => MockResponse(
            statusCode: 200,
            data: mockResponse,
          ));

      // Act
      final result = await service.getChanges(since: since);

      // Assert
      expect(result, isA<SyncChangesDto>());
      expect(result.changes.expenses.created.length, 1);
      expect(result.changes.expenses.deleted.length, 1);

      verify(mockApiClient.get(
        '/sync/changes',
        queryParams: anyNamed('queryParams'),
      )).called(1);
    });

    test('should throw ApiException on error', () async {
      // Arrange
      final since = DateTime.parse('2024-10-23T09:00:00.000Z');

      when(mockApiClient.get(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenThrow(ApiException(
        statusCode: 500,
        message: 'Server error',
      ));

      // Act & Assert
      expect(
        () => service.getChanges(since: since),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('BatchSyncService - fullSync', () {
    test('should perform full sync successfully', () async {
      // Arrange
      final lastSync = DateTime.parse('2024-10-23T09:00:00.000Z');
      final localChanges = SyncDataDto(
        expenses: [
          {'local_id': 'temp-1', 'amount': 50.0}
        ],
      );

      final pushResponse = {
        'data': {
          'synced_at': '2024-10-23T10:00:00.000000Z',
          'expenses': {
            'created': [
              {
                'local_id': 'temp-1',
                'server_id': 456,
                'data': {'id': 456}
              }
            ],
            'conflicts': []
          },
          'incoming': {'created': [], 'conflicts': []},
          'transfers': {'created': [], 'conflicts': []}
        }
      };

      final pullResponse = {
        'data': {
          'timestamp': '2024-10-23T10:00:00.000000Z',
          'changes': {
            'expenses': {
              'created': [],
              'updated': [],
              'deleted': []
            },
            'incoming': {
              'created': [],
              'updated': [],
              'deleted': []
            },
            'transfers': {
              'created': [],
              'updated': [],
              'deleted': []
            }
          }
        }
      };

      when(mockApiClient.post(
        any,
        body: anyNamed('body'),
      )).thenAnswer((_) async => MockResponse(
            statusCode: 200,
            data: pushResponse,
          ));

      when(mockApiClient.get(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => MockResponse(
            statusCode: 200,
            data: pullResponse,
          ));

      // Act
      final result = await service.fullSync(
        lastSync: lastSync,
        localChanges: localChanges,
      );

      // Assert
      expect(result.success, true);
      expect(result.pushResponse, isNotNull);
      expect(result.pullResponse, isNotNull);
      expect(result.totalCreated, 1);
    });

    test('should handle errors in full sync', () async {
      // Arrange
      final lastSync = DateTime.parse('2024-10-23T09:00:00.000Z');
      final localChanges = SyncDataDto();

      when(mockApiClient.post(
        any,
        body: anyNamed('body'),
      )).thenThrow(ApiException(
        statusCode: 500,
        message: 'Server error',
      ));

      // Act
      final result = await service.fullSync(
        lastSync: lastSync,
        localChanges: localChanges,
      );

      // Assert
      expect(result.success, false);
      expect(result.error, isNotNull);
    });
  });
}

// Mock response class for testing
class MockResponse {
  final int statusCode;
  final Map<String, dynamic> data;

  MockResponse({
    required this.statusCode,
    required this.data,
  });
}
