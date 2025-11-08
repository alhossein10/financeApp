import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/models/sync_request_dto.dart';

void main() {
  group('SyncDataDto', () {
    test('should serialize to JSON correctly', () {
      final dto = SyncDataDto(
        expenses: [
          {'local_id': 'temp-1', 'amount': 50.0, 'category': 'Food'},
        ],
        incoming: [
          {'local_id': 'temp-2', 'amount': 100.0, 'source': 'Salary'},
        ],
        transfers: [],
      );

      final json = dto.toJson();

      expect(json['expenses'], isA<List>());
      expect(json['expenses'].length, 1);
      expect(json['incoming'].length, 1);
      expect(json['transfers'].length, 0);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'expenses': [
          {'local_id': 'temp-1', 'amount': 50.0}
        ],
        'incoming': [],
        'transfers': [],
      };

      final dto = SyncDataDto.fromJson(json);

      expect(dto.expenses.length, 1);
      expect(dto.incoming.length, 0);
      expect(dto.transfers.length, 0);
    });

    test('should calculate isEmpty correctly', () {
      final emptyDto = SyncDataDto();
      expect(emptyDto.isEmpty, true);

      final nonEmptyDto = SyncDataDto(
        expenses: [
          {'amount': 50.0}
        ],
      );
      expect(nonEmptyDto.isEmpty, false);
    });

    test('should calculate totalCount correctly', () {
      final dto = SyncDataDto(
        expenses: [
          {'amount': 50.0},
          {'amount': 30.0}
        ],
        incoming: [
          {'amount': 100.0}
        ],
        transfers: [],
      );

      expect(dto.totalCount, 3);
    });
  });

  group('SyncRequestDto', () {
    test('should serialize to JSON with correct format', () {
      final lastSync = DateTime.parse('2024-10-23T09:00:00.000Z');
      final data = SyncDataDto(
        expenses: [
          {'local_id': 'temp-1', 'amount': 50.0}
        ],
      );

      final dto = SyncRequestDto(lastSync: lastSync, data: data);
      final json = dto.toJson();

      expect(json['last_sync'], isA<String>());
      expect(json['last_sync'], contains('2024-10-23'));
      expect(json['data'], isA<Map>());
      expect(json['data']['expenses'], isA<List>());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'last_sync': '2024-10-23T09:00:00.000000Z',
        'data': {
          'expenses': [
            {'local_id': 'temp-1', 'amount': 50.0}
          ],
          'incoming': [],
          'transfers': [],
        },
      };

      final dto = SyncRequestDto.fromJson(json);

      expect(dto.lastSync, isA<DateTime>());
      expect(dto.data.expenses.length, 1);
    });

    test('should match Laravel API specification format', () {
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
        incoming: [],
        transfers: [],
      );

      final dto = SyncRequestDto(lastSync: lastSync, data: data);
      final json = dto.toJson();

      // Verify structure matches API spec
      expect(json.containsKey('last_sync'), true);
      expect(json.containsKey('data'), true);
      expect(json['data'].containsKey('expenses'), true);
      expect(json['data'].containsKey('incoming'), true);
      expect(json['data'].containsKey('transfers'), true);
    });
  });
}
