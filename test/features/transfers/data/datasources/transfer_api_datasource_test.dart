import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:finance_app/features/transfers/data/datasources/transfer_api_datasource.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'transfer_api_datasource_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late TransferApiDataSourceImpl dataSource;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    dataSource = TransferApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('TransferApiDataSource', () {
    group('createTransfer', () {
      test('should send correct request body with proper field mappings', () async {
        // Arrange
        final transferDto = TransferDto(
          userId: 123,
          recipientName: 'abo momen',
          amountUsd: 500.0,
          transferDate: '2024-10-23',
          notes: 'Monthly transfer',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'user_id': 123,
            'recipient_name': 'abo momen',
            'amount_usd': 500.0,
            'transfer_date': '2024-10-23',
            'notes': 'Monthly transfer',
            'created_at': '2024-10-23T10:00:00.000000Z',
          },
        };

        when(mockApiClient.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 201,
              data: responseData,
            ));

        // Act
        final result = await dataSource.createTransfer(transferDto);

        // Assert
        final captured = verify(mockApiClient.post(
          '/transfers',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['recipient_name'], 'abo momen');
        expect(captured['amount_usd'], 500.0);
        expect(captured['transfer_date'], '2024-10-23');
        expect(captured['notes'], 'Monthly transfer');
        expect(result.id, 1);
      });

      test('should exclude notes if null or empty', () async {
        // Arrange
        final transferDto = TransferDto(
          recipientName: 'abo momen',
          amountUsd: 500.0,
          transferDate: '2024-10-23',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'recipient_name': 'abo momen',
            'amount_usd': 500.0,
            'transfer_date': '2024-10-23',
          },
        };

        when(mockApiClient.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 201,
              data: responseData,
            ));

        // Act
        await dataSource.createTransfer(transferDto);

        // Assert
        final captured = verify(mockApiClient.post(
          '/transfers',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured.containsKey('notes'), false);
      });
    });

    group('updateTransfer', () {
      test('should send correct request body with all required fields', () async {
        // Arrange
        final transferDto = TransferDto(
          id: 1,
          recipientName: 'abo momen',
          amountUsd: 600.0,
          transferDate: '2024-10-24',
          notes: 'Updated transfer',
        );

        final responseData = {
          'success': true,
          'data': {
            'id': 1,
            'recipient_name': 'abo momen',
            'amount_usd': 600.0,
            'transfer_date': '2024-10-24',
            'notes': 'Updated transfer',
          },
        };

        when(mockApiClient.put(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        await dataSource.updateTransfer(1, transferDto);

        // Assert
        final captured = verify(mockApiClient.put(
          '/transfers/1',
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['recipient_name'], 'abo momen');
        expect(captured['amount_usd'], 600.0);
        expect(captured['transfer_date'], '2024-10-24');
      });
    });

    group('getTransfers', () {
      test('should use correct query parameters with date formatting', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 12, 31);

        final responseData = {
          'success': true,
          'data': [],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 15,
            'total': 0,
          },
        };

        when(mockApiClient.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((_) async => ApiResponse(
              statusCode: 200,
              data: responseData,
            ));

        // Act
        await dataSource.getTransfers(
          page: 1,
          perPage: 15,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        final captured = verify(mockApiClient.get(
          '/transfers',
          queryParams: captureAnyNamed('queryParams'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['page'], 1);
        expect(captured['per_page'], 15);
        expect(captured['date_from'], '2024-01-01');
        expect(captured['date_to'], '2024-12-31');
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
