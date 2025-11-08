import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:finance_app/features/incoming/data/datasources/incoming_api_datasource.dart';
import 'package:finance_app/features/incoming/data/models/incoming_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'incoming_api_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late IncomingApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = IncomingApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('IncomingApiDataSource', () {
    group('createIncoming', () {
      test('should send correct request body with proper field mappings', () async {
        // Arrange
        final incomingDto = IncomingDto(
          userId: 123,
          amountUsd: 5000.0,
          source: 'Salary',
          description: 'Monthly salary',
          date: '2024-10-23',
          paymentMethod: 'bank_transfer',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'amount_usd': 5000.0,
            'source': 'Salary',
            'description': 'Monthly salary',
            'date': '2024-10-23',
            'payment_method': 'bank_transfer',
            'created_at': '2024-10-23T10:00:00.000000Z',
          },
        };

        when(mockApiClient.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => Response(
              statusCode: 201,
              data: responseData,
              requestOptions: RequestOptions(path: '/incoming'),
            ));

        // Act
        final result = await dataSource.createIncoming(incomingDto);

        // Assert
        final captured = verify(mockApiClient.post(
          '/incoming',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['amount_usd'], 5000.0);
        expect(captured['source'], 'Salary');
        expect(captured['description'], 'Monthly salary');
        expect(captured['date'], '2024-10-23');
        expect(captured['payment_method'], 'bank_transfer');
        expect(result.id, 1);
      });

      test('should exclude description if null', () async {
        // Arrange
        final incomingDto = IncomingDto(
          amountUsd: 5000.0,
          source: 'Salary',
          date: '2024-10-23',
          paymentMethod: 'cash',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'amount_usd': 5000.0,
            'source': 'Salary',
            'date': '2024-10-23',
            'payment_method': 'cash',
          },
        };

        when(mockApiClient.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => Response(
              statusCode: 201,
              data: responseData,
              requestOptions: RequestOptions(path: '/incoming'),
            ));

        // Act
        await dataSource.createIncoming(incomingDto);

        // Assert
        final captured = verify(mockApiClient.post(
          '/incoming',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured.containsKey('description'), false);
      });

      test('should validate payment method before sending', () async {
        // Arrange
        final incomingDto = IncomingDto(
          amountUsd: 5000.0,
          source: 'Salary',
          date: '2024-10-23',
          paymentMethod: 'invalid_method',
        );

        // Act & Assert
        expect(
          () => dataSource.createIncoming(incomingDto),
          throwsA(isA<Exception>()),
        );
      });

      test('should accept all valid payment methods', () async {
        // Arrange
        final validMethods = ['cash', 'card', 'bank_transfer'];

        for (final method in validMethods) {
          final incomingDto = IncomingDto(
            amountUsd: 5000.0,
            source: 'Salary',
            date: '2024-10-23',
            paymentMethod: method,
          );

          final responseData = {
            'success': true,
            'data': {
              'id': 1,
              'amount_usd': 5000.0,
              'source': 'Salary',
              'date': '2024-10-23',
              'payment_method': method,
            },
          };

          when(mockApiClient.post(
            any,
            body: anyNamed('body'),
          )).thenAnswer((_) async => Response(
                statusCode: 201,
                data: responseData,
                requestOptions: RequestOptions(path: '/incoming'),
              ));

          // Act & Assert
          expect(
            () => dataSource.createIncoming(incomingDto),
            returnsNormally,
          );
        }
      });
    });

    group('updateIncoming', () {
      test('should send correct request body with all required fields', () async {
        // Arrange
        final incomingDto = IncomingDto(
          id: 1,
          amountUsd: 5500.0,
          source: 'Salary',
          description: 'Monthly salary with bonus',
          date: '2024-10-24',
          paymentMethod: 'bank_transfer',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'amount_usd': 5500.0,
            'source': 'Salary',
            'description': 'Monthly salary with bonus',
            'date': '2024-10-24',
            'payment_method': 'bank_transfer',
          },
        };

        when(mockApiClient.put(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => Response(
              statusCode: 200,
              data: responseData,
              requestOptions: RequestOptions(path: '/incoming/1'),
            ));

        // Act
        await dataSource.updateIncoming(1, incomingDto);

        // Assert
        final captured = verify(mockApiClient.put(
          '/incoming/1',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['amount_usd'], 5500.0);
        expect(captured['source'], 'Salary');
        expect(captured['date'], '2024-10-24');
        expect(captured['payment_method'], 'bank_transfer');
      });

      test('should validate payment method before sending', () async {
        // Arrange
        final incomingDto = IncomingDto(
          id: 1,
          amountUsd: 5500.0,
          source: 'Salary',
          date: '2024-10-24',
          paymentMethod: 'invalid_method',
        );

        // Act & Assert
        expect(
          () => dataSource.updateIncoming(1, incomingDto),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getIncoming', () {
      test('should use correct query parameters with date formatting', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 12, 31);

        final responseData = {
          'success': true,
          'data': [],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        };

        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => Response(
              statusCode: 200,
              data: responseData,
              requestOptions: RequestOptions(path: '/incoming'),
            ));

        // Act
        await dataSource.getIncoming(
          page: 1,
          perPage: 15,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        final captured = verify(mockApiClient.get(
          '/incoming',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['page'], 1);
        expect(captured['per_page'], 15);
        expect(captured['date_from'], '2024-01-01');
        expect(captured['date_to'], '2024-12-31');
      });

      test('should not include date filters if not provided', () async {
        // Arrange
        final responseData = {
          'success': true,
          'data': [],
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
        };

        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => Response(
              statusCode: 200,
              data: responseData,
              requestOptions: RequestOptions(path: '/incoming'),
            ));

        // Act
        await dataSource.getIncoming(page: 1, perPage: 15);

        // Assert
        final captured = verify(mockApiClient.get(
          '/incoming',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured.containsKey('date_from'), false);
        expect(captured.containsKey('date_to'), false);
      });
    });

    group('getIncomingById', () {
      test('should fetch single incoming transaction', () async {
        // Arrange
        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'amount_usd': 5000.0,
            'source': 'Salary',
            'description': 'Monthly salary',
            'date': '2024-10-23',
            'payment_method': 'bank_transfer',
          },
        };

        when(mockApiClient.get(any)).thenAnswer((_) async => Response(
              statusCode: 200,
              data: responseData,
              requestOptions: RequestOptions(path: '/incoming/1'),
            ));

        // Act
        final result = await dataSource.getIncomingById(1);

        // Assert
        verify(mockApiClient.get('/incoming/1')).called(1);
        expect(result.id, 1);
        expect(result.amountUsd, 5000.0);
        expect(result.source, 'Salary');
        expect(result.paymentMethod, 'bank_transfer');
      });
    });

    group('deleteIncoming', () {
      test('should call delete endpoint', () async {
        // Arrange
        when(mockApiClient.delete(any)).thenAnswer((_) async => Response(
              statusCode: 200,
              data: {'success': true, 'message': 'Income deleted successfully'},
              requestOptions: RequestOptions(path: '/incoming/1'),
            ));

        // Act
        await dataSource.deleteIncoming(1);

        // Assert
        verify(mockApiClient.delete('/incoming/1')).called(1);
      });
    });

    group('Date formatting', () {
      test('should format dates as YYYY-MM-DD', () {
        // Arrange
        final date = DateTime(2024, 1, 5);

        // Act
        final formatted = DateFormatter.toApiDate(date);

        // Assert
        expect(formatted, '2024-01-05');
      });

      test('should parse YYYY-MM-DD dates correctly', () {
        // Arrange
        const dateStr = '2024-01-05';

        // Act
        final parsed = DateFormatter.fromApiDate(dateStr);

        // Assert
        expect(parsed.year, 2024);
        expect(parsed.month, 1);
        expect(parsed.day, 5);
      });
    });
  });
}
