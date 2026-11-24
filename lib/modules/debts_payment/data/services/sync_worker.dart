import 'package:gold_shop_app/modules/debts_payment/data/local/app_database.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_debt_api.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:sqflite/sqflite.dart';

enum _Step { ok, conflict, stop }

class SyncWorker {
  SyncWorker({required this._database, required this._api});

  final AppDatabase _database;
  final MockDebtApi _api;

  bool _isSyncing = false;

  Future<void> recoverInterrupted() async {
    final db = await _database.database;

    await db.update(
      'sync_queue',
      {
        'status': 'pending',
        'outcome_unknown': 1,
        'last_error': 'Retry after app restart',
      },
      where: 'status = ?',
      whereArgs: ['syncing'],
    );
  }

  Future<void> syncPendingPayments() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await recoverInterrupted();

      final db = await _database.database;

      final operations = await db.rawQuery('''
        SELECT q.*, p.customer_id AS customer_id
        FROM sync_queue q
        JOIN payments p ON p.id = q.payment_id
        WHERE q.status = 'pending'
        ORDER BY q.device_id ASC, q.device_sequence ASC
      ''');

      final blockedCustomers = <String>{};

      for (final operation in operations) {
        final customerId = operation['customer_id'] as String;
        if (blockedCustomers.contains(customerId)) continue;

        final step = await _syncOne(operation);

        if (step == _Step.stop) break;
        if (step == _Step.conflict) blockedCustomers.add(customerId);
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<_Step> _syncOne(Map<String, Object?> operation) async {
    final db = await _database.database;
    final operationId = operation['operation_id'] as String;
    final paymentId = operation['payment_id'] as String;

    await db.update(
      'sync_queue',
      {'status': 'syncing', 'last_error': null},
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );

    try {
      final payments = await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: [paymentId],
        limit: 1,
      );

      if (payments.isEmpty) {
        await _markConflict(
          operationId: operationId,
          paymentId: paymentId,
          reason: 'Payment record is missing locally.',
        );
        return _Step.conflict;
      }

      final payment = payments.single;

      final result = await _api.submitPayment(
        operationId: operationId,
        customerId: payment['customer_id'] as String,
        deviceId: operation['device_id'] as String,
        deviceSequence: operation['device_sequence'] as int,
        amount: payment['amount'] as int,
        expectedServerVersion: operation['expected_server_version'] as int?,
      );

      final now = DateTime.now().toUtc().toIso8601String();

      await db.transaction((txn) async {
        await txn.update(
          'sync_queue',
          {
            'status': 'confirmed',
            'last_error': null,
            'outcome_unknown': 0,
            'already_processed': result.alreadyProcessed ? 1 : 0,
            'confirmed_at': now,
          },
          where: 'operation_id = ?',
          whereArgs: [operationId],
        );

        await txn.update(
          'payments',
          {'status': 'confirmed'},
          where: 'id = ?',
          whereArgs: [paymentId],
        );

        await txn.insert('app_metadata', {
          'key': 'server_version:${payment['customer_id']}',
          'value': result.serverVersion.toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });

      return _Step.ok;
    } on MockResponseLost {
      await db.update(
        'sync_queue',
        {
          'status': 'pending',
          'outcome_unknown': 1,
          'last_error':
              'Response lost; safe to retry with the same operation ID.',
        },
        where: 'operation_id = ?',
        whereArgs: [operationId],
      );
      return _Step.stop;
    } on MockNetworkUnavailable catch (error) {
      await db.update(
        'sync_queue',
        {'status': 'pending', 'last_error': error.toString()},
        where: 'operation_id = ?',
        whereArgs: [operationId],
      );
      return _Step.stop;
    } on MockPaymentConflict catch (error) {
      await _markConflict(
        operationId: operationId,
        paymentId: paymentId,
        reason: error.toString(),
        serverBalance: error.serverBalance,
        otherDevice: error.otherDeviceId,
        otherAmount: error.otherAmount,
        otherAt: error.otherAt,
      );
      return _Step.conflict;
    } catch (error) {
      await db.update(
        'sync_queue',
        {
          'status': 'pending',
          'outcome_unknown': 1,
          'last_error': error.toString(),
        },
        where: 'operation_id = ?',
        whereArgs: [operationId],
      );
      return _Step.stop;
    }
  }

  Future<void> _markConflict({
    required String operationId,
    required String paymentId,
    required String reason,
    int? serverBalance,
    String? otherDevice,
    int? otherAmount,
    DateTime? otherAt,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'sync_queue',
        {
          'status': 'conflict',
          'last_error': reason,
          'outcome_unknown': 0,
          'conflict_server_balance': serverBalance,
          'conflict_other_device': otherDevice,
          'conflict_other_amount': otherAmount,
          'conflict_other_at': otherAt?.toUtc().toIso8601String(),
        },
        where: 'operation_id = ?',
        whereArgs: [operationId],
      );

      await txn.update(
        'payments',
        {'status': 'conflict'},
        where: 'id = ?',
        whereArgs: [paymentId],
      );
    });
  }
}
