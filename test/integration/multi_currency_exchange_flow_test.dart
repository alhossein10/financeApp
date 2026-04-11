import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:finance_app/features/exchanges/data/datasources/exchange_api_datasource.dart';

import 'multi_currency_exchange_flow_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late MockApiClient mockApiClient;
  late FundBoxApiDataSourceImpl fundBoxDataSource;
  late ExpenseApiDataSourceImpl expenseDataSource;
  late ExchangeApiDataSourceImpl exchangeDataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    fundBoxDataSource = FundBoxApiDataSourceImpl(apiClient: mockApiClient);
    expenseDataSource = ExpenseApiDataSourceImpl(apiClient: mockApiClient);
    exchangeDataSource = ExchangeApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('Multi-Currency and Exchange Flow Integration Tests', () {
    test('Complete multi-currency flow: USD → SYP → TRY expenses', () async {
      // Step 1: Get initial fund box with all currencies
      final initialFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 1000.0,
          'balance_syp': 5000000.0,
          'balance_try': 10000.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
          'updated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: initialFundBoxResponse,
          ));

      final initialFundBox = await fundBoxDataSource.getFundBox();

      expect(initialFundBox.balanceUsd, 1000.0);
      expect(initialFundBox.balanceSyp, 5000000.0);
      expect(initialFundBox.balanceTry, 10000.0);

      // Step 2: Create USD expense
      final usdExpenseResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'description': 'USD Expense',
          'price_usd': 100.0,
          'price_syp': null,
          'price_try': null,
          'expense_date': '2024-11-16',
          'has_invoice': false,
          'created_at': '2024-11-16T10:00:00Z',
          'updated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.post(
        '/expenses',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: usdExpenseResponse,
          ));

      final usdExpense = await expenseDataSource.createExpense(
        description: 'USD Expense',
        priceUsd: 100.0,
        expenseDate: '2024-11-16',
      );

      expect(usdExpense.priceUsd, 100.0);
      expect(usdExpense.priceSyp, isNull);
      expect(usdExpense.priceTry, isNull);

      // Step 3: Verify USD balance decreased
      final afterUsdFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 900.0,
          'balance_syp': 5000000.0,
          'balance_try': 10000.0,
          'last_calculated_at': '2024-11-16T10:05:00Z',
          'updated_at': '2024-11-16T10:05:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: afterUsdFundBoxResponse,
          ));

      final afterUsdFundBox = await fundBoxDataSource.getFundBox();
      expect(afterUsdFundBox.balanceUsd, 900.0);

      // Step 4: Create SYP expense
      final sypExpenseResponse = {
        'data': {
          'id': 2,
          'user_id': 1,
          'description': 'SYP Expense',
          'price_usd': null,
          'price_syp': 1000000.0,
          'price_try': null,
          'expense_date': '2024-11-16',
          'has_invoice': false,
          'created_at': '2024-11-16T10:10:00Z',
          'updated_at': '2024-11-16T10:10:00Z',
        },
      };

      when(mockApiClient.post(
        '/expenses',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: sypExpenseResponse,
          ));

      final sypExpense = await expenseDataSource.createExpense(
        description: 'SYP Expense',
        priceSyp: 1000000.0,
        expenseDate: '2024-11-16',
      );

      expect(sypExpense.priceSyp, 1000000.0);
      expect(sypExpense.priceUsd, isNull);

      // Step 5: Verify SYP balance decreased
      final afterSypFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 900.0,
          'balance_syp': 4000000.0,
          'balance_try': 10000.0,
          'last_calculated_at': '2024-11-16T10:15:00Z',
          'updated_at': '2024-11-16T10:15:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: afterSypFundBoxResponse,
          ));

      final afterSypFundBox = await fundBoxDataSource.getFundBox();
      expect(afterSypFundBox.balanceSyp, 4000000.0);

      // Step 6: Create TRY expense
      final tryExpenseResponse = {
        'data': {
          'id': 3,
          'user_id': 1,
          'description': 'TRY Expense',
          'price_usd': null,
          'price_syp': null,
          'price_try': 500.0,
          'expense_date': '2024-11-16',
          'has_invoice': false,
          'created_at': '2024-11-16T10:20:00Z',
          'updated_at': '2024-11-16T10:20:00Z',
        },
      };

      when(mockApiClient.post(
        '/expenses',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: tryExpenseResponse,
          ));

      final tryExpense = await expenseDataSource.createExpense(
        description: 'TRY Expense',
        priceTry: 500.0,
        expenseDate: '2024-11-16',
      );

      expect(tryExpense.priceTry, 500.0);
      expect(tryExpense.priceUsd, isNull);

      // Step 7: Verify TRY balance decreased
      final finalFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 900.0,
          'balance_syp': 4000000.0,
          'balance_try': 9500.0,
          'last_calculated_at': '2024-11-16T10:25:00Z',
          'updated_at': '2024-11-16T10:25:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: finalFundBoxResponse,
          ));

      final finalFundBox = await fundBoxDataSource.getFundBox();
      expect(finalFundBox.balanceTry, 9500.0);

      print('✅ Multi-currency expense flow completed');
      print('   - Initial: 1000 USD, 5M SYP, 10K TRY');
      print('   - USD expense: 100 USD → 900 USD remaining');
      print('   - SYP expense: 1M SYP → 4M SYP remaining');
      print('   - TRY expense: 500 TRY → 9.5K TRY remaining');
    });

    test('Complete exchange flow: USD → SYP and USD → TRY', () async {
      // Step 1: Get initial fund box
      final initialFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 1000.0,
          'balance_syp': 0.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
          'updated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: initialFundBoxResponse,
          ));

      final initialFundBox = await fundBoxDataSource.getFundBox();
      expect(initialFundBox.balanceUsd, 1000.0);
      expect(initialFundBox.balanceSyp, 0.0);
      expect(initialFundBox.balanceTry, 0.0);

      // Step 2: Exchange USD to SYP
      final sypExchangeResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'target_currency': 'SYP',
          'amount_usd': 500.0,
          'exchange_rate': 15000.0,
          'converted_amount': 7500000.0,
          'exchange_date': '2024-11-16',
          'notes': 'Exchange to SYP',
          'created_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.post(
        '/exchanges',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: sypExchangeResponse,
          ));

      final sypExchange = await exchangeDataSource.createExchange(
        targetCurrency: 'SYP',
        amountUsd: 500.0,
        exchangeRate: 15000.0,
        exchangeDate: '2024-11-16',
        notes: 'Exchange to SYP',
      );

      expect(sypExchange.targetCurrency, 'SYP');
      expect(sypExchange.amountUsd, 500.0);
      expect(sypExchange.exchangeRate, 15000.0);
      expect(sypExchange.convertedAmount, 7500000.0);

      // Step 3: Verify balances after SYP exchange
      final afterSypExchangeFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 500.0,
          'balance_syp': 7500000.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:05:00Z',
          'updated_at': '2024-11-16T10:05:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: afterSypExchangeFundBoxResponse,
          ));

      final afterSypExchangeFundBox = await fundBoxDataSource.getFundBox();
      expect(afterSypExchangeFundBox.balanceUsd, 500.0);
      expect(afterSypExchangeFundBox.balanceSyp, 7500000.0);

      // Step 4: Exchange USD to TRY
      final tryExchangeResponse = {
        'data': {
          'id': 2,
          'user_id': 1,
          'target_currency': 'TRY',
          'amount_usd': 300.0,
          'exchange_rate': 30.0,
          'converted_amount': 9000.0,
          'exchange_date': '2024-11-16',
          'notes': 'Exchange to TRY',
          'created_at': '2024-11-16T10:10:00Z',
        },
      };

      when(mockApiClient.post(
        '/exchanges',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: tryExchangeResponse,
          ));

      final tryExchange = await exchangeDataSource.createExchange(
        targetCurrency: 'TRY',
        amountUsd: 300.0,
        exchangeRate: 30.0,
        exchangeDate: '2024-11-16',
        notes: 'Exchange to TRY',
      );

      expect(tryExchange.targetCurrency, 'TRY');
      expect(tryExchange.amountUsd, 300.0);
      expect(tryExchange.convertedAmount, 9000.0);

      // Step 5: Verify final balances
      final finalFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 200.0,
          'balance_syp': 7500000.0,
          'balance_try': 9000.0,
          'last_calculated_at': '2024-11-16T10:15:00Z',
          'updated_at': '2024-11-16T10:15:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: finalFundBoxResponse,
          ));

      final finalFundBox = await fundBoxDataSource.getFundBox();
      expect(finalFundBox.balanceUsd, 200.0);
      expect(finalFundBox.balanceSyp, 7500000.0);
      expect(finalFundBox.balanceTry, 9000.0);

      // Step 6: Get exchange history
      final exchangeHistoryResponse = {
        'data': [
          {
            'id': 1,
            'user_id': 1,
            'target_currency': 'SYP',
            'amount_usd': 500.0,
            'exchange_rate': 15000.0,
            'converted_amount': 7500000.0,
            'exchange_date': '2024-11-16',
            'notes': 'Exchange to SYP',
            'created_at': '2024-11-16T10:00:00Z',
          },
          {
            'id': 2,
            'user_id': 1,
            'target_currency': 'TRY',
            'amount_usd': 300.0,
            'exchange_rate': 30.0,
            'converted_amount': 9000.0,
            'exchange_date': '2024-11-16',
            'notes': 'Exchange to TRY',
            'created_at': '2024-11-16T10:10:00Z',
          },
        ],
      };

      when(mockApiClient.get(
        '/exchanges',
        queryParams: anyNamed('queryParams'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: exchangeHistoryResponse,
          ));

      final exchanges = await exchangeDataSource.getExchanges(currency: 'all');
      expect(exchanges.length, 2);
      expect(exchanges[0].targetCurrency, 'SYP');
      expect(exchanges[1].targetCurrency, 'TRY');

      print('✅ Exchange flow completed');
      print('   - Initial: 1000 USD');
      print('   - Exchanged 500 USD → 7.5M SYP');
      print('   - Exchanged 300 USD → 9K TRY');
      print('   - Final: 200 USD, 7.5M SYP, 9K TRY');
      print('   - Exchange history retrieved (2 exchanges)');
    });

    test('Exchange with automatic calculation: provide rate, calculate amount', () async {
      // Exchange with rate provided, amount calculated
      final exchangeResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'target_currency': 'SYP',
          'amount_usd': 100.0,
          'exchange_rate': 15000.0,
          'converted_amount': 1500000.0,
          'exchange_date': '2024-11-16',
          'created_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.post(
        '/exchanges',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: exchangeResponse,
          ));

      final exchange = await exchangeDataSource.createExchange(
        targetCurrency: 'SYP',
        amountUsd: 100.0,
        exchangeRate: 15000.0,
        exchangeDate: '2024-11-16',
      );

      expect(exchange.convertedAmount, 1500000.0);
      expect(exchange.convertedAmount, exchange.amountUsd * exchange.exchangeRate!);
    });

    test('Exchange with automatic calculation: provide amount, calculate rate', () async {
      // Exchange with converted amount provided, rate calculated
      final exchangeResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'target_currency': 'TRY',
          'amount_usd': 100.0,
          'exchange_rate': 30.0,
          'converted_amount': 3000.0,
          'exchange_date': '2024-11-16',
          'created_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.post(
        '/exchanges',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: exchangeResponse,
          ));

      final exchange = await exchangeDataSource.createExchange(
        targetCurrency: 'TRY',
        amountUsd: 100.0,
        convertedAmount: 3000.0,
        exchangeDate: '2024-11-16',
      );

      expect(exchange.exchangeRate, 30.0);
      expect(exchange.exchangeRate, exchange.convertedAmount! / exchange.amountUsd);
    });

    test('Filter exchanges by currency', () async {
      // Get SYP exchanges only
      final sypExchangesResponse = {
        'data': [
          {
            'id': 1,
            'user_id': 1,
            'target_currency': 'SYP',
            'amount_usd': 500.0,
            'exchange_rate': 15000.0,
            'converted_amount': 7500000.0,
            'exchange_date': '2024-11-16',
            'created_at': '2024-11-16T10:00:00Z',
          },
        ],
      };

      when(mockApiClient.get(
        '/exchanges',
        queryParams: {'currency': 'SYP'},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: sypExchangesResponse,
          ));

      final sypExchanges = await exchangeDataSource.getExchanges(currency: 'SYP');
      expect(sypExchanges.length, 1);
      expect(sypExchanges[0].targetCurrency, 'SYP');

      // Get TRY exchanges only
      final tryExchangesResponse = {
        'data': [
          {
            'id': 2,
            'user_id': 1,
            'target_currency': 'TRY',
            'amount_usd': 300.0,
            'exchange_rate': 30.0,
            'converted_amount': 9000.0,
            'exchange_date': '2024-11-16',
            'created_at': '2024-11-16T10:10:00Z',
          },
        ],
      };

      when(mockApiClient.get(
        '/exchanges',
        queryParams: {'currency': 'TRY'},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: tryExchangesResponse,
          ));

      final tryExchanges = await exchangeDataSource.getExchanges(currency: 'TRY');
      expect(tryExchanges.length, 1);
      expect(tryExchanges[0].targetCurrency, 'TRY');
    });

    test('Multi-currency expense with multiple currencies in single expense', () async {
      // Create expense with multiple currencies
      final multiCurrencyExpenseResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'description': 'Multi-currency expense',
          'price_usd': 100.0,
          'price_syp': 1500000.0,
          'price_try': 3000.0,
          'expense_date': '2024-11-16',
          'has_invoice': false,
          'created_at': '2024-11-16T10:00:00Z',
          'updated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.post(
        '/expenses',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: multiCurrencyExpenseResponse,
          ));

      final expense = await expenseDataSource.createExpense(
        description: 'Multi-currency expense',
        priceUsd: 100.0,
        priceSyp: 1500000.0,
        priceTry: 3000.0,
        expenseDate: '2024-11-16',
      );

      expect(expense.priceUsd, 100.0);
      expect(expense.priceSyp, 1500000.0);
      expect(expense.priceTry, 3000.0);

      // Verify all balances decreased
      final fundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 900.0,
          'balance_syp': 3500000.0,
          'balance_try': 7000.0,
          'last_calculated_at': '2024-11-16T10:05:00Z',
          'updated_at': '2024-11-16T10:05:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: fundBoxResponse,
          ));

      final fundBox = await fundBoxDataSource.getFundBox();
      expect(fundBox.balanceUsd, 900.0);
      expect(fundBox.balanceSyp, 3500000.0);
      expect(fundBox.balanceTry, 7000.0);
    });

    test('Get fund box by specific currency', () async {
      // Get USD balance only
      final usdFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 1000.0,
          'balance_syp': 0.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
          'updated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get(
        '/fund-box',
        queryParams: {'currency': 'USD'},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: usdFundBoxResponse,
          ));

      final usdFundBox = await fundBoxDataSource.getFundBoxByCurrency('USD');
      expect(usdFundBox.balanceUsd, 1000.0);

      // Get SYP balance only
      final sypFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 0.0,
          'balance_syp': 5000000.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
          'updated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get(
        '/fund-box',
        queryParams: {'currency': 'SYP'},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: sypFundBoxResponse,
          ));

      final sypFundBox = await fundBoxDataSource.getFundBoxByCurrency('SYP');
      expect(sypFundBox.balanceSyp, 5000000.0);

      // Get TRY balance only
      final tryFundBoxResponse = {
        'data': {
          'id': 1,
          'user_id': 1,
          'balance_usd': 0.0,
          'balance_syp': 0.0,
          'balance_try': 10000.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
          'updated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get(
        '/fund-box',
        queryParams: {'currency': 'TRY'},
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: tryFundBoxResponse,
          ));

      final tryFundBox = await fundBoxDataSource.getFundBoxByCurrency('TRY');
      expect(tryFundBox.balanceTry, 10000.0);
    });
  });
}