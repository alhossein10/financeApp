import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/api/api_client.dart';
import 'package:finance_app/core/services/laravel_auth_service.dart';
import 'package:finance_app/core/services/token_manager.dart';
import 'package:finance_app/features/expenses/data/datasources/expense_api_datasource.dart';
import 'package:finance_app/features/transfers/data/datasources/transfer_api_datasource.dart';
import 'package:finance_app/features/incoming/data/datasources/incoming_api_datasource.dart';
import 'package:finance_app/features/fund_box/data/datasources/fund_box_api_datasource.dart';
import 'package:finance_app/features/admin/data/datasources/admin_api_datasource.dart';
import 'package:finance_app/features/expenses/data/models/expense_dto.dart';
import 'package:finance_app/features/transfers/data/models/transfer_dto.dart';
import 'package:finance_app/features/incoming/data/models/incoming_dto.dart';
import 'package:finance_app/core/utils/date_formatter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finance_app/core/config/api_config.dart';

/// Integration tests for Admin Group Data Scoping
/// Tests Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 11.6
/// 
/// These tests verify that:
/// - Users can only see data from their own admin group
/// - Data from other admin groups is not accessible
/// - Dashboard statistics are scoped to group members only
void main() {
  group('Admin Group Data Scoping Integration Tests', () {
    late ApiClient apiClient;
    late LaravelAuthService authService;
    late ExpenseApiDataSource expenseDataSource;
    late TransferApiDataSource transferDataSource;
    late IncomingApiDataSource incomingDataSource;
    late FundBoxApiDataSource fundBoxDataSource;
    late AdminApiDataSource adminDataSource;

    setUpAll(() async {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      apiClient = DioApiClient(dio: dio);
      final secureStorage = const FlutterSecureStorage();
      final tokenManager = TokenManager(secureStorage: secureStorage);
      authService = LaravelAuthService(
        apiClient: apiClient,
        tokenManager: tokenManager,
      );

      expenseDataSource = ExpenseApiDataSourceImpl(apiClient: apiClient);
      transferDataSource = TransferApiDataSourceImpl(apiClient: apiClient);
      incomingDataSource = IncomingApiDataSourceImpl(apiClient: apiClient);
      fundBoxDataSource = FundBoxApiDataSourceImpl(apiClient: apiClient);
      adminDataSource = AdminApiDataSourceImpl(apiClient: apiClient);
    });

    tearDownAll(() async {
      try {
        await authService.logout();
      } catch (e) {
        // Ignore logout errors
      }
    });

    test('Expense filtering: Users only see expenses from their admin group', () async {
      try {
        // Create Admin 1 with group code ABC123
        final admin1Email = 'admin1_expense_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 1 creates an expense
        final admin1Expense = ExpenseDto(
          amount: 100.0,
          category: 'Food',
          description: 'Admin 1 expense',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );
        final createdAdmin1Expense = await expenseDataSource.createExpense(admin1Expense);
        
        await authService.logout();

        // Create Admin 2 with different group
        final admin2Email = 'admin2_expense_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 creates an expense
        final admin2Expense = ExpenseDto(
          amount: 200.0,
          category: 'Transport',
          description: 'Admin 2 expense',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'card',
        );
        await expenseDataSource.createExpense(admin2Expense);

        // Admin 2 should NOT see Admin 1's expense
        final admin2Expenses = await expenseDataSource.getExpenses(perPage: 100);
        final hasAdmin1Expense = admin2Expenses.data.any((e) => e.id == createdAdmin1Expense.id);
        expect(hasAdmin1Expense, isFalse, reason: 'Admin 2 should not see Admin 1 expenses');

        await authService.logout();

        // Login back as Admin 1
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        
        // Admin 1 should see their own expense
        final admin1Expenses = await expenseDataSource.getExpenses(perPage: 100);
        final hasOwnExpense = admin1Expenses.data.any((e) => e.id == createdAdmin1Expense.id);
        expect(hasOwnExpense, isTrue, reason: 'Admin 1 should see their own expense');

        // Cleanup
        await expenseDataSource.deleteExpense(createdAdmin1Expense.id!);
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Transfer filtering: Users only see transfers from their admin group', () async {
      try {
        // Create Admin 1
        final admin1Email = 'admin1_transfer_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Transfer',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 1 creates a transfer
        final admin1Transfer = TransferDto(
          recipientName: 'Recipient 1',
          amountUsd: 500.0,
          transferDate: DateFormatter.toApiDate(DateTime.now()),
          notes: 'Admin 1 transfer',
        );
        final createdAdmin1Transfer = await transferDataSource.createTransfer(admin1Transfer);
        
        await authService.logout();

        // Create Admin 2
        final admin2Email = 'admin2_transfer_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Transfer',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 creates a transfer
        final admin2Transfer = TransferDto(
          recipientName: 'Recipient 2',
          amountUsd: 750.0,
          transferDate: DateFormatter.toApiDate(DateTime.now()),
          notes: 'Admin 2 transfer',
        );
        await transferDataSource.createTransfer(admin2Transfer);

        // Admin 2 should NOT see Admin 1's transfer
        final admin2Transfers = await transferDataSource.getTransfers(perPage: 100);
        final hasAdmin1Transfer = admin2Transfers.data.any((t) => t.id == createdAdmin1Transfer.id);
        expect(hasAdmin1Transfer, isFalse, reason: 'Admin 2 should not see Admin 1 transfers');

        await authService.logout();

        // Login back as Admin 1
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        
        // Admin 1 should see their own transfer
        final admin1Transfers = await transferDataSource.getTransfers(perPage: 100);
        final hasOwnTransfer = admin1Transfers.data.any((t) => t.id == createdAdmin1Transfer.id);
        expect(hasOwnTransfer, isTrue, reason: 'Admin 1 should see their own transfer');

        // Cleanup
        await transferDataSource.deleteTransfer(createdAdmin1Transfer.id!);
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Incoming filtering: Users only see incoming from their admin group', () async {
      try {
        // Create Admin 1
        final admin1Email = 'admin1_incoming_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Incoming',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 1 creates incoming
        final admin1Incoming = IncomingDto(
          amount: 1000.0,
          source: 'Source 1',
          description: 'Admin 1 incoming',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'bank_transfer',
        );
        final createdAdmin1Incoming = await incomingDataSource.createIncoming(admin1Incoming);
        
        await authService.logout();

        // Create Admin 2
        final admin2Email = 'admin2_incoming_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Incoming',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 creates incoming
        final admin2Incoming = IncomingDto(
          amount: 1500.0,
          source: 'Source 2',
          description: 'Admin 2 incoming',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );
        await incomingDataSource.createIncoming(admin2Incoming);

        // Admin 2 should NOT see Admin 1's incoming
        final admin2IncomingList = await incomingDataSource.getIncoming(perPage: 100);
        final hasAdmin1Incoming = admin2IncomingList.data.any((i) => i.id == createdAdmin1Incoming.id);
        expect(hasAdmin1Incoming, isFalse, reason: 'Admin 2 should not see Admin 1 incoming');

        await authService.logout();

        // Login back as Admin 1
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        
        // Admin 1 should see their own incoming
        final admin1IncomingList = await incomingDataSource.getIncoming(perPage: 100);
        final hasOwnIncoming = admin1IncomingList.data.any((i) => i.id == createdAdmin1Incoming.id);
        expect(hasOwnIncoming, isTrue, reason: 'Admin 1 should see their own incoming');

        // Cleanup
        await incomingDataSource.deleteIncoming(createdAdmin1Incoming.id!);
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Fund box filtering: Each admin group has separate fund box', () async {
      try {
        // Create Admin 1
        final admin1Email = 'admin1_fundbox_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 FundBox',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 1 updates fund box
        final admin1Balance = 5000.0;
        await fundBoxDataSource.updateFundBox(admin1Balance);
        
        final admin1FundBox = await fundBoxDataSource.getFundBox();
        expect(admin1FundBox.totalBalance, equals(admin1Balance));
        
        await authService.logout();

        // Create Admin 2
        final admin2Email = 'admin2_fundbox_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 FundBox',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 updates their fund box
        final admin2Balance = 7500.0;
        await fundBoxDataSource.updateFundBox(admin2Balance);
        
        final admin2FundBox = await fundBoxDataSource.getFundBox();
        expect(admin2FundBox.totalBalance, equals(admin2Balance));
        
        // Admin 2's fund box should be different from Admin 1's
        expect(admin2FundBox.totalBalance, isNot(equals(admin1Balance)));
        
        await authService.logout();

        // Login back as Admin 1
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        
        // Admin 1 should still see their original balance
        final admin1FundBoxAgain = await fundBoxDataSource.getFundBox();
        expect(admin1FundBoxAgain.totalBalance, equals(admin1Balance));
        
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Dashboard statistics: Calculated only from group members data', () async {
      try {
        // Create Admin 1
        final admin1Email = 'admin1_stats_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Stats',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 1 creates some data
        final expense1 = ExpenseDto(
          amount: 100.0,
          category: 'Food',
          description: 'Test expense',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );
        final createdExpense1 = await expenseDataSource.createExpense(expense1);

        final incoming1 = IncomingDto(
          amount: 500.0,
          source: 'Test source',
          description: 'Test incoming',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );
        final createdIncoming1 = await incomingDataSource.createIncoming(incoming1);

        // Get Admin 1's dashboard stats
        final admin1Stats = await adminDataSource.getDashboardStats();
        final admin1ExpenseCount = admin1Stats.totalExpenses;
        final admin1IncomeCount = admin1Stats.totalIncome;
        
        await authService.logout();

        // Create Admin 2
        final admin2Email = 'admin2_stats_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Stats',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 creates different data
        final expense2 = ExpenseDto(
          amount: 200.0,
          category: 'Transport',
          description: 'Test expense 2',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'card',
        );
        await expenseDataSource.createExpense(expense2);

        // Get Admin 2's dashboard stats
        final admin2Stats = await adminDataSource.getDashboardStats();
        
        // Admin 2's stats should NOT include Admin 1's data
        expect(admin2Stats.totalExpenses, isNot(equals(admin1ExpenseCount)));
        expect(admin2Stats.totalIncome, isNot(equals(admin1IncomeCount)));
        
        await authService.logout();

        // Login back as Admin 1
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        
        // Admin 1's stats should remain the same
        final admin1StatsAgain = await adminDataSource.getDashboardStats();
        expect(admin1StatsAgain.totalExpenses, equals(admin1ExpenseCount));
        expect(admin1StatsAgain.totalIncome, equals(admin1IncomeCount));

        // Cleanup
        await expenseDataSource.deleteExpense(createdExpense1.id!);
        await incomingDataSource.deleteIncoming(createdIncoming1.id!);
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('User activity: Admins only see members from their group', () async {
      try {
        // Create Admin 1
        final admin1Email = 'admin1_activity_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Activity',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Get Admin 1's user activity
        final admin1Activity = await adminDataSource.getUserActivity(page: 1, perPage: 100);
        final admin1UserCount = admin1Activity.length;
        
        await authService.logout();

        // Create Admin 2
        final admin2Email = 'admin2_activity_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Activity',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Get Admin 2's user activity
        final admin2Activity = await adminDataSource.getUserActivity(page: 1, perPage: 100);
        
        // Admin 2 should NOT see Admin 1 in their user list
        final hasAdmin1 = admin2Activity.any((u) => u.email == admin1Email);
        expect(hasAdmin1, isFalse, reason: 'Admin 2 should not see Admin 1 in user activity');
        
        // Admin 2's user count should be different from Admin 1's
        expect(admin2Activity.length, isNot(equals(admin1UserCount)));
        
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Expense summaries: Calculated only from group members expenses', () async {
      try {
        // Create Admin 1
        final admin1Email = 'admin1_summary_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Summary',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 1 creates expenses in specific category
        final expense1 = ExpenseDto(
          amount: 100.0,
          category: 'Food',
          description: 'Test food expense',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );
        final createdExpense1 = await expenseDataSource.createExpense(expense1);

        // Get Admin 1's expense summary
        final admin1Summary = await adminDataSource.getExpenseSummary();
        final admin1FoodTotal = admin1Summary.byCategory['Food']?.total ?? 0.0;
        
        await authService.logout();

        // Create Admin 2
        final admin2Email = 'admin2_summary_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Summary',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 creates expenses in same category
        final expense2 = ExpenseDto(
          amount: 200.0,
          category: 'Food',
          description: 'Test food expense 2',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'card',
        );
        await expenseDataSource.createExpense(expense2);

        // Get Admin 2's expense summary
        final admin2Summary = await adminDataSource.getExpenseSummary();
        final admin2FoodTotal = admin2Summary.byCategory['Food']?.total ?? 0.0;
        
        // Admin 2's food total should NOT include Admin 1's expenses
        expect(admin2FoodTotal, isNot(equals(admin1FoodTotal)));
        
        await authService.logout();

        // Login back as Admin 1
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        
        // Cleanup
        await expenseDataSource.deleteExpense(createdExpense1.id!);
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Analytics: Calculated only from group members data', () async {
      try {
        // Create Admin 1
        final admin1Email = 'admin1_analytics_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Analytics',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 1 creates data
        final expense1 = ExpenseDto(
          amount: 150.0,
          category: 'Food',
          description: 'Test expense',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        );
        final createdExpense1 = await expenseDataSource.createExpense(expense1);

        // Get Admin 1's analytics
        final dateFrom = DateTime.now().subtract(const Duration(days: 7));
        final dateTo = DateTime.now();
        final admin1Analytics = await adminDataSource.getAnalytics(
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
        final admin1ExpenseTotal = admin1Analytics.expenses.total;
        
        await authService.logout();

        // Create Admin 2
        final admin2Email = 'admin2_analytics_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Analytics',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Admin 2 creates data
        final expense2 = ExpenseDto(
          amount: 250.0,
          category: 'Transport',
          description: 'Test expense 2',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'card',
        );
        await expenseDataSource.createExpense(expense2);

        // Get Admin 2's analytics
        final admin2Analytics = await adminDataSource.getAnalytics(
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
        
        // Admin 2's analytics should NOT include Admin 1's data
        expect(admin2Analytics.expenses.total, isNot(equals(admin1ExpenseTotal)));
        
        await authService.logout();

        // Login back as Admin 1
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        
        // Cleanup
        await expenseDataSource.deleteExpense(createdExpense1.id!);
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });

    test('Cross-group data isolation: Complete end-to-end verification', () async {
      try {
        // Create Admin 1 with complete dataset
        final admin1Email = 'admin1_isolation_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 1 Isolation',
          email: admin1Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Create comprehensive data for Admin 1
        final admin1Expense = await expenseDataSource.createExpense(ExpenseDto(
          amount: 100.0,
          category: 'Food',
          description: 'Admin 1 expense',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'cash',
        ));

        final admin1Transfer = await transferDataSource.createTransfer(TransferDto(
          recipientName: 'Admin 1 Recipient',
          amountUsd: 500.0,
          transferDate: DateFormatter.toApiDate(DateTime.now()),
          notes: 'Admin 1 transfer',
        ));

        final admin1Incoming = await incomingDataSource.createIncoming(IncomingDto(
          amount: 1000.0,
          source: 'Admin 1 Source',
          description: 'Admin 1 incoming',
          date: DateFormatter.toApiDate(DateTime.now()),
          paymentMethod: 'bank_transfer',
        ));

        await fundBoxDataSource.updateFundBox(5000.0);
        
        await authService.logout();

        // Create Admin 2 with different dataset
        final admin2Email = 'admin2_isolation_${DateTime.now().millisecondsSinceEpoch}@example.com';
        await authService.register(
          name: 'Admin 2 Isolation',
          email: admin2Email,
          password: 'TestPassword123!',
          role: 'admin',
        );

        // Verify Admin 2 cannot see any of Admin 1's data
        final admin2Expenses = await expenseDataSource.getExpenses(perPage: 100);
        expect(admin2Expenses.data.any((e) => e.id == admin1Expense.id), isFalse);

        final admin2Transfers = await transferDataSource.getTransfers(perPage: 100);
        expect(admin2Transfers.data.any((t) => t.id == admin1Transfer.id), isFalse);

        final admin2Incoming = await incomingDataSource.getIncoming(perPage: 100);
        expect(admin2Incoming.data.any((i) => i.id == admin1Incoming.id), isFalse);

        final admin2FundBox = await fundBoxDataSource.getFundBox();
        expect(admin2FundBox.totalBalance, isNot(equals(5000.0)));

        final admin2Stats = await adminDataSource.getDashboardStats();
        final admin2Activity = await adminDataSource.getUserActivity(page: 1, perPage: 100);
        expect(admin2Activity.any((u) => u.email == admin1Email), isFalse);
        
        await authService.logout();

        // Verify Admin 1 still has access to their data
        await authService.login(email: admin1Email, password: 'TestPassword123!');
        
        final admin1ExpensesAgain = await expenseDataSource.getExpenses(perPage: 100);
        expect(admin1ExpensesAgain.data.any((e) => e.id == admin1Expense.id), isTrue);

        final admin1TransfersAgain = await transferDataSource.getTransfers(perPage: 100);
        expect(admin1TransfersAgain.data.any((t) => t.id == admin1Transfer.id), isTrue);

        final admin1IncomingAgain = await incomingDataSource.getIncoming(perPage: 100);
        expect(admin1IncomingAgain.data.any((i) => i.id == admin1Incoming.id), isTrue);

        final admin1FundBoxAgain = await fundBoxDataSource.getFundBox();
        expect(admin1FundBoxAgain.totalBalance, equals(5000.0));

        // Cleanup
        await expenseDataSource.deleteExpense(admin1Expense.id!);
        await transferDataSource.deleteTransfer(admin1Transfer.id!);
        await incomingDataSource.deleteIncoming(admin1Incoming.id!);
        await authService.logout();
      } catch (e) {
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Connection refused')) {
          print('Skipping test - API not available');
          return;
        }
        rethrow;
      }
    });
  });
}
