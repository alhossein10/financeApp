/// DEPRECATED: This file is kept for backward compatibility only
/// 
/// This app now uses Laravel backend with MySQL database.
/// All database operations go through Laravel API endpoints.
/// 
/// Local SQLite database is NO LONGER USED except for:
/// - Data migration tool (to migrate old SQLite data to Laravel)
/// - Offline cache (handled by Hive, not SQLite)
/// 
/// DO NOT use this class for new features. Use API data sources instead:
/// - ExpenseApiDataSource
/// - TransferApiDataSource
/// - IncomingApiDataSource
/// - FundBoxApiDataSource
/// - etc.
library;

import 'dart:async';

import '../models/exchange_record.dart';
import '../models/expense.dart';
import '../models/fund_box.dart';
import '../models/incoming.dart';
import '../models/transfer.dart';

// Type alias for compatibility
typedef Database = dynamic;

/// AppDatabase - DEPRECATED stub for Laravel backend version
/// 
/// ⚠️ WARNING: Do not use this class!
/// All data operations should go through Laravel API services.
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  static const int _dbVersion = 7;
  static const String _dbName = 'finance_app.db';

  Database? _db;

  @Deprecated('Use API services instead of local database')
  Future<Database> get database async {
    throw UnimplementedError(
      'Local SQLite database is not used in Laravel version.\n'
      'Use API data sources instead:\n'
      '- ExpenseApiDataSource for expenses\n'
      '- TransferApiDataSource for transfers\n'
      '- IncomingApiDataSource for incoming\n'
      '- FundBoxApiDataSource for fund box\n'
    );
  }

  // All methods below throw errors - use API services instead
  
  @Deprecated('Use FundBoxApiDataSource.getFundBox() instead')
  Future<FundBox> getFundBox() async {
    throw UnimplementedError('Use FundBoxApiDataSource.getFundBox() instead');
  }

  @Deprecated('Use FundBoxApiDataSource.updateBalance() instead')
  Future<void> setFundBalanceUsd(double newBalance) async {
    throw UnimplementedError('Use FundBoxApiDataSource.updateBalance() instead');
  }

  @Deprecated('Use TransferApiDataSource.createTransfer() instead')
  Future<TransferRecord> createTransfer({
    required String recipientName,
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  }) async {
    throw UnimplementedError('Use TransferApiDataSource.createTransfer() instead');
  }

  Future<List<TransferRecord>> listTransfers() async {
    throw UnimplementedError('Use TransferApiDataSource instead');
  }

  Future<void> updateTransfer(TransferRecord record) async {
    throw UnimplementedError('Use TransferApiDataSource instead');
  }

  Future<void> deleteTransfer(int id, {bool refund = false}) async {
    throw UnimplementedError('Use TransferApiDataSource instead');
  }

  Future<int> createExpense(ExpenseRecord record) async {
    throw UnimplementedError('Use ExpenseApiDataSource instead');
  }

  Future<void> updateExpense(ExpenseRecord record) async {
    throw UnimplementedError('Use ExpenseApiDataSource instead');
  }

  Future<void> deleteExpense(int id) async {
    throw UnimplementedError('Use ExpenseApiDataSource instead');
  }

  Future<List<ExpenseRecord>> listExpenses() async {
    throw UnimplementedError('Use ExpenseApiDataSource instead');
  }

  Future<IncomingRecord> createIncoming({
    required String description,
    required double amountUsd,
    DateTime? transactionDate,
  }) async {
    throw UnimplementedError('Use IncomingApiDataSource instead');
  }

  Future<List<IncomingRecord>> listIncoming() async {
    throw UnimplementedError('Use IncomingApiDataSource instead');
  }

  Future<void> updateIncoming(IncomingRecord record) async {
    throw UnimplementedError('Use IncomingApiDataSource instead');
  }

  Future<void> deleteIncoming(int id, {bool refund = false}) async {
    throw UnimplementedError('Use IncomingApiDataSource instead');
  }

  Future<int> createExchangeRecord(ExchangeRecord record) async {
    throw UnimplementedError('Use API instead');
  }

  Future<List<ExchangeRecord>> listExchangesByTransfer(int transferId) async {
    throw UnimplementedError('Use API instead');
  }

  Future<void> deleteExchangeRecord(int id) async {
    throw UnimplementedError('Use API instead');
  }
}
