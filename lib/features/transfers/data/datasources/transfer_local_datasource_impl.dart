import 'package:sqflite/sqflite.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/services/auth_logger.dart';
import '../models/transfer_model.dart';
import 'transfer_local_datasource.dart';

class TransferLocalDataSourceImpl implements TransferLocalDataSource {
  final Database database;

  TransferLocalDataSourceImpl({required this.database});

  @override
  Future<TransferModel> createTransfer({
    required int userId,
    required String recipientName,
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  }) async {
    try {
      return await database.transaction((txn) async {
        // Check fund box balance for the user
        final fundRows = await txn.query(
          'fund_box',
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        if (fundRows.isEmpty) {
          throw app_exceptions.DatabaseException('Fund box not found for user');
        }

        final currentBalance = (fundRows.first['balance_usd'] as num).toDouble();
        final newBalance = currentBalance - amountUsd;

        if (newBalance < 0) {
          throw app_exceptions.DatabaseException('Insufficient fund balance');
        }

        // Update fund box balance
        await txn.update(
          'fund_box',
          {
            'balance_usd': newBalance,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        // Insert transfer
        final now = DateTime.now();
        final id = await txn.insert('transfers', {
          'user_id': userId,
          'recipient_name': recipientName,
          'amount_usd': amountUsd,
          'converted_amount_usd': convertedAmountUsd,
          'amount_syp_at_exchange': amountSypAtExchange,
          'manual_usd_to_syp_rate': manualUsdToSypRate,
          'transaction_date': (transactionDate ?? now).millisecondsSinceEpoch,
          'created_at': now.millisecondsSinceEpoch,
        });

        // Retrieve and return the created transfer
        final rows = await txn.query(
          'transfers',
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );

        if (rows.isEmpty) {
          throw app_exceptions.DatabaseException('Failed to retrieve created transfer');
        }

        return TransferModel.fromMap(rows.first);
      });
    } catch (e) {
      if (e is app_exceptions.DatabaseException) rethrow;
      throw app_exceptions.DatabaseException('Failed to create transfer: ${e.toString()}');
    }
  }

  @override
  Future<List<TransferModel>> getTransfersByUser(int userId) async {
    try {
      final rows = await database.query(
        'transfers',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'transaction_date DESC, created_at DESC',
      );

      return rows.map((row) => TransferModel.fromMap(row)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get transfers: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTransfer(TransferModel transfer) async {
    try {
      if (transfer.id == null) {
        throw app_exceptions.DatabaseException('Transfer ID is required for update');
      }

      // Verify the transfer belongs to the user
      late TransferModel existing;
      try {
        existing = await getTransferById(transfer.id!, transfer.userId);
        
        // Log authorized access
        AuthLogger.logAuthorizedAccess(
          operation: 'updateTransfer',
          userId: transfer.userId,
          resourceType: 'transfer',
          resourceId: transfer.id,
        );

      } on app_exceptions.NotFoundException catch (e) {
        // Log unauthorized access attempt
        AuthLogger.logUnauthorizedAccess(
          operation: 'updateTransfer',
          attemptedUserId: transfer.userId,
          resourceOwnerId: null,
          resourceType: 'transfer',
          resourceId: transfer.id,
          additionalInfo: 'Transfer not found or does not belong to user',
        );
        throw app_exceptions.UnauthorizedException('Transfer not found or unauthorized access');
      }

      await database.transaction((txn) async {
        // Calculate balance difference
        final balanceDiff = existing.amountUsd - transfer.amountUsd;

        if (balanceDiff != 0) {
          // Update fund box if amount changed
          final fundRows = await txn.query(
            'fund_box',
            where: 'user_id = ?',
            whereArgs: [transfer.userId],
          );

          if (fundRows.isEmpty) {
            throw app_exceptions.DatabaseException('Fund box not found for user');
          }

          final currentBalance =
              (fundRows.first['balance_usd'] as num).toDouble();
          final newBalance = currentBalance + balanceDiff;

          if (newBalance < 0) {
            throw app_exceptions.DatabaseException('Insufficient fund balance');
          }

          await txn.update(
            'fund_box',
            {
              'balance_usd': newBalance,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'user_id = ?',
            whereArgs: [transfer.userId],
          );
        }

        // Update transfer
        final updateData = transfer.toMap();
        updateData['updated_at'] = DateTime.now().millisecondsSinceEpoch;

        final count = await txn.update(
          'transfers',
          updateData,
          where: 'id = ? AND user_id = ?',
          whereArgs: [transfer.id, transfer.userId],
        );

        if (count == 0) {
          AuthLogger.logUnauthorizedAccess(
            operation: 'updateTransfer',
            attemptedUserId: transfer.userId,
            resourceOwnerId: null,
            resourceType: 'transfer',
            resourceId: transfer.id,
            additionalInfo: 'Update failed - transfer not found or unauthorized',
          );
          throw app_exceptions.UnauthorizedException(
              'Transfer not found or unauthorized access');
        }
      });
    } catch (e) {
      if (e is app_exceptions.DatabaseException || e is app_exceptions.UnauthorizedException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update transfer: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTransfer(
    int id,
    int userId, {
    bool refund = false,
  }) async {
    try {
      await database.transaction((txn) async {
        // Verify the transfer belongs to the user and get its data
        final rows = await txn.query(
          'transfers',
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );

        if (rows.isEmpty) {
          AuthLogger.logUnauthorizedAccess(
            operation: 'deleteTransfer',
            attemptedUserId: userId,
            resourceOwnerId: null,
            resourceType: 'transfer',
            resourceId: id,
            additionalInfo: 'Transfer not found or does not belong to user',
          );
          throw app_exceptions.UnauthorizedException(
              'Transfer not found or unauthorized access');
        }

        // Log authorized access
        AuthLogger.logAuthorizedAccess(
          operation: 'deleteTransfer',
          userId: userId,
          resourceType: 'transfer',
          resourceId: id,
        );

        if (refund) {
          final transfer = TransferModel.fromMap(rows.first);

          // Refund to fund box
          final fundRows = await txn.query(
            'fund_box',
            where: 'user_id = ?',
            whereArgs: [userId],
          );

          if (fundRows.isNotEmpty) {
            final currentBalance =
                (fundRows.first['balance_usd'] as num).toDouble();
            final newBalance = currentBalance + transfer.amountUsd;

            await txn.update(
              'fund_box',
              {
                'balance_usd': newBalance,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'user_id = ?',
              whereArgs: [userId],
            );
          }
        }

        // Delete the transfer
        await txn.delete(
          'transfers',
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );
      });
    } catch (e) {
      if (e is app_exceptions.DatabaseException || e is app_exceptions.UnauthorizedException) rethrow;
      throw app_exceptions.DatabaseException('Failed to delete transfer: ${e.toString()}');
    }
  }

  @override
  Future<TransferModel> getTransferById(int id, int userId) async {
    try {
      final rows = await database.query(
        'transfers',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );

      if (rows.isEmpty) {
        throw app_exceptions.NotFoundException('Transfer not found');
      }

      return TransferModel.fromMap(rows.first);
    } catch (e) {
      if (e is app_exceptions.NotFoundException) rethrow;
      throw app_exceptions.DatabaseException('Failed to get transfer: ${e.toString()}');
    }
  }
}

