import 'package:sqflite/sqflite.dart';

import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/fund_box_model.dart';
import 'fund_box_local_datasource.dart';

/// Implementation of FundBoxLocalDataSource using SQLite
/// Handles all database operations for fund box data
class FundBoxLocalDataSourceImpl implements FundBoxLocalDataSource {
  final Database database;

  FundBoxLocalDataSourceImpl({required this.database});

  @override
  Future<FundBoxModel> getFundBoxByUser(int userId) async {
    try {
      final results = await database.query(
        'fund_box',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (results.isEmpty) {
        throw app_exceptions.DatabaseException('Fund box not found for user $userId');
      }

      return FundBoxModel.fromMap(results.first);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get fund box: ${e.toString()}');
    }
  }

  @override
  Future<FundBoxModel> updateFundBalance({
    required int userId,
    required double newBalance,
  }) async {
    try {
      final now = DateTime.now();
      
      // Check if fund box exists
      final exists = await fundBoxExists(userId);
      
      if (!exists) {
        // Initialize fund box if it doesn't exist
        return await initializeFundBox(userId);
      }

      // Update the balance
      final updateCount = await database.update(
        'fund_box',
        {
          'balance_usd': newBalance,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (updateCount == 0) {
        throw app_exceptions.DatabaseException('Failed to update fund box for user $userId');
      }

      // Return the updated fund box
      return await getFundBoxByUser(userId);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update fund balance: ${e.toString()}');
    }
  }

  @override
  Future<FundBoxModel> initializeFundBox(int userId) async {
    try {
      final now = DateTime.now();
      
      final id = await database.insert(
        'fund_box',
        {
          'user_id': userId,
          'balance_usd': 0.0,
          'updated_at': now.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return FundBoxModel(
        id: id,
        userId: userId,
        balanceUsd: 0.0,
        updatedAt: now,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to initialize fund box: ${e.toString()}');
    }
  }

  @override
  Future<bool> fundBoxExists(int userId) async {
    try {
      final results = await database.query(
        'fund_box',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return results.isNotEmpty;
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to check fund box existence: ${e.toString()}');
    }
  }
}

