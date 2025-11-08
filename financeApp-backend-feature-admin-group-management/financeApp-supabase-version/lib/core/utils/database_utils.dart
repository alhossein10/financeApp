import 'package:sqflite/sqflite.dart';
import '../../data/db.dart';

/// Utility class for database operations
class DatabaseUtils {
  /// Clear all user data from the database while preserving structure
  /// This deletes all records but keeps tables and schema intact
  static Future<void> clearAllData() async {
    final db = await AppDatabase().database;
    
    await db.transaction((txn) async {
      // Delete all data from tables (in correct order to respect foreign keys)
      await txn.delete('exchange_history');
      await txn.delete('password_reset_tokens');
      await txn.delete('sessions');
      await txn.delete('expenses');
      await txn.delete('incoming');
      await txn.delete('transfers');
      await txn.delete('fund_box');
      await txn.delete('users');
      
      print('✓ All data cleared from database');
      
      // Recreate default user
      final now = DateTime.now().millisecondsSinceEpoch;
      final userId = await txn.insert('users', {
        'username': 'default_user',
        'email': 'default@finance.app',
        'password_hash': '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYzpLaEiUM2', // 'password'
        'role': 0,
        'created_at': now,
        'updated_at': now,
      });
      
      // Recreate fund box for default user
      await txn.insert('fund_box', {
        'id': 1,
        'user_id': userId,
        'balance_usd': 0.0,
        'updated_at': now,
      });
      
      print('✓ Default user and fund box recreated');
    });
  }
  
  /// Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    final db = await AppDatabase().database;
    
    final stats = <String, int>{};
    
    final tables = [
      'users',
      'sessions',
      'expenses',
      'incoming',
      'transfers',
      'fund_box',
      'exchange_history',
      'password_reset_tokens',
    ];
    
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = Sqflite.firstIntValue(result) ?? 0;
    }
    
    return stats;
  }
}
