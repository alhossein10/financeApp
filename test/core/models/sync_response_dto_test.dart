import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/models/sync_response_dto.dart';

void main() {
  group('CreatedItemDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
        'local_id': 'temp-1',
        'server_id': 456,
        'data': {
          'id': 456,
          'amount': 50.0,
          'category': 'Food',
        },
      };

      final dto = CreatedItemDto.fromJson(json);

      expect(dto.localId, 'temp-1');
      expect(dto.serverId, 456);
      expect(dto.data['amount'], 50.0);
    });

    test('should serialize to JSON correctly', () {
      final dto = CreatedItemDto(
        localId: 'temp-1',
        serverId: 456,
        data: {'amount': 50.0},
      );

      final json = dto.toJson();

      expect(json['local_id'], 'temp-1');
      expect(json['server_id'], 456);
      expect(json['data'], isA<Map>());
    });
  });

  group('ConflictItemDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
        'local_id': 'temp-1',
        'server_id': 123,
        'local_data': {'amount': 50.0},
        'server_data': {'amount': 60.0},
        'reason': 'Data mismatch',
      };

      final dto = ConflictItemDto.fromJson(json);

      expect(dto.localId, 'temp-1');
      expect(dto.serverId, 123);
      expect(dto.localData['amount'], 50.0);
      expect(dto.serverData['amount'], 60.0);
      expect(dto.reason, 'Data mismatch');
    });

    test('should handle optional fields', () {
      final json = {
        'local_data': {'amount': 50.0},
        'server_data': {'amount': 60.0},
        'reason': 'Conflict',
      };

      final dto = ConflictItemDto.fromJson(json);

      expect(dto.localId, isNull);
      expect(dto.serverId, isNull);
    });
  });

  group('EntitySyncResultDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
        'created': [
          {
            'local_id': 'temp-1',
            'server_id': 456,
            'data': {'amount': 50.0}
          }
        ],
        'conflicts': [
          {
            'local_id': 'temp-2',
            'local_data': {'amount': 30.0},
            'server_data': {'amount': 35.0},
            'reason': 'Mismatch'
          }
        ],
      };

      final dto = EntitySyncResultDto.fromJson(json);

      expect(dto.created.length, 1);
      expect(dto.conflicts.length, 1);
      expect(dto.hasConflicts, true);
      expect(dto.hasCreated, true);
    });

    test('should handle empty arrays', () {
      final json = {
        'created': [],
        'conflicts': [],
      };

      final dto = EntitySyncResultDto.fromJson(json);

      expect(dto.created.length, 0);
      expect(dto.conflicts.length, 0);
      expect(dto.hasConflicts, false);
      expect(dto.hasCreated, false);
    });

    test('should calculate totals correctly', () {
      final dto = EntitySyncResultDto(
        created: [
          CreatedItemDto(
            localId: 'temp-1',
            serverId: 1,
            data: {},
          ),
          CreatedItemDto(
            localId: 'temp-2',
            serverId: 2,
            data: {},
          ),
        ],
        conflicts: [
          ConflictItemDto(
            localData: {},
            serverData: {},
            reason: 'test',
          ),
        ],
      );

      expect(dto.totalCreated, 2);
      expect(dto.totalConflicts, 1);
    });
  });

  group('SyncResponseDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
        'synced_at': '2024-10-23T10:00:00.000000Z',
        'expenses': {
          'created': [
            {
              'local_id': 'temp-1',
              'server_id': 456,
              'data': {'amount': 50.0}
            }
          ],
          'conflicts': [],
        },
        'incoming': {
          'created': [],
          'conflicts': [],
        },
        'transfers': {
          'created': [],
          'conflicts': [],
        },
      };

      final dto = SyncResponseDto.fromJson(json);

      expect(dto.syncedAt, isA<DateTime>());
      expect(dto.expenses.created.length, 1);
      expect(dto.totalCreated, 1);
      expect(dto.totalConflicts, 0);
    });

    test('should calculate hasConflicts correctly', () {
      final dtoWithConflicts = SyncResponseDto(
        syncedAt: DateTime.now(),
        expenses: EntitySyncResultDto(
          conflicts: [
            ConflictItemDto(
              localData: {},
              serverData: {},
              reason: 'test',
            ),
          ],
        ),
        incoming: EntitySyncResultDto(),
        transfers: EntitySyncResultDto(),
      );

      expect(dtoWithConflicts.hasConflicts, true);

      final dtoWithoutConflicts = SyncResponseDto(
        syncedAt: DateTime.now(),
        expenses: EntitySyncResultDto(),
        incoming: EntitySyncResultDto(),
        transfers: EntitySyncResultDto(),
      );

      expect(dtoWithoutConflicts.hasConflicts, false);
    });

    test('should aggregate all conflicts', () {
      final dto = SyncResponseDto(
        syncedAt: DateTime.now(),
        expenses: EntitySyncResultDto(
          conflicts: [
            ConflictItemDto(
              localData: {},
              serverData: {},
              reason: 'expense conflict',
            ),
          ],
        ),
        incoming: EntitySyncResultDto(
          conflicts: [
            ConflictItemDto(
              localData: {},
              serverData: {},
              reason: 'incoming conflict',
            ),
          ],
        ),
        transfers: EntitySyncResultDto(),
      );

      expect(dto.allConflicts.length, 2);
      expect(dto.totalConflicts, 2);
    });

    test('should match Laravel API specification format', () {
      final json = {
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
      };

      final dto = SyncResponseDto.fromJson(json);

      // Verify structure matches API spec
      expect(dto.syncedAt, isA<DateTime>());
      expect(dto.expenses, isA<EntitySyncResultDto>());
      expect(dto.incoming, isA<EntitySyncResultDto>());
      expect(dto.transfers, isA<EntitySyncResultDto>());
    });
  });
}
