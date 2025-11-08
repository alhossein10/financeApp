import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../auth/data/models/user_model.dart';
import '../models/user_statistics_model.dart';
import 'profile_local_datasource.dart';

/// Implementation of profile local data source using SQLite
class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final Database database;

  ProfileLocalDataSourceImpl({required this.database});

  @override
  Future<UserStatisticsModel> getUserStatistics(int userId) async {
    try {
      // Get user creation date
      final userResult = await database.query(
        'users',
        columns: ['created_at'],
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (userResult.isEmpty) {
        throw const app_exceptions.DatabaseException('User not found');
      }

      final userCreatedAt = DateTime.fromMillisecondsSinceEpoch(
        userResult.first['created_at'] as int,
      );

      // Get total expenses (sum all currencies - for now just count USD)
      // Note: In future, convert SYP and TRY to USD using exchange rates
      final expenseResult = await database.rawQuery(
        'SELECT COALESCE(SUM(COALESCE(price_usd, 0) + COALESCE(price_syp, 0) + COALESCE(price_try, 0)), 0) as total FROM expenses WHERE user_id = ?',
        [userId],
      );
      final totalExpenses = (expenseResult.first['total'] as num).toDouble();

      // Get total transfers
      final transferResult = await database.rawQuery(
        'SELECT COALESCE(SUM(amount_usd), 0) as total FROM transfers WHERE user_id = ?',
        [userId],
      );
      final totalTransfers = (transferResult.first['total'] as num).toDouble();

      // Get total transaction count
      final transactionCountResult = await database.rawQuery(
        '''
        SELECT 
          (SELECT COUNT(*) FROM expenses WHERE user_id = ?) +
          (SELECT COUNT(*) FROM transfers WHERE user_id = ?) +
          (SELECT COUNT(*) FROM incoming WHERE user_id = ?) as total
        ''',
        [userId, userId, userId],
      );
      final totalTransactions = transactionCountResult.first['total'] as int;

      // Get last activity (most recent transaction date)
      final lastActivityResult = await database.rawQuery(
        '''
        SELECT MAX(transaction_date) as last_activity FROM (
          SELECT expense_date as transaction_date FROM expenses WHERE user_id = ?
          UNION ALL
          SELECT transaction_date FROM transfers WHERE user_id = ?
          UNION ALL
          SELECT transaction_date FROM incoming WHERE user_id = ?
        )
        ''',
        [userId, userId, userId],
      );

      DateTime? lastActivity;
      final lastActivityTimestamp = lastActivityResult.first['last_activity'];
      if (lastActivityTimestamp != null) {
        lastActivity = DateTime.fromMillisecondsSinceEpoch(
          lastActivityTimestamp as int,
        );
      }

      return UserStatisticsModel.fromCalculation(
        totalExpenses: totalExpenses,
        totalTransfers: totalTransfers,
        totalTransactions: totalTransactions,
        userCreatedAt: userCreatedAt,
        lastActivity: lastActivity,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get user statistics: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required int userId,
    String? username,
    String? email,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      if (username != null) {
        // Check if username already exists for another user
        final existingUser = await database.query(
          'users',
          where: 'username = ? AND id != ?',
          whereArgs: [username, userId],
        );

        if (existingUser.isNotEmpty) {
          throw const app_exceptions.DatabaseException('Username already exists');
        }

        updateData['username'] = username;
      }

      if (email != null) {
        // Check if email already exists for another user
        final existingUser = await database.query(
          'users',
          where: 'email = ? AND id != ?',
          whereArgs: [email, userId],
        );

        if (existingUser.isNotEmpty) {
          throw const app_exceptions.DatabaseException('Email already exists');
        }

        updateData['email'] = email;
      }

      // Update user
      final updatedRows = await database.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (updatedRows == 0) {
        throw const app_exceptions.DatabaseException('User not found');
      }

      // Get updated user
      final result = await database.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) {
        throw const app_exceptions.DatabaseException('User not found after update');
      }

      return UserModel.fromMap(result.first);
    } catch (e) {
      if (e is app_exceptions.DatabaseException) {
        rethrow;
      }
      throw app_exceptions.DatabaseException('Failed to update user profile: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfilePicture({
    required int userId,
    required String imagePath,
  }) async {
    try {
      // Verify image file exists
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw const app_exceptions.DatabaseException('Image file does not exist');
      }

      // Update user profile picture
      final updatedRows = await database.update(
        'users',
        {
          'profile_picture_path': imagePath,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (updatedRows == 0) {
        throw const app_exceptions.DatabaseException('User not found');
      }

      // Get updated user
      final result = await database.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) {
        throw const app_exceptions.DatabaseException('User not found after update');
      }

      return UserModel.fromMap(result.first);
    } catch (e) {
      if (e is app_exceptions.DatabaseException) {
        rethrow;
      }
      throw app_exceptions.DatabaseException('Failed to update profile picture: ${e.toString()}');
    }
  }
}
