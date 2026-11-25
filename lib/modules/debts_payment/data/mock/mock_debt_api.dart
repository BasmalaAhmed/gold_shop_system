import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class MockDebtApi {
  final MockNetwork _network;
  Database? _serverDatabase;
  final Set<String> _operationsWithLostResponses = {};
  final Duration _requestDelay;

  MockDebtApi({
    MockNetwork? network,
    this._requestDelay = const Duration(milliseconds: 250),
  }) : _network = network ?? MockNetwork();

  Future<Database> get _database async {
    final existingDatabase = _serverDatabase;
    if (existingDatabase != null) return existingDatabase;

    final directory = await getDatabasesPath();
    final databasePath = p.join(directory, 'mock_server.db');

    final database = await openDatabase(
      databasePath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE server_debts (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            original_amount INTEGER NOT NULL,
            outstanding INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            due_date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE server_operations (
            operation_id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            device_id TEXT NOT NULL,
            device_sequence INTEGER NOT NULL,
            amount INTEGER NOT NULL,
            server_balance_after INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE server_versions (
            customer_id TEXT PRIMARY KEY,
            version INTEGER NOT NULL
          )
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
      CREATE TABLE server_versions (
        customer_id TEXT PRIMARY KEY,
        version INTEGER NOT NULL
      )
    ''');

          await db.execute('''
      INSERT INTO server_versions (customer_id, version)
      SELECT DISTINCT customer_id, 1 FROM server_debts
    ''');
        }

        if (oldVersion < 3) {
          await db.execute('ALTER TABLE server_debts ADD COLUMN due_date TEXT');
        }
      },
    );

    _serverDatabase = database;
    return database;
  }

  void loseNextResponseFor(String operationId) {
    _operationsWithLostResponses.add(operationId);
  }

  Future<List<Map<String, Object?>>> fetchDebts(String customerId) async {
    await _beforeRequest();
    final db = await _database;

    return db.transaction((txn) async {
      await _seedCustomerIfNeeded(txn, customerId);
      final serverVersion = await _serverVersion(txn, customerId);

      final rows = await txn.query(
        'server_debts',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at ASC, id ASC',
      );

      return rows.map((row) {
        return <String, Object?>{
          'id': row['id'],
          'customer_id': row['customer_id'],
          'original_amount': row['original_amount'],
          'server_outstanding': row['outstanding'],
          'created_at': row['created_at'],
          'server_version': serverVersion,
          'due_date': row['due_date'],
        };
      }).toList();
    });
  }

  Future<MockPaymentResult> submitPayment({
    required String operationId,
    required String customerId,
    required String deviceId,
    required int deviceSequence,
    required int amount,
    int? expectedServerVersion,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be greater than zero');
    }

    await _beforeRequest();

    final db = await _database;

    final result = await db.transaction((txn) async {
      await _seedCustomerIfNeeded(txn, customerId);

      final previousOperations = await txn.query(
        'server_operations',
        where: 'operation_id = ?',
        whereArgs: [operationId],
        limit: 1,
      );

      if (previousOperations.isNotEmpty) {
        final previous = previousOperations.single;
        return MockPaymentResult(
          operationId: operationId,
          serverBalanceAfter: previous['server_balance_after'] as int,
          alreadyProcessed: true,
          serverVersion: await _serverVersion(txn, customerId),
        );
      }

      final debts = await txn.query(
        'server_debts',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at ASC, id ASC',
      );

      final serverBalance = debts.fold<int>(
        0,
        (total, debt) => total + (debt['outstanding'] as int),
      );

      final actualServerVersion = await _serverVersion(txn, customerId);
      final other = await _lastOtherDeviceOperation(txn, customerId, deviceId);

      if (expectedServerVersion != null &&
          expectedServerVersion != actualServerVersion) {
        throw MockPaymentConflict(
          requestedAmount: amount,
          serverBalance: serverBalance,
          expectedServerVersion: expectedServerVersion,
          actualServerVersion: actualServerVersion,
          otherDeviceId: other?.deviceId,
          otherAmount: other?.amount,
          otherAt: other?.at,
        );
      }

      if (amount > serverBalance) {
        throw MockPaymentConflict(
          requestedAmount: amount,
          serverBalance: serverBalance,
          otherDeviceId: other?.deviceId,
          otherAmount: other?.amount,
          otherAt: other?.at,
        );
      }

      var remaining = amount;

      for (final debt in debts) {
        if (remaining == 0) break;

        final outstanding = debt['outstanding'] as int;
        if (outstanding == 0) continue;

        final deducted = remaining < outstanding ? remaining : outstanding;

        await txn.update(
          'server_debts',
          {'outstanding': outstanding - deducted},
          where: 'id = ?',
          whereArgs: [debt['id']],
        );

        remaining -= deducted;
      }

      final balanceAfter = serverBalance - amount;

      final serverVersion = await _incrementServerVersion(txn, customerId);

      await txn.insert('server_operations', {
        'operation_id': operationId,
        'customer_id': customerId,
        'device_id': deviceId,
        'device_sequence': deviceSequence,
        'amount': amount,
        'server_balance_after': balanceAfter,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return MockPaymentResult(
        operationId: operationId,
        serverBalanceAfter: balanceAfter,
        alreadyProcessed: false,
        serverVersion: serverVersion,
      );
    });

    if (_operationsWithLostResponses.remove(operationId)) {
      throw MockResponseLost(operationId);
    }

    return result;
  }

  Future<void> simulateOtherDevicePayment({
    required String customerId,
    required int amount,
    String deviceId = 'B2',
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be greater than zero');
    }

    final db = await _database;

    await db.transaction((txn) async {
      await _seedCustomerIfNeeded(txn, customerId);

      final debts = await txn.query(
        'server_debts',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at ASC, id ASC',
      );

      final serverBalance = debts.fold<int>(
        0,
        (total, debt) => total + (debt['outstanding'] as int),
      );

      if (amount > serverBalance) {
        throw MockPaymentConflict(
          requestedAmount: amount,
          serverBalance: serverBalance,
        );
      }

      var remaining = amount;

      for (final debt in debts) {
        if (remaining == 0) break;

        final outstanding = debt['outstanding'] as int;
        if (outstanding == 0) continue;

        final deducted = remaining < outstanding ? remaining : outstanding;

        await txn.update(
          'server_debts',
          {'outstanding': outstanding - deducted},
          where: 'id = ?',
          whereArgs: [debt['id']],
        );

        remaining -= deducted;
      }
      await txn.insert('server_operations', {
        'operation_id': 'other-${DateTime.now().microsecondsSinceEpoch}',
        'customer_id': customerId,
        'device_id': deviceId,
        'device_sequence': 0,
        'amount': amount,
        'server_balance_after': serverBalance - amount,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _incrementServerVersion(txn, customerId);
    });
  }

  Future<void> _seedCustomerIfNeeded(Transaction txn, String customerId) async {
    final existingDebts = await txn.query(
      'server_debts',
      columns: ['id'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
      limit: 1,
    );

    if (existingDebts.isEmpty) {
      final now = DateTime.now().toUtc();

      await txn.insert('server_debts', {
        'id': '$customerId-debt-001',
        'customer_id': customerId,
        'original_amount': 100000,
        'outstanding': 100000,
        'created_at': now.subtract(const Duration(days: 60)).toIso8601String(),
        'due_date': now.subtract(const Duration(days: 12)).toIso8601String(),
      });

      await txn.insert('server_debts', {
        'id': '$customerId-debt-002',
        'customer_id': customerId,
        'original_amount': 50000,
        'outstanding': 50000,
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
        'due_date': now.add(const Duration(days: 12)).toIso8601String(),
      });
    }

    final versions = await txn.query(
      'server_versions',
      columns: ['customer_id'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
      limit: 1,
    );

    if (versions.isEmpty) {
      await txn.insert('server_versions', {
        'customer_id': customerId,
        'version': 1,
      });
    }
  }

  Future<({String deviceId, int amount, DateTime at})?>
  _lastOtherDeviceOperation(
    Transaction txn,
    String customerId,
    String deviceId,
  ) async {
    final rows = await txn.query(
      'server_operations',
      where: 'customer_id = ? AND device_id != ?',
      whereArgs: [customerId, deviceId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.single;
    return (
      deviceId: row['device_id'] as String,
      amount: row['amount'] as int,
      at: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<void> close() async {
    final database = _serverDatabase;
    if (database == null) return;

    await database.close();
    _serverDatabase = null;
  }

  Future<int> countServerOperations(String operationId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM server_operations WHERE operation_id = ?',
      [operationId],
    );
    return rows.single['total'] as int;
  }

  Future<void> _beforeRequest() async {
    await Future<void>.delayed(_requestDelay);

    if (!_network.isOnline) {
      throw const MockNetworkUnavailable();
    }
  }

  Future<int> _serverVersion(Transaction txn, String customerId) async {
    final rows = await txn.query(
      'server_versions',
      columns: ['version'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
      limit: 1,
    );

    return rows.single['version'] as int;
  }

  Future<int> _incrementServerVersion(
    Transaction txn,
    String customerId,
  ) async {
    final nextVersion = await _serverVersion(txn, customerId) + 1;

    await txn.update(
      'server_versions',
      {'version': nextVersion},
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );

    return nextVersion;
  }
}

class MockPaymentResult {
  const MockPaymentResult({
    required this.operationId,
    required this.serverBalanceAfter,
    required this.alreadyProcessed,
    required this.serverVersion,
  });

  final String operationId;
  final int serverBalanceAfter;
  final bool alreadyProcessed;
  final int serverVersion;
}

class MockPaymentConflict implements Exception {
  const MockPaymentConflict({
    required this.requestedAmount,
    required this.serverBalance,
    this.expectedServerVersion,
    this.actualServerVersion,
    this.otherDeviceId,
    this.otherAmount,
    this.otherAt,
  });

  final int requestedAmount;
  final int serverBalance;
  final int? expectedServerVersion;
  final int? actualServerVersion;
  final String? otherDeviceId;
  final int? otherAmount;
  final DateTime? otherAt;

  @override
  String toString() {
    final versionDetails =
        expectedServerVersion != null && actualServerVersion != null
        ? 'Server version changed: expected $expectedServerVersion, '
              'current $actualServerVersion. '
        : '';

    return '$versionDetails'
        'Requested $requestedAmount cents; '
        'server balance is $serverBalance cents.';
  }
}

class MockResponseLost implements Exception {
  const MockResponseLost(this.operationId);

  final String operationId;

  @override
  String toString() => 'The response for operation $operationId was lost.';
}
