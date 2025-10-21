import 'package:sqflite/sqflite.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/services/auth_logger.dart';
import '../models/incoming_model.dart';
import 'incoming_local_datasource.dart';

class IncomingLocalDataSourceImpl implements IncomingLocalDataSource {
  final Database database;

  IncomingLocalDataSourceImpl({required this.database});

  @override
  Future<IncomingModel> createIncoming({
    required int userId,
    required String description,
    required double amountUsd,
    DateTime? transactionDate,
  }) async {
    try {
      return await database.transaction((txn) async {
        final now = DateTime.now();
        final id = await txn.insert('incoming', {
          'user_id': userId,
          'description': description,
          'amount_usd': amountUsd,
          'transaction_date': (transactionDate ?? now).millisecondsSinceEpoch,
          'created_at': now.millisecondsSinceEpoch,
        });

        // Update fund box balance
        await txn.rawUpdate(
          'UPDATE fund_box SET balance_usd = balance_usd + ? WHERE user_id = ?',
          [amountUsd, userId],
        );

        final row = await txn.query(
          'incoming',
          where: 'id = ?',
          whereArgs: [id],
        );
        return IncomingModel.fromMap(row.first);
      });
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to create incoming transaction: $e');
    }
  }

  @override
  Future<List<IncomingModel>> getIncomingByUser(int userId) async {
    try {
      final rows = await database.query(
        'incoming',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'transaction_date DESC',
      );
      return rows.map((row) => IncomingModel.fromMap(row)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get incoming transactions: $e');
    }
  }

  @override
  Future<void> updateIncoming(IncomingModel incoming) async {
    try {
      await database.transaction((txn) async {
        // Get the old incoming transaction to calculate the difference
        final oldRows = await txn.query(
          'incoming',
          where: 'id = ? AND user_id = ?',
          whereArgs: [incoming.id, incoming.userId],
        );

        if (oldRows.isEmpty) {
          AuthLogger.logUnauthorizedAccess(
            operation: 'updateIncoming',
            attemptedUserId: incoming.userId,
            resourceOwnerId: null,
            resourceType: 'incoming',
            resourceId: incoming.id,
            additionalInfo: 'Incoming transaction not found or does not belong to user',
          );
          throw app_exceptions.UnauthorizedException('Incoming transaction not found or unauthorized');
        }

        // Log authorized access
        AuthLogger.logAuthorizedAccess(
          operation: 'updateIncoming',
          userId: incoming.userId,
          resourceType: 'incoming',
          resourceId: incoming.id,
        );

        final oldIncoming = IncomingModel.fromMap(oldRows.first);
        final amountDifference = incoming.amountUsd - oldIncoming.amountUsd;

        // Update the incoming transaction
        final updatedIncoming = incoming.copyWith(updatedAt: DateTime.now());
        await txn.update(
          'incoming',
          updatedIncoming.toMap(),
          where: 'id = ? AND user_id = ?',
          whereArgs: [incoming.id, incoming.userId],
        );

        // Update fund box balance if amount changed
        if (amountDifference != 0) {
          await txn.rawUpdate(
            'UPDATE fund_box SET balance_usd = balance_usd + ? WHERE user_id = ?',
            [amountDifference, incoming.userId],
          );
        }
      });
    } catch (e) {
      if (e is app_exceptions.UnauthorizedException) rethrow;
      throw app_exceptions.DatabaseException('Failed to update incoming transaction: $e');
    }
  }

  @override
  Future<void> deleteIncoming(int id, int userId, {bool refund = false}) async {
    try {
      await database.transaction((txn) async {
        // First verify the incoming transaction exists and belongs to the user
        final verifyRows = await txn.query(
          'incoming',
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );

        if (verifyRows.isEmpty) {
          AuthLogger.logUnauthorizedAccess(
            operation: 'deleteIncoming',
            attemptedUserId: userId,
            resourceOwnerId: null,
            resourceType: 'incoming',
            resourceId: id,
            additionalInfo: 'Incoming transaction not found or does not belong to user',
          );
          throw app_exceptions.UnauthorizedException('Incoming transaction not found or unauthorized');
        }

        // Log authorized access
        AuthLogger.logAuthorizedAccess(
          operation: 'deleteIncoming',
          userId: userId,
          resourceType: 'incoming',
          resourceId: id,
        );

        if (refund) {
          final incoming = IncomingModel.fromMap(verifyRows.first);
          // Subtract the amount from fund box
          await txn.rawUpdate(
            'UPDATE fund_box SET balance_usd = balance_usd - ? WHERE user_id = ?',
            [incoming.amountUsd, userId],
          );
        }

        // Delete the incoming transaction
        final deletedCount = await txn.delete(
          'incoming',
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );

        if (deletedCount == 0) {
          AuthLogger.logUnauthorizedAccess(
            operation: 'deleteIncoming',
            attemptedUserId: userId,
            resourceOwnerId: null,
            resourceType: 'incoming',
            resourceId: id,
            additionalInfo: 'Delete failed - incoming transaction not found or unauthorized',
          );
          throw app_exceptions.UnauthorizedException('Incoming transaction not found or unauthorized');
        }
      });
    } catch (e) {
      if (e is app_exceptions.UnauthorizedException) rethrow;
      throw app_exceptions.DatabaseException('Failed to delete incoming transaction: $e');
    }
  }
}

