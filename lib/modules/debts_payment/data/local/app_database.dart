import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) return existingDatabase;

    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, 'debts_payment.db');

    final database = await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE debts (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            original_amount INTEGER NOT NULL,
            server_outstanding INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            due_date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE payments (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            amount INTEGER NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE payment_allocations (
            payment_id TEXT NOT NULL,
            debt_id TEXT NOT NULL,
            amount INTEGER NOT NULL,
            PRIMARY KEY (payment_id, debt_id),
            FOREIGN KEY (payment_id) REFERENCES payments(id),
            FOREIGN KEY (debt_id) REFERENCES debts(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE sync_queue (
          operation_id TEXT PRIMARY KEY,
          expected_server_version INTEGER,
          device_id TEXT NOT NULL,
          device_sequence INTEGER NOT NULL,
          payment_id TEXT NOT NULL UNIQUE,
          status TEXT NOT NULL,
          last_error TEXT,
          created_at TEXT NOT NULL,
          outcome_unknown INTEGER NOT NULL DEFAULT 0,
          already_processed INTEGER NOT NULL DEFAULT 0,
          confirmed_at TEXT,
          conflict_server_balance INTEGER,
          conflict_other_device TEXT,
          conflict_other_amount INTEGER,
          conflict_other_at TEXT,
          resolved_at TEXT,
          replaced_by_sequence INTEGER,
          replaces_sequence INTEGER,
    FOREIGN KEY (payment_id) REFERENCES payments(id)
  )
        ''');

        await db.execute('''
          CREATE TABLE app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE sync_queue ADD COLUMN expected_server_version INTEGER',
          );
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE debts ADD COLUMN due_date TEXT');
        }
        if (oldVersion < 4) {
          for (final column in const [
            'outcome_unknown INTEGER NOT NULL DEFAULT 0',
            'already_processed INTEGER NOT NULL DEFAULT 0',
            'confirmed_at TEXT',
            'conflict_server_balance INTEGER',
            'conflict_other_device TEXT',
            'conflict_other_amount INTEGER',
            'conflict_other_at TEXT',
          ]) {
            await db.execute('ALTER TABLE sync_queue ADD COLUMN $column');
          }
        }
        if (oldVersion < 5) {
          for (final column in const [
            'resolved_at TEXT',
            'replaced_by_sequence INTEGER',
            'replaces_sequence INTEGER',
          ]) {
            await db.execute('ALTER TABLE sync_queue ADD COLUMN $column');
          }
        }
      },
    );

    _database = database;
    return database;
  }

  Future<void> replaceDebts(
    String customerId,
    List<Map<String, Object?>> debts, {
    int? serverVersion,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'debts',
        where: 'customer_id = ?',
        whereArgs: [customerId],
      );

      for (final debt in debts) {
        await txn.insert('debts', debt);
      }

      if (serverVersion != null) {
        await txn.insert('app_metadata', {
          'key': 'server_version:$customerId',
          'value': serverVersion.toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> close() async {
    final openDatabase = _database;
    if (openDatabase == null) return;

    await openDatabase.close();
    _database = null;
  }
}
