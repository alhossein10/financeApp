import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/exchange_record.dart';
import '../models/expense.dart';
import '../models/fund_box.dart';
import '../models/incoming.dart';
import '../models/transfer.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal() {
    _initDatabase();
  }

  static const int _dbVersion = 6;
  static const String _dbName = 'finance_app.db';

  Database? _db;

  void _initDatabase() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // Create users table
        await db.execute('''
CREATE TABLE users(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role INTEGER NOT NULL DEFAULT 0,
  profile_picture_path TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  last_login INTEGER
);
''');

        // Create sessions table
        await db.execute('''
CREATE TABLE sessions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  token TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  last_activity INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

        // Create password_reset_tokens table
        await db.execute('''
CREATE TABLE password_reset_tokens(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  token TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  used INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

        await db.execute('''
CREATE TABLE fund_box(
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL DEFAULT 1,
  balance_usd REAL NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

        await db.execute('''
CREATE TABLE transfers(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL DEFAULT 1,
  recipient_name TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  converted_amount_usd REAL,
  amount_syp_at_exchange REAL,
  manual_usd_to_syp_rate REAL,
  transaction_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

        await db.execute('''
CREATE TABLE incoming(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL DEFAULT 1,
  description TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  transaction_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

        await db.execute('''
CREATE TABLE expenses(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL DEFAULT 1,
  description TEXT NOT NULL,
  price_usd REAL,
  price_syp REAL,
  price_try REAL,
  invoice_status INTEGER NOT NULL,
  invoice_file_path TEXT,
  invoice_cloud_file_id TEXT,
  sync_status INTEGER NOT NULL DEFAULT 0,
  synced_at INTEGER,
  sync_retry_count INTEGER NOT NULL DEFAULT 0,
  sync_error_message TEXT,
  expense_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

        await db.execute('''
CREATE TABLE exchange_history(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transfer_id INTEGER NOT NULL,
  converted_amount_usd REAL NOT NULL,
  amount_syp_at_exchange REAL,
  manual_usd_to_syp_rate REAL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (transfer_id) REFERENCES transfers(id) ON DELETE CASCADE
);
''');

        // Create indexes for performance
        await db.execute('CREATE INDEX idx_fund_box_user_id ON fund_box(user_id);');
        await db.execute('CREATE INDEX idx_transfers_user_id ON transfers(user_id);');
        await db.execute('CREATE INDEX idx_incoming_user_id ON incoming(user_id);');
        await db.execute('CREATE INDEX idx_expenses_user_id ON expenses(user_id);');
        await db.execute('CREATE INDEX idx_expenses_sync_status ON expenses(sync_status);');
        await db.execute('CREATE INDEX idx_expenses_synced_at ON expenses(synced_at);');
        await db.execute('CREATE INDEX idx_expenses_user_id_sync_status ON expenses(user_id, sync_status);');
        await db.execute('CREATE INDEX idx_sessions_user_id ON sessions(user_id);');
        await db.execute('CREATE INDEX idx_sessions_token ON sessions(token);');

        // Create default user
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.insert('users', {
          'username': 'default_user',
          'email': 'default@finance.app',
          'password_hash': '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYzpLaEiUM2', // 'password'
          'created_at': now,
          'updated_at': now,
        });

        // Seed single fund_box row for default user
        await db.insert('fund_box', {
          'id': 1,
          'user_id': 1,
          'balance_usd': 0.0,
          'updated_at': now,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add converted_amount_usd column to transfers table
          await db.execute('ALTER TABLE transfers ADD COLUMN converted_amount_usd REAL');
          // Add expense_date column to expenses table
          await db.execute('ALTER TABLE expenses ADD COLUMN expense_date INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          // Add transaction_date column to transfers table
          await db.execute('ALTER TABLE transfers ADD COLUMN transaction_date INTEGER NOT NULL DEFAULT 0');
          // Create incoming table
          await db.execute('''
CREATE TABLE incoming(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  description TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  transaction_date INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER
);
''');
        }
        if (oldVersion < 4) {
          // Create exchange_history table
          await db.execute('''
CREATE TABLE exchange_history(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transfer_id INTEGER NOT NULL,
  converted_amount_usd REAL NOT NULL,
  amount_syp_at_exchange REAL,
  manual_usd_to_syp_rate REAL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (transfer_id) REFERENCES transfers(id) ON DELETE CASCADE
);
''');
        }
        if (oldVersion < 5) {
          // Migration to version 5: Multi-user support
          final now = DateTime.now().millisecondsSinceEpoch;
          
          // Create users table
          await db.execute('''
CREATE TABLE users(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  profile_picture_path TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  last_login INTEGER
);
''');

          // Create sessions table
          await db.execute('''
CREATE TABLE sessions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  token TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  last_activity INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

          // Create password_reset_tokens table
          await db.execute('''
CREATE TABLE password_reset_tokens(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  token TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  used INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

          // Create default user
          await db.insert('users', {
            'username': 'default_user',
            'email': 'default@finance.app',
            'password_hash': '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYzpLaEiUM2', // 'password'
            'created_at': now,
            'updated_at': now,
          });

          // Add user_id column to existing tables and associate with default user
          await db.execute('ALTER TABLE fund_box ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1 REFERENCES users(id) ON DELETE CASCADE;');
          await db.execute('ALTER TABLE transfers ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1 REFERENCES users(id) ON DELETE CASCADE;');
          await db.execute('ALTER TABLE incoming ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1 REFERENCES users(id) ON DELETE CASCADE;');
          await db.execute('ALTER TABLE expenses ADD COLUMN user_id INTEGER NOT NULL DEFAULT 1 REFERENCES users(id) ON DELETE CASCADE;');

          // Create indexes for performance
          await db.execute('CREATE INDEX idx_fund_box_user_id ON fund_box(user_id);');
          await db.execute('CREATE INDEX idx_transfers_user_id ON transfers(user_id);');
          await db.execute('CREATE INDEX idx_incoming_user_id ON incoming(user_id);');
          await db.execute('CREATE INDEX idx_expenses_user_id ON expenses(user_id);');
          await db.execute('CREATE INDEX idx_sessions_user_id ON sessions(user_id);');
          await db.execute('CREATE INDEX idx_sessions_token ON sessions(token);');
        }
        if (oldVersion < 6) {
          // Migration to version 6: Add sync support and user roles
          
          // Add sync-related columns to expenses table
          await db.execute('ALTER TABLE expenses ADD COLUMN invoice_cloud_file_id TEXT;');
          await db.execute('ALTER TABLE expenses ADD COLUMN sync_status INTEGER NOT NULL DEFAULT 0;');
          await db.execute('ALTER TABLE expenses ADD COLUMN synced_at INTEGER;');
          await db.execute('ALTER TABLE expenses ADD COLUMN sync_retry_count INTEGER NOT NULL DEFAULT 0;');
          await db.execute('ALTER TABLE expenses ADD COLUMN sync_error_message TEXT;');
          
          // Add role column to users table
          await db.execute('ALTER TABLE users ADD COLUMN role INTEGER NOT NULL DEFAULT 0;');
          
          // Create indexes for sync queries
          await db.execute('CREATE INDEX idx_expenses_sync_status ON expenses(sync_status);');
          await db.execute('CREATE INDEX idx_expenses_synced_at ON expenses(synced_at);');
          await db.execute('CREATE INDEX idx_expenses_user_id_sync_status ON expenses(user_id, sync_status);');
        }
      },
    );
  }

  // Fund box
  Future<FundBox> getFundBox() async {
    final db = await database;
    final rows = await db.query('fund_box', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      final fb = FundBox(id: 1, balanceUsd: 0.0, updatedAt: DateTime.now());
      await db.insert('fund_box', fb.toMap());
      return fb;
    }
    return FundBox.fromMap(rows.first);
  }

  Future<void> setFundBalanceUsd(double newBalance) async {
    final db = await database;
    await db.update(
      'fund_box',
      {
        'balance_usd': newBalance,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Transfer flow: deduct from fund and insert record atomically
  Future<TransferRecord> createTransfer({
    required String recipientName,
    required double amountUsd,
    double? convertedAmountUsd,
    double? amountSypAtExchange,
    double? manualUsdToSypRate,
    DateTime? transactionDate,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      final rows = await txn.query('fund_box', where: 'id = 1');
      final current = rows.isNotEmpty
          ? FundBox.fromMap(rows.first)
          : FundBox(id: 1, balanceUsd: 0.0, updatedAt: DateTime.now());
      final newBalance = current.balanceUsd - amountUsd;
      if (newBalance < 0) {
        throw StateError('Insufficient fund balance');
      }
      await txn.update(
        'fund_box',
        {
          'balance_usd': newBalance,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = 1',
      );

      final now = DateTime.now();
      final id = await txn.insert('transfers', {
        'recipient_name': recipientName,
        'amount_usd': amountUsd,
        'converted_amount_usd': convertedAmountUsd,
        'amount_syp_at_exchange': amountSypAtExchange,
        'manual_usd_to_syp_rate': manualUsdToSypRate,
        'transaction_date': (transactionDate ?? now).millisecondsSinceEpoch,
        'created_at': now.millisecondsSinceEpoch,
      });

      final row = await txn.query('transfers', where: 'id = ?', whereArgs: [id]);
      return TransferRecord.fromMap(row.first);
    });
  }

  Future<List<TransferRecord>> listTransfers() async {
    final db = await database;
    final rows = await db.query('transfers', orderBy: 'created_at DESC');
    return rows.map((e) => TransferRecord.fromMap(e)).toList();
  }

  Future<void> updateTransfer(TransferRecord record) async {
    final db = await database;
    await db.update(
      'transfers',
      record
          .copyWith(updatedAt: DateTime.now())
          .toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteTransfer(int id, {bool refund = false}) async {
    final db = await database;
    await db.transaction((txn) async {
      if (refund) {
        final row = await txn.query('transfers', where: 'id = ?', whereArgs: [id]);
        if (row.isNotEmpty) {
          final tr = TransferRecord.fromMap(row.first);
          final fund = FundBox.fromMap((await txn.query('fund_box', where: 'id = 1')).first);
          await txn.update(
            'fund_box',
            {
              'balance_usd': fund.balanceUsd + tr.amountUsd,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = 1',
          );
        }
      }
      await txn.delete('transfers', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Expenses
  Future<int> createExpense(ExpenseRecord record) async {
    final db = await database;
    return db.insert('expenses', record.toMap());
  }

  Future<void> updateExpense(ExpenseRecord record) async {
    final db = await database;
    await db.update(
      'expenses',
      record.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExpenseRecord>> listExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'created_at DESC');
    return rows.map((e) => ExpenseRecord.fromMap(e)).toList();
  }

  // Incoming transactions
  Future<IncomingRecord> createIncoming({
    required String description,
    required double amountUsd,
    DateTime? transactionDate,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Add to fund box
      final rows = await txn.query('fund_box', where: 'id = 1');
      final current = rows.isNotEmpty
          ? FundBox.fromMap(rows.first)
          : FundBox(id: 1, balanceUsd: 0.0, updatedAt: DateTime.now());
      final newBalance = current.balanceUsd + amountUsd;
      
      await txn.update(
        'fund_box',
        {
          'balance_usd': newBalance,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = 1',
      );

      final now = DateTime.now();
      final id = await txn.insert('incoming', {
        'description': description,
        'amount_usd': amountUsd,
        'transaction_date': (transactionDate ?? now).millisecondsSinceEpoch,
        'created_at': now.millisecondsSinceEpoch,
      });

      final row = await txn.query('incoming', where: 'id = ?', whereArgs: [id]);
      return IncomingRecord.fromMap(row.first);
    });
  }

  Future<List<IncomingRecord>> listIncoming() async {
    final db = await database;
    final rows = await db.query('incoming', orderBy: 'transaction_date DESC');
    return rows.map((e) => IncomingRecord.fromMap(e)).toList();
  }

  Future<void> updateIncoming(IncomingRecord record) async {
    final db = await database;
    await db.update(
      'incoming',
      record.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteIncoming(int id, {bool refund = false}) async {
    final db = await database;
    await db.transaction((txn) async {
      if (refund) {
        final row = await txn.query('incoming', where: 'id = ?', whereArgs: [id]);
        if (row.isNotEmpty) {
          final inc = IncomingRecord.fromMap(row.first);
          final fund = FundBox.fromMap((await txn.query('fund_box', where: 'id = 1')).first);
          await txn.update(
            'fund_box',
            {
              'balance_usd': fund.balanceUsd - inc.amountUsd,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = 1',
          );
        }
      }
      await txn.delete('incoming', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Exchange History
  Future<int> createExchangeRecord(ExchangeRecord record) async {
    final db = await database;
    return db.insert('exchange_history', record.toMap());
  }

  Future<List<ExchangeRecord>> listExchangesByTransfer(int transferId) async {
    final db = await database;
    final rows = await db.query(
      'exchange_history',
      where: 'transfer_id = ?',
      whereArgs: [transferId],
      orderBy: 'created_at DESC',
    );
    return rows.map((e) => ExchangeRecord.fromMap(e)).toList();
  }

  Future<void> deleteExchangeRecord(int id) async {
    final db = await database;
    await db.delete('exchange_history', where: 'id = ?', whereArgs: [id]);
  }
}


