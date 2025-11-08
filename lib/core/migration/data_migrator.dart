import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:path_provider/path_provider.dart';

import '../../data/db.dart';
import '../../models/expense.dart';
import '../../models/transfer.dart';
import '../../models/incoming.dart';
import '../../models/exchange_record.dart';
import '../services/batch_sync_service.dart';
import '../models/batch_record.dart';
import '../models/sync_request_dto.dart';

/// Result of a migration operation
class MigrationResult {
  final bool success;
  final int totalRecords;
  final int successfulRecords;
  final int failedRecords;
  final List<String> errors;
  final String? exportFilePath;

  MigrationResult({
    required this.success,
    required this.totalRecords,
    required this.successfulRecords,
    required this.failedRecords,
    required this.errors,
    this.exportFilePath,
  });

  double get progressPercentage =>
      totalRecords > 0 ? (successfulRecords / totalRecords) * 100 : 0;
}

/// Service for migrating data from SQLite to Laravel backend
class DataMigrator {
  final AppDatabase database;
  final BatchSyncService batchSyncService;

  DataMigrator({
    required this.database,
    required this.batchSyncService,
  });

  /// Export all SQLite data to JSON file
  Future<File> exportToJson() async {
    try {
      developer.log('Starting data export to JSON', name: 'DataMigrator');

      // Fetch all data from SQLite
      final expenses = await database.listExpenses();
      final transfers = await database.listTransfers();
      final incoming = await database.listIncoming();

      // Fetch exchange history for all transfers
      final exchangeHistory = <int, List<ExchangeRecord>>{};
      for (final transfer in transfers) {
        if (transfer.id != null) {
          final exchanges = await database.listExchangesByTransfer(transfer.id!);
          if (exchanges.isNotEmpty) {
            exchangeHistory[transfer.id!] = exchanges;
          }
        }
      }

      // Create export data structure
      final exportData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'expenses': expenses.map((e) => _expenseToJson(e)).toList(),
        'transfers': transfers.map((t) => _transferToJson(t, exchangeHistory[t.id])).toList(),
        'incoming': incoming.map((i) => _incomingToJson(i)).toList(),
        'statistics': {
          'total_expenses': expenses.length,
          'total_transfers': transfers.length,
          'total_incoming': incoming.length,
          'total_records': expenses.length + transfers.length + incoming.length,
        },
      };

      // Write to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/finance_data_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json.encode(exportData));

      developer.log('Data exported to: ${file.path}', name: 'DataMigrator');
      return file;
    } catch (e) {
      developer.log('Export failed: $e', name: 'DataMigrator', error: e);
      rethrow;
    }
  }

  /// Transform expense to JSON format
  Map<String, dynamic> _expenseToJson(ExpenseRecord expense) {
    return {
      'id': expense.id,
      'description': expense.description,
      'price_usd': expense.priceUsd,
      'price_syp': expense.priceSyp,
      'price_try': expense.priceTry,
      'invoice_status': expense.invoiceStatus.index,
      'invoice_file_path': expense.invoiceFilePath,
      'expense_date': expense.expenseDate.toIso8601String(),
      'created_at': expense.createdAt.toIso8601String(),
      'updated_at': expense.updatedAt?.toIso8601String(),
    };
  }

  /// Transform transfer to JSON format
  Map<String, dynamic> _transferToJson(TransferRecord transfer, List<ExchangeRecord>? exchanges) {
    return {
      'id': transfer.id,
      'recipient_name': transfer.recipientName,
      'amount_usd': transfer.amountUsd,
      'converted_amount_usd': transfer.convertedAmountUsd,
      'amount_syp_at_exchange': transfer.amountSypAtExchange,
      'manual_usd_to_syp_rate': transfer.manualUsdToSypRate,
      'transaction_date': transfer.transactionDate.toIso8601String(),
      'created_at': transfer.createdAt.toIso8601String(),
      'updated_at': transfer.updatedAt?.toIso8601String(),
      'exchanges': exchanges?.map((e) => _exchangeToJson(e)).toList() ?? [],
    };
  }

  /// Transform exchange record to JSON format
  Map<String, dynamic> _exchangeToJson(ExchangeRecord exchange) {
    return {
      'id': exchange.id,
      'transfer_id': exchange.transferId,
      'converted_amount_usd': exchange.convertedAmountUsd,
      'amount_syp_at_exchange': exchange.amountSypAtExchange,
      'manual_usd_to_syp_rate': exchange.manualUsdToSypRate,
      'created_at': exchange.createdAt.toIso8601String(),
    };
  }

  /// Transform incoming to JSON format
  Map<String, dynamic> _incomingToJson(IncomingRecord incoming) {
    return {
      'id': incoming.id,
      'description': incoming.description,
      'amount_usd': incoming.amountUsd,
      'transaction_date': incoming.transactionDate.toIso8601String(),
      'created_at': incoming.createdAt.toIso8601String(),
      'updated_at': incoming.updatedAt?.toIso8601String(),
    };
  }

  /// Transform expense to API format
  Map<String, dynamic> _expenseToApiFormat(ExpenseRecord expense) {
    return {
      'description': expense.description,
      if (expense.priceUsd != null) 'price_usd': expense.priceUsd,
      if (expense.priceSyp != null) 'price_syp': expense.priceSyp,
      if (expense.priceTry != null) 'price_try': expense.priceTry,
      'has_invoice': expense.invoiceStatus == InvoiceStatus.invoiceAvailable,
      'expense_date': expense.expenseDate.toIso8601String(),
    };
  }

  /// Transform transfer to API format
  Map<String, dynamic> _transferToApiFormat(TransferRecord transfer) {
    return {
      'recipient_name': transfer.recipientName,
      'amount_usd': transfer.amountUsd,
      if (transfer.convertedAmountUsd != null)
        'converted_amount_usd': transfer.convertedAmountUsd,
      if (transfer.amountSypAtExchange != null)
        'amount_syp_at_exchange': transfer.amountSypAtExchange,
      if (transfer.manualUsdToSypRate != null)
        'manual_usd_to_syp_rate': transfer.manualUsdToSypRate,
      'transfer_date': transfer.transactionDate.toIso8601String(),
    };
  }

  /// Transform incoming to API format
  Map<String, dynamic> _incomingToApiFormat(IncomingRecord incoming) {
    return {
      'description': incoming.description,
      'amount_usd': incoming.amountUsd,
      'incoming_date': incoming.transactionDate.toIso8601String(),
    };
  }

  /// Migrate all data to Laravel backend
  Future<MigrationResult> migrateToBackend({
    Function(int current, int total, String message)? onProgress,
  }) async {
    final errors = <String>[];
    int totalRecords = 0;
    int successfulRecords = 0;
    int failedRecords = 0;

    try {
      developer.log('Starting data migration to Laravel backend', name: 'DataMigrator');

      // Fetch all data
      onProgress?.call(0, 100, 'Fetching data from local database...');
      final expenses = await database.listExpenses();
      final transfers = await database.listTransfers();
      final incoming = await database.listIncoming();

      totalRecords = expenses.length + transfers.length + incoming.length;

      if (totalRecords == 0) {
        return MigrationResult(
          success: true,
          totalRecords: 0,
          successfulRecords: 0,
          failedRecords: 0,
          errors: ['No data to migrate'],
        );
      }

      // Prepare batch records
      final batchRecords = <BatchRecord>[];

      // Add expenses
      for (final expense in expenses) {
        batchRecords.add(BatchRecord(
          type: 'expense',
          action: 'create',
          data: _expenseToApiFormat(expense),
          localId: expense.id?.toString(),
        ));
      }

      // Add transfers
      for (final transfer in transfers) {
        batchRecords.add(BatchRecord(
          type: 'transfer',
          action: 'create',
          data: _transferToApiFormat(transfer),
          localId: transfer.id?.toString(),
        ));
      }

      // Add incoming
      for (final incomingRecord in incoming) {
        batchRecords.add(BatchRecord(
          type: 'incoming',
          action: 'create',
          data: _incomingToApiFormat(incomingRecord),
          localId: incomingRecord.id?.toString(),
        ));
      }

      // Upload in batches
      onProgress?.call(10, 100, 'Uploading data to server...');
      
      // Convert batch records to sync data format
      final syncData = SyncDataDto(
        expenses: batchRecords
            .where((r) => r.type == 'expense')
            .map((r) => r.data)
            .toList(),
        incoming: batchRecords
            .where((r) => r.type == 'incoming')
            .map((r) => r.data)
            .toList(),
        transfers: batchRecords
            .where((r) => r.type == 'transfer')
            .map((r) => r.data)
            .toList(),
      );
      
      final response = await batchSyncService.batchSync(
        lastSync: DateTime.now().subtract(const Duration(days: 365)),
        data: syncData,
      );

      successfulRecords = response.totalCreated;
      failedRecords = response.totalConflicts;

      // Collect errors from conflicts
      if (response.allConflicts.isNotEmpty) {
        for (final conflict in response.allConflicts) {
          errors.add('Conflict: ${conflict.reason} - Local ID: ${conflict.localId}');
        }
      }

      onProgress?.call(90, 100, 'Verifying data integrity...');

      // Verify data integrity
      final verificationResult = await _verifyDataIntegrity(
        expenses.length,
        transfers.length,
        incoming.length,
        response,
      );

      if (!verificationResult) {
        errors.add('Data integrity verification failed');
      }

      onProgress?.call(100, 100, 'Migration complete');

      final success = failedRecords == 0 && verificationResult;

      developer.log(
        'Migration completed: $successfulRecords/$totalRecords successful, $failedRecords failed',
        name: 'DataMigrator',
      );

      return MigrationResult(
        success: success,
        totalRecords: totalRecords,
        successfulRecords: successfulRecords,
        failedRecords: failedRecords,
        errors: errors,
      );
    } catch (e) {
      developer.log('Migration failed: $e', name: 'DataMigrator', error: e);
      errors.add('Migration error: $e');

      return MigrationResult(
        success: false,
        totalRecords: totalRecords,
        successfulRecords: successfulRecords,
        failedRecords: failedRecords,
        errors: errors,
      );
    }
  }

  /// Verify data integrity after migration
  Future<bool> _verifyDataIntegrity(
    int expectedExpenses,
    int expectedTransfers,
    int expectedIncoming,
    dynamic response,
  ) async {
    try {
      // For now, just check if total created matches expected
      final totalExpected = expectedExpenses + expectedTransfers + expectedIncoming;
      final totalCreated = response.totalCreated as int;
      
      if (totalCreated != totalExpected) {
        developer.log(
          'Record count mismatch: expected $totalExpected, got $totalCreated',
          name: 'DataMigrator',
        );
        return false;
      }

      return true;
    } catch (e) {
      developer.log('Data integrity verification error: $e', name: 'DataMigrator', error: e);
      return false;
    }
  }

  /// Export and migrate in one operation
  Future<MigrationResult> exportAndMigrate({
    Function(int current, int total, String message)? onProgress,
  }) async {
    try {
      // Export to JSON first
      onProgress?.call(0, 100, 'Exporting data to JSON...');
      final exportFile = await exportToJson();

      // Then migrate
      onProgress?.call(5, 100, 'Starting migration...');
      final result = await migrateToBackend(
        onProgress: (current, total, message) {
          // Scale progress from 5-100
          final scaledProgress = 5 + ((current / total) * 95).round();
          onProgress?.call(scaledProgress, 100, message);
        },
      );

      return MigrationResult(
        success: result.success,
        totalRecords: result.totalRecords,
        successfulRecords: result.successfulRecords,
        failedRecords: result.failedRecords,
        errors: result.errors,
        exportFilePath: exportFile.path,
      );
    } catch (e) {
      developer.log('Export and migrate failed: $e', name: 'DataMigrator', error: e);
      return MigrationResult(
        success: false,
        totalRecords: 0,
        successfulRecords: 0,
        failedRecords: 0,
        errors: ['Export and migrate error: $e'],
      );
    }
  }
}
