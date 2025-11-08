import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/models/sync_changes_dto.dart';

void main() {
  group('EntityChangesDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
        'created': [
          {'id': 1, 'amount': 50.0}
        ],
        'updated': [
          {'id': 2, 'amount': 60.0}
        ],
        'deleted': [3, 4, 5],
      };

      final dto = EntityChangesDto.fromJson(json);

      expect(dto.created.length, 1);
      expect(dto.updated.length, 1);
      expect(dto.deleted.length, 3);
      expect(dto.hasChanges, true);
    });

    test('should handle empty arrays', () {
      final json = {
        'created': [],
        'updated': [],
        'deleted': [],
      };

      final dto = EntityChangesDto.fromJson(json);

      expect(dto.hasChanges, false);
      expect(dto.totalChanges, 0);
    });

    test('should calculate totalChanges correctly', () {
      final dto = EntityChangesDto(
        created: [
          {'id': 1},
          {'id': 2}
        ],
        updated: [
          {'id': 3}
        ],
        deleted: [4, 5],
      );

      expect(dto.totalChanges, 5);
    });
  });

  group('ChangesDataDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
        'expenses': {
          'created': [
            {'id': 1}
          ],
          'updated': [],
          'deleted': [],
        },
        'incoming': {
          'created': [],
          'updated': [],
          'deleted': [],
        },
        'transfers': {
          'created': [],
          'updated': [],
          'deleted': [5],
        },
      };

      final dto = ChangesDataDto.fromJson(json);

      expect(dto.expenses.created.length, 1);
      expect(dto.transfers.deleted.length, 1);
      expect(dto.hasChanges, true);
    });

    test('should calculate totalChanges correctly', () {
      final dto = ChangesDataDto(
        expenses: EntityChangesDto(
          created: [
            {'id': 1}
          ],
          updated: [
            {'id': 2}
          ],
        ),
        incoming: EntityChangesDto(
          deleted: [3],
        ),
        transfers: EntityChangesDto(),
      );

      expect(dto.totalChanges, 3);
    });
  });

  group('SyncChangesDto', () {
    test('should deserialize from JSON correctly', () {
      final json = {
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
      };

      final dto = SyncChangesDto.fromJson(json);

      expect(dto.timestamp, isA<DateTime>());
      expect(dto.changes.expenses.created.length, 1);
      expect(dto.changes.expenses.deleted.length, 1);
    });

    test('should serialize to JSON correctly', () {
      final dto = SyncChangesDto(
        timestamp: DateTime.parse('2024-10-23T10:00:00.000Z'),
        changes: ChangesDataDto(
          expenses: EntityChangesDto(
            created: [
              {'id': 1}
            ],
          ),
          incoming: EntityChangesDto(),
          transfers: EntityChangesDto(),
        ),
      );

      final json = dto.toJson();

      expect(json['timestamp'], isA<String>());
      expect(json['changes'], isA<Map>());
      expect(json['changes']['expenses'], isA<Map>());
    });

    test('should match Laravel API specification format', () {
      final json = {
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
      };

      final dto = SyncChangesDto.fromJson(json);

      // Verify structure matches API spec
      expect(dto.timestamp, isA<DateTime>());
      expect(dto.changes, isA<ChangesDataDto>());
      expect(dto.changes.expenses, isA<EntityChangesDto>());
      expect(dto.changes.incoming, isA<EntityChangesDto>());
      expect(dto.changes.transfers, isA<EntityChangesDto>());
    });
  });
}
