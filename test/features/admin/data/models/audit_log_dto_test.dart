import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/features/admin/data/models/audit_log_dto.dart';

void main() {
  group('AuditLogDto', () {
    final testDateTime = DateTime.parse('2024-01-15T10:30:00Z');

    final testJson = {
      'id': 1,
      'user_id': 123,
      'user_name': 'John Doe',
      'action': 'expense.created',
      'entity_type': 'Expense',
      'entity_id': 456,
      'ip_address': '192.168.1.1',
      'user_agent': 'Mozilla/5.0',
      'changes': {
        'amount': {'old': 100.0, 'new': 150.0},
        'category': {'old': 'Food', 'new': 'Transport'},
      },
      'created_at': '2024-01-15T10:30:00Z',
    };

    final testDto = AuditLogDto(
      id: 1,
      userId: 123,
      userName: 'John Doe',
      action: 'expense.created',
      entityType: 'Expense',
      entityId: 456,
      ipAddress: '192.168.1.1',
      userAgent: 'Mozilla/5.0',
      changes: {
        'amount': {'old': 100.0, 'new': 150.0},
        'category': {'old': 'Food', 'new': 'Transport'},
      },
      createdAt: testDateTime,
    );

    test('fromJson should correctly parse JSON', () {
      final result = AuditLogDto.fromJson(testJson);

      expect(result.id, 1);
      expect(result.userId, 123);
      expect(result.userName, 'John Doe');
      expect(result.action, 'expense.created');
      expect(result.entityType, 'Expense');
      expect(result.entityId, 456);
      expect(result.ipAddress, '192.168.1.1');
      expect(result.userAgent, 'Mozilla/5.0');
      expect(result.changes, isNotNull);
      expect(result.changes!['amount'], {'old': 100.0, 'new': 150.0});
      expect(result.createdAt, testDateTime);
    });

    test('fromJson should handle missing optional fields', () {
      final jsonWithoutOptionals = {
        'id': 1,
        'user_id': 123,
        'action': 'expense.created',
        'entity_type': 'Expense',
        'entity_id': 456,
        'ip_address': '192.168.1.1',
        'user_agent': 'Mozilla/5.0',
        'created_at': '2024-01-15T10:30:00Z',
      };

      final result = AuditLogDto.fromJson(jsonWithoutOptionals);

      expect(result.userName, isNull);
      expect(result.changes, isNull);
    });

    test('toJson should correctly convert to JSON', () {
      final result = testDto.toJson();

      expect(result['id'], 1);
      expect(result['user_id'], 123);
      expect(result['user_name'], 'John Doe');
      expect(result['action'], 'expense.created');
      expect(result['entity_type'], 'Expense');
      expect(result['entity_id'], 456);
      expect(result['ip_address'], '192.168.1.1');
      expect(result['user_agent'], 'Mozilla/5.0');
      expect(result['changes'], isNotNull);
      expect(result['created_at'], testDateTime.toIso8601String());
    });

    test('toJson should exclude null optional fields', () {
      final dtoWithoutOptionals = AuditLogDto(
        id: 1,
        userId: 123,
        action: 'expense.created',
        entityType: 'Expense',
        entityId: 456,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        createdAt: testDateTime,
      );

      final result = dtoWithoutOptionals.toJson();

      expect(result.containsKey('user_name'), false);
      expect(result.containsKey('changes'), false);
    });
  });

  group('AuditLogListDto', () {
    final testDateTime = DateTime.parse('2024-01-15T10:30:00Z');

    final testJson = {
      'data': [
        {
          'id': 1,
          'user_id': 123,
          'action': 'expense.created',
          'entity_type': 'Expense',
          'entity_id': 456,
          'ip_address': '192.168.1.1',
          'user_agent': 'Mozilla/5.0',
          'created_at': '2024-01-15T10:30:00Z',
        },
        {
          'id': 2,
          'user_id': 124,
          'action': 'expense.updated',
          'entity_type': 'Expense',
          'entity_id': 457,
          'ip_address': '192.168.1.2',
          'user_agent': 'Mozilla/5.0',
          'created_at': '2024-01-15T10:30:00Z',
        },
      ],
      'meta': {
        'current_page': 1,
        'last_page': 5,
        'total': 100,
        'per_page': 15,
      },
    };

    test('fromJson should correctly parse paginated response', () {
      final result = AuditLogListDto.fromJson(testJson);

      expect(result.logs.length, 2);
      expect(result.currentPage, 1);
      expect(result.lastPage, 5);
      expect(result.total, 100);
      expect(result.perPage, 15);
      expect(result.hasMorePages, true);
    });

    test('fromJson should handle pagination in root level', () {
      final jsonWithRootPagination = {
        'data': [
          {
            'id': 1,
            'user_id': 123,
            'action': 'expense.created',
            'entity_type': 'Expense',
            'entity_id': 456,
            'ip_address': '192.168.1.1',
            'user_agent': 'Mozilla/5.0',
            'created_at': '2024-01-15T10:30:00Z',
          },
        ],
        'current_page': 1,
        'last_page': 1,
        'total': 1,
        'per_page': 15,
      };

      final result = AuditLogListDto.fromJson(jsonWithRootPagination);

      expect(result.logs.length, 1);
      expect(result.currentPage, 1);
      expect(result.lastPage, 1);
      expect(result.total, 1);
      expect(result.perPage, 15);
    });

    test('hasMorePages should return false on last page', () {
      final jsonLastPage = {
        'data': [],
        'meta': {
          'current_page': 5,
          'last_page': 5,
          'total': 100,
          'per_page': 15,
        },
      };

      final result = AuditLogListDto.fromJson(jsonLastPage);

      expect(result.hasMorePages, false);
    });

    test('toJson should correctly convert to JSON', () {
      final dto = AuditLogListDto(
        logs: [
          AuditLogDto(
            id: 1,
            userId: 123,
            action: 'expense.created',
            entityType: 'Expense',
            entityId: 456,
            ipAddress: '192.168.1.1',
            userAgent: 'Mozilla/5.0',
            createdAt: testDateTime,
          ),
        ],
        currentPage: 1,
        lastPage: 5,
        total: 100,
        perPage: 15,
      );

      final result = dto.toJson();

      expect(result['data'], isList);
      expect((result['data'] as List).length, 1);
      expect(result['meta']['current_page'], 1);
      expect(result['meta']['last_page'], 5);
      expect(result['meta']['total'], 100);
      expect(result['meta']['per_page'], 15);
    });
  });
}
