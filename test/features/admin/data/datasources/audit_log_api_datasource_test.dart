import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_exception.dart';
import 'package:finance_app/features/admin/data/datasources/audit_log_api_datasource.dart';

@GenerateMocks([ApiClient])
import 'audit_log_api_datasource_test.mocks.dart';

void main() {
  late AuditLogApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = AuditLogApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('getAuditLogs', () {
    final testResponse = {
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
      'meta': {
        'current_page': 1,
        'last_page': 5,
        'total': 100,
        'per_page': 15,
      },
    };

    test('should return AuditLogListDto on successful request', () async {
      when(mockApiClient.get(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/audit-logs'),
            statusCode: 200,
            data: testResponse,
          ));

      final result = await dataSource.getAuditLogs();

      expect(result.logs.length, 1);
      expect(result.currentPage, 1);
      expect(result.total, 100);
      verify(mockApiClient.get(
        '/audit-logs',
        queryParams: {'page': 1, 'per_page': 15},
      )).called(1);
    });

    test('should include filters in query parameters', () async {
      when(mockApiClient.get(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/audit-logs'),
            statusCode: 200,
            data: testResponse,
          ));

      final startDate = DateTime.parse('2024-01-01');
      final endDate = DateTime.parse('2024-01-31');

      await dataSource.getAuditLogs(
        page: 2,
        perPage: 20,
        userId: 123,
        action: 'expense.created',
        resourceType: 'Expense',
        startDate: startDate,
        endDate: endDate,
      );

      verify(mockApiClient.get(
        '/audit-logs',
        queryParams: {
          'page': 2,
          'per_page': 20,
          'user_id': 123,
          'action': 'expense.created',
          'entity_type': 'Expense',
          'start_date': '2024-01-01',
          'end_date': '2024-01-31',
        },
      )).called(1);
    });

    test('should throw ApiException on 403 Forbidden', () async {
      when(mockApiClient.get(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/audit-logs'),
            statusCode: 403,
            data: {'message': 'Forbidden'},
          ));

      expect(
        () => dataSource.getAuditLogs(),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          403,
        )),
      );
    });

    test('should throw ApiException on error', () async {
      when(mockApiClient.get(
        any,
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/audit-logs'),
            statusCode: 500,
            data: {'message': 'Server error'},
          ));

      expect(
        () => dataSource.getAuditLogs(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('getAuditLogDetails', () {
    final testResponse = {
      'data': {
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
        },
        'created_at': '2024-01-15T10:30:00Z',
      },
    };

    test('should return AuditLogDto on successful request', () async {
      when(mockApiClient.get(any)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/audit-logs/1'),
            statusCode: 200,
            data: testResponse,
          ));

      final result = await dataSource.getAuditLogDetails(1);

      expect(result.id, 1);
      expect(result.userName, 'John Doe');
      expect(result.changes, isNotNull);
      verify(mockApiClient.get('/audit-logs/1')).called(1);
    });

    test('should throw ApiException on 403 Forbidden', () async {
      when(mockApiClient.get(any)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/audit-logs/1'),
            statusCode: 403,
            data: {'message': 'Forbidden'},
          ));

      expect(
        () => dataSource.getAuditLogDetails(1),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          403,
        )),
      );
    });

    test('should throw ApiException on 404 Not Found', () async {
      when(mockApiClient.get(any)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/audit-logs/1'),
            statusCode: 404,
            data: {'message': 'Not found'},
          ));

      expect(
        () => dataSource.getAuditLogDetails(1),
        throwsA(isA<ApiException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });
  });
}
