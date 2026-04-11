import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/api/api_response.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/auth/data/datasources/auth_api_datasource.dart';
import 'package:finance_app/features/admin_group/data/datasources/admin_group_api_datasource.dart';
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:finance_app/features/exchanges/data/datasources/exchange_api_datasource.dart';

import 'user_join_expense_exchange_flow_test.mocks.dart';

@GenerateMocks([ApiClient, TokenManager])
void main() {
  late MockApiClient mockApiClient;
  late MockTokenManager mockTokenManager;
  late AuthApiDataSourceImpl authDataSource;
  late AdminGroupApiDatasource adminGroupDataSource;
  late FundBoxApiDataSourceImpl fundBoxDataSource;
  late ExpenseApiDataSourceImpl expenseDataSource;
  late ExchangeApiDataSourceImpl exchangeDataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    mockTokenManager = MockTokenManager();
    authDataSource = AuthApiDataSourceImpl(apiClient: mockApiClient);
    adminGroupDataSource = AdminGroupApiDatasource(apiClient: mockApiClient);
    fundBoxDataSource = FundBoxApiDataSourceImpl(apiClient: mockApiClient);
    expenseDataSource = ExpenseApiDataSourceImpl(apiClient: mockApiClient);
    exchangeDataSource = ExchangeApiDataSourceImpl(apiClient: mockApiClient);
  });

  group('User Join Group → Create Expense → Exchange Currency Flow', () {
    test('Complete User flow: Register → Join group → Create expense → Exchange',
        () async {
      // Step 1: User Registration
      final registrationResponse = {
        'success': true,
        'data': {
          'user': {
            'id': 30,
            'name': 'Regular User',
            'email': 'user@test.com',
            'role': 'user',
          },
          'token': 'user-token-789',
          'token_type': 'Bearer',
        },
      };

      when(mockApiClient.post(
        '/auth/register',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: registrationResponse,
          ));

      final registrationResult = await authDataSource.register(
        name: 'Regular User',
        email: 'user@test.com',
        password: 'password123',
        role: 'user',
      );

      expect(registrationResult['user']['role'], 'user');
      expect(registrationResult['token'], 'user-token-789');

      // Step 2: Save token
      when(mockTokenManager.saveToken(
        token: anyNamed('token'),
        tokenType: anyNamed('tokenType'),
      )).thenAnswer((_) async => {});

      await mockTokenManager.saveToken(
        token: registrationResult['token'],
        tokenType: 'Bearer',
      );

      // Step 3: Join Admin Group
      final joinGroupResponse = {
        'success': true,
        'data': {
          'user': {
            'id': 30,
            'name': 'Regular User',
            'email': 'user@test.com',
            'role': 'user',
            'admin_group_id': 1,
          },
          'admin_group': {
            'id': 1,
            'name': 'Test Admin Group',
            'admin_id': 10,
          },
        },
      };

      when(mockApiClient.post(
        '/admin-group/join',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: joinGroupResponse,
          ));

      final joinResult = await adminGroupDataSource.joinGroup('ABC123');

      expect(joinResult['user']['admin_group_id'], 1);
      expect(joinResult['admin_group']['name'], 'Test Admin Group');

      // Step 4: Get User Group Info
      final groupInfoResponse = {
        'data': {
          'id': 1,
          'name': 'Test Admin Group',
          'admin_name': 'Admin User',
          'member_count': 6,
          'joined_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get('/user/group-info')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: groupInfoResponse,
          ));

      final groupInfo = await adminGroupDataSource.getUserGroupInfo();

      expect(groupInfo.name, 'Test Admin Group');
      expect(groupInfo.adminName, 'Admin User');
      expect(groupInfo.memberCount, 6);

      // Step 5: Get Fund Box (initial balance from admin transfer)
      final initialFundBoxResponse = {
        'data': {
          'id': 30,
          'user_id': 30,
          'balance_usd': 100.0,
          'balance_syp': 0.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: initialFundBoxResponse,
          ));

      final initialFundBox = await fundBoxDataSource.getFundBox();

      expect(initialFundBox.balanceUsd, 100.0);

      // Step 6: Create Multi-Currency Expense (USD)
      final expenseResponse = {
        'data': {
          'id': 1,
          'user_id': 30,
          'description': 'Office supplies',
          'price_usd': 50.0,
          'price_syp': null,
          'price_try': null,
          'expense_date': '2024-11-16',
          'has_invoice': false,
          'created_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.post(
        '/expenses',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 201,
            data: expenseResponse,
          ));

      final expense = await expenseDataSource.createExpense(
        description: 'Office supplies',
        priceUsd: 50.0,
        expenseDate: '2024-11-16',
      );

      expect(expense.description, 'Office supplies');
      expect(expense.priceUsd, 50.0);
      expect(expense.priceSyp, isNull);
      expect(expense.priceTry, isNull);

      // Step 7: Verify Fund Box updated (balance decreased)
      final updatedFundBoxResponse = {
        'data': {
          'id': 30,
          'user_id': 30,
          'balance_usd': 50.0,
          'balance_syp': 0.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:05:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: updatedFundBoxResponse,
          ));

      final updatedFundBox = await fundBoxDataSource.getFundBox();

      expect(updatedFundBox.balanceUsd, 50.0);

      // Step 8: Exchange USD to SYP
      final exchangeResponse = {
        'data': {
          'id': 1,
          'target_currency': 'SYP',
          'amount_usd': 30.0,
          'exchange_rate': 15000.0,
          'converted_amount': 450000.0,
          'exchange_date': '2024-11-16',
          'created_at': '2024-11-16T10:10:00Z',
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
        amountUsd: 30.0,
        exchangeRate: 15000.0,
        exchangeDate: '2024-11-16',
      );

      expect(exchange.targetCurrency, 'SYP');
      expect(exchange.amountUsd, 30.0);
      expect(exchange.exchangeRate, 15000.0);
      expect(exchange.convertedAmount, 450000.0);

      // Step 9: Verify Fund Box updated (USD decreased, SYP increased)
      final finalFundBoxResponse = {
        'data': {
          'id': 30,
          'user_id': 30,
          'balance_usd': 20.0,
          'balance_syp': 450000.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:15:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: finalFundBoxResponse,
          ));

      final finalFundBox = await fundBoxDataSource.getFundBox();

      expect(finalFundBox.balanceUsd, 20.0);
      expect(finalFundBox.balanceSyp, 450000.0);

      // Step 10: Create SYP Expense
      final sypExpenseResponse = {
        'data': {
          'id': 2,
          'user_id': 30,
          'description': 'Local purchase',
          'price_usd': null,
          'price_syp': 150000.0,
          'price_try': null,
          'expense_date': '2024-11-16',
          'has_invoice': false,
          'created_at': '2024-11-16T10:20:00Z',
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
        description: 'Local purchase',
        priceSyp: 150000.0,
        expenseDate: '2024-11-16',
      );

      expect(sypExpense.priceSyp, 150000.0);
      expect(sypExpense.priceUsd, isNull);

      // Step 11: Verify Final Fund Box (SYP decreased)
      final veryFinalFundBoxResponse = {
        'data': {
          'id': 30,
          'user_id': 30,
          'balance_usd': 20.0,
          'balance_syp': 300000.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:25:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: veryFinalFundBoxResponse,
          ));

      final veryFinalFundBox = await fundBoxDataSource.getFundBox();

      expect(veryFinalFundBox.balanceUsd, 20.0);
      expect(veryFinalFundBox.balanceSyp, 300000.0);

      // Verify complete flow executed successfully
      print('✅ User flow completed successfully');
      print('   - Registration with user role');
      print('   - Token saved');
      print('   - Joined admin group');
      print('   - Group info retrieved');
      print('   - Initial fund box: 100 USD');
      print('   - Created USD expense: 50 USD');
      print('   - Fund box updated: 50 USD');
      print('   - Exchanged USD to SYP: 30 USD → 450,000 SYP');
      print('   - Fund box updated: 20 USD, 450,000 SYP');
      print('   - Created SYP expense: 150,000 SYP');
      print('   - Final fund box: 20 USD, 300,000 SYP');
    });

    test('User cannot join group with invalid code', () async {
      when(mockApiClient.post(
        '/admin-group/join',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 404,
            data: {
              'message': 'Invalid group code',
            },
          ));

      expect(
        () => adminGroupDataSource.joinGroup('INVALID'),
        throwsException,
      );
    });

    test('User cannot create expense with insufficient balance', () async {
      // Get Fund Box with low balance
      final fundBoxResponse = {
        'data': {
          'id': 30,
          'user_id': 30,
          'balance_usd': 10.0,
          'balance_syp': 0.0,
          'balance_try': 0.0,
          'last_calculated_at': '2024-11-16T10:00:00Z',
        },
      };

      when(mockApiClient.get('/fund-box')).thenAnswer((_) async => ApiResponse(
            statusCode: 200,
            data: fundBoxResponse,
          ));

      final fundBox = await fundBoxDataSource.getFundBox();
      expect(fundBox.balanceUsd, 10.0);

      // Attempt expense exceeding balance
      when(mockApiClient.post(
        '/expenses',
        body: anyNamed('body'),
      )).thenAnswer((_) async => ApiResponse(
            statusCode: 422,
            data: {
              'message': 'Insufficient balance',
              'errors': {
                'price_usd': ['Insufficient USD balance'],
              },
            },
          ));

      expect(
        () => expenseDataSource.createExpense(
          description: 'Expensive item',
          priceUsd: 50.0,
          expenseDate: '2024-11-16',
        ),
        throwsException,
      );
    });

    test('User can exchange to TRY currency', () async {
      // Exchange USD to TRY
      final exchangeResponse = {
        'data': {
          'id': 2,
          'target_currency': 'TRY',
          'amount_usd': 50.0,
          'exchange_rate': 30.0,
          'converted_amount': 1500.0,
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
        amountUsd: 50.0,
        exchangeRate: 30.0,
        exchangeDate: '2024-11-16',
      );

      expect(exchange.targetCurrency, 'TRY');
      expect(exchange.convertedAmount, 1500.0);
    });
  });
}
