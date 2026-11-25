import 'package:gold_shop_app/modules/debts_payment/data/local/app_database.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_record.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/queue_summary.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class PaymentRepo {
  PaymentRepo({required this._database, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  Future<String> recordPayment({
    required String customerId,
    required int amount,
    required String deviceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be greater than zero');
    }

    if (deviceId.trim().isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'Must not be empty');
    }

    final db = await _database.database;

    return db.transaction(
      (txn) => _recordPaymentInTxn(
        txn,
        customerId: customerId,
        amount: amount,
        deviceId: deviceId,
      ),
    );
  }

  Future<bool> refreshDebtsIfIdle(
    String customerId,
    List<Map<String, Object?>> serverDebts,
  ) async {
    final db = await _database.database;

    return db.transaction((txn) async {
      final rows = await txn.rawQuery(
        '''
      SELECT COUNT(*) AS total
      FROM sync_queue q
      JOIN payments p ON p.id = q.payment_id
      WHERE p.customer_id = ?
        AND q.status NOT IN ('confirmed', 'cancelled', 'superseded')
      ''',
        [customerId],
      );

      if ((rows.single['total'] as int) > 0) return false;

      await _refreshDebtCache(txn, customerId, serverDebts);
      return true;
    });
  }

  Future<String> _recordPaymentInTxn(
    Transaction txn, {
    required String customerId,
    required int amount,
    required String deviceId,
    int? replacesSequence,
  }) async {
    final debtRows = await txn.query(
      'debts',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at ASC, id ASC',
    );

    final debts = debtRows.map(_debtFromRow).toList();
    final allocations = <({DebtRecord debt, int amount})>[];
    var remainingToAllocate = amount;

    for (final debt in debts) {
      final locallyCollected = await _locallyCollectedForDebt(txn, debt.id);
      final localOutstanding = debt.serverOutstanding - locallyCollected;

      if (localOutstanding <= 0) continue;

      final allocated = remainingToAllocate < localOutstanding
          ? remainingToAllocate
          : localOutstanding;

      allocations.add((debt: debt, amount: allocated));
      remainingToAllocate -= allocated;

      if (remainingToAllocate == 0) break;
    }

    if (remainingToAllocate > 0) {
      throw StateError('Payment exceeds the locally available balance.');
    }

    final versionRows = await txn.query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['server_version:$customerId'],
      limit: 1,
    );

    final baseServerVersion = versionRows.isEmpty
        ? null
        : int.tryParse(versionRows.single['value'] as String);

    final pendingRows = await txn.rawQuery(
      '''
  SELECT COUNT(*) AS total
  FROM sync_queue q
  JOIN payments p ON p.id = q.payment_id
  WHERE p.customer_id = ?
    AND q.status IN ('pending', 'syncing')
  ''',
      [customerId],
    );

    final earlierPendingCount = pendingRows.single['total'] as int;
    final expectedServerVersion = baseServerVersion == null
        ? null
        : baseServerVersion + earlierPendingCount;

    final now = DateTime.now().toUtc().toIso8601String();
    final paymentId = _uuid.v4();
    final operationId = _uuid.v4();
    final deviceSequence = await _nextDeviceSequence(txn, deviceId);

    await txn.insert('payments', {
      'id': paymentId,
      'customer_id': customerId,
      'amount': amount,
      'status': 'local',
      'created_at': now,
    });

    for (final allocation in allocations) {
      await txn.insert('payment_allocations', {
        'payment_id': paymentId,
        'debt_id': allocation.debt.id,
        'amount': allocation.amount,
      });
    }

    await txn.insert('sync_queue', {
      'operation_id': operationId,
      'device_id': deviceId,
      'device_sequence': deviceSequence,
      'payment_id': paymentId,
      'status': 'pending',
      'last_error': null,
      'created_at': now,
      'expected_server_version': expectedServerVersion,
      'replaces_sequence': replacesSequence,
    });

    return paymentId;
  }

  Future<int> _locallyCollectedForDebt(Transaction txn, String debtId) async {
    final rows = await txn.rawQuery(
      '''
      SELECT COALESCE(SUM(pa.amount), 0) AS total
      FROM payment_allocations pa
      JOIN payments p ON p.id = pa.payment_id
      WHERE pa.debt_id = ?
        AND p.status IN ('local', 'confirmed', 'conflict')
      ''',
      [debtId],
    );

    return (rows.first['total'] as int?) ?? 0;
  }

  Future<int> _nextDeviceSequence(Transaction txn, String deviceId) async {
    final rows = await txn.rawQuery(
      '''
      SELECT MAX(device_sequence) AS last_sequence
      FROM sync_queue
      WHERE device_id = ?
      ''',
      [deviceId],
    );

    final lastSequence = rows.first['last_sequence'] as int?;
    return (lastSequence ?? 0) + 1;
  }

  DebtRecord _debtFromRow(Map<String, Object?> row) {
    return DebtRecord(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      serverOutstanding: row['server_outstanding'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<void> cacheDebts(String customerId, List<Map<String, Object?>> debts) {
    final serverVersion = debts.isEmpty
        ? null
        : debts.first['server_version'] as int?;

    final localDebts = debts.map((debt) {
      final localDebt = Map<String, Object?>.from(debt);
      localDebt.remove('server_version');
      return localDebt;
    }).toList();

    return _database.replaceDebts(
      customerId,
      localDebts,
      serverVersion: serverVersion,
    );
  }

  Future<List<DebtBalance>> getDebtBalances(String customerId) async {
    final db = await _database.database;

    final rows = await db.rawQuery(
      '''
    SELECT
      d.id AS debt_id,
      d.server_outstanding AS server_outstanding,
      d.created_at AS created_at,
      d.due_date AS due_date,
      d.server_outstanding - COALESCE(
        SUM(
          CASE WHEN p.id IS NOT NULL THEN pa.amount ELSE 0 END
        ),
        0
      ) AS local_outstanding,
      COALESCE(SUM(CASE WHEN p.status = 'confirmed' THEN pa.amount ELSE 0 END), 0) AS confirmed_amount,
      COALESCE(SUM(CASE WHEN p.status = 'local' THEN pa.amount ELSE 0 END), 0) AS pending_amount,
      COALESCE(SUM(CASE WHEN p.status = 'conflict' THEN pa.amount ELSE 0 END), 0) AS conflict_amount
    FROM debts d
    LEFT JOIN payment_allocations pa
      ON pa.debt_id = d.id
    LEFT JOIN payments p
      ON p.id = pa.payment_id
      AND p.status IN ('local', 'confirmed', 'conflict')
    WHERE d.customer_id = ?
    GROUP BY
  d.id,
  d.server_outstanding,
  d.created_at,
  d.due_date
    ORDER BY d.created_at ASC, d.id ASC
    ''',
      [customerId],
    );

    return rows.map((row) {
      final dueDateValue = row['due_date'] as String?;

      return DebtBalance(
        debtId: row['debt_id'] as String,
        serverOutstanding: row['server_outstanding'] as int,
        localOutstanding: row['local_outstanding'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
        dueDate: dueDateValue == null ? null : DateTime.parse(dueDateValue),
        confirmedAmount: row['confirmed_amount'] as int,
        pendingAmount: row['pending_amount'] as int,
        conflictAmount: row['conflict_amount'] as int,
      );
    }).toList();
  }

  Future<String> getOrCreateDeviceId() async {
    final db = await _database.database;

    return db.transaction((txn) async {
      final rows = await txn.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['device_id'],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        return rows.single['value'] as String;
      }

      final deviceId = _uuid.v4();

      await txn.insert('app_metadata', {'key': 'device_id', 'value': deviceId});

      return deviceId;
    });
  }

  Future<List<SyncOperation>> getSyncOperations() async {
    final db = await _database.database;

    final rows = await db.rawQuery('''
    SELECT
      q.operation_id,
      q.payment_id,
      q.device_id,
      q.device_sequence,
      q.status AS sync_status,
      q.last_error,
      q.created_at,
      q.outcome_unknown,
      q.already_processed,
      q.confirmed_at,
      q.conflict_server_balance,
      q.conflict_other_device,
      q.conflict_other_amount,
      q.conflict_other_at,
      q.resolved_at,
      q.replaced_by_sequence,
      q.replaces_sequence,
      p.customer_id,
      p.amount,
      p.status AS payment_status
    FROM sync_queue q
    JOIN payments p ON p.id = q.payment_id
    ORDER BY q.device_id ASC, q.device_sequence ASC
  ''');

    return rows.map(SyncOperation.fromRow).toList();
  }

  Future<QueueSummary> getQueueSummary() async {
    final db = await _database.database;

    final row = (await db.rawQuery('''
    SELECT
      COALESCE(SUM(CASE WHEN status IN ('pending','syncing') THEN 1 ELSE 0 END), 0) AS open_count,
      COALESCE(SUM(CASE WHEN status = 'conflict' THEN 1 ELSE 0 END), 0) AS conflict_count,
      MAX(confirmed_at) AS last_synced_at
    FROM sync_queue
  ''')).single;

    final last = row['last_synced_at'] as String?;

    return QueueSummary(
      open: row['open_count'] as int,
      conflicts: row['conflict_count'] as int,
      lastSyncedAt: last == null ? null : DateTime.parse(last),
    );
  }

  Future<SyncOperation> getOperationForPayment(String paymentId) async {
    final operations = await getSyncOperations();
    return operations.firstWhere((o) => o.paymentId == paymentId);
  }

  Future<void> cancelConflictedPayment({
    required String operationId,
    required List<Map<String, Object?>> serverDebts,
  }) async {
    final db = await _database.database;

    await db.transaction((txn) async {
      final op = await _requireConflictOp(txn, operationId);
      await _ensureSafeToRefresh(txn, op.customerId);

      await _closeConflictOp(
        txn,
        operationId: operationId,
        paymentId: op.paymentId,
        status: 'cancelled',
      );
      await _refreshDebtCache(txn, op.customerId, serverDebts);
    });
  }

  Future<String> replaceConflictedPayment({
    required String operationId,
    required List<Map<String, Object?>> serverDebts,
  }) async {
    final db = await _database.database;

    return db.transaction((txn) async {
      final op = await _requireConflictOp(txn, operationId);
      await _ensureSafeToRefresh(txn, op.customerId);

      final oldPayment = await txn.query(
        'payments',
        columns: ['amount'],
        where: 'id = ?',
        whereArgs: [op.paymentId],
        limit: 1,
      );
      final oldAmount = oldPayment.single['amount'] as int;

      final nextSequence = await _nextDeviceSequence(txn, op.deviceId);

      await _closeConflictOp(
        txn,
        operationId: operationId,
        paymentId: op.paymentId,
        status: 'superseded',
        replacedBySequence: nextSequence,
      );
      await _refreshDebtCache(txn, op.customerId, serverDebts);

      final available = await _availableForCustomer(txn, op.customerId);
      final newAmount = available < oldAmount ? available : oldAmount;

      if (newAmount <= 0) {
        throw const ConflictResolutionBlocked(
          'لا يوجد رصيد متبقٍ على الخادم لهذا العميل. يمكنك إلغاء التحصيل.',
        );
      }

      return _recordPaymentInTxn(
        txn,
        customerId: op.customerId,
        amount: newAmount,
        deviceId: op.deviceId,
        replacesSequence: op.sequence,
      );
    });
  }

  Future<_ConflictOpInfo> _requireConflictOp(
    Transaction txn,
    String operationId,
  ) async {
    final rows = await txn.rawQuery(
      '''
      SELECT q.payment_id, q.device_id, q.device_sequence, q.status,
             p.customer_id
      FROM sync_queue q
      JOIN payments p ON p.id = q.payment_id
      WHERE q.operation_id = ?
      ''',
      [operationId],
    );

    if (rows.isEmpty || rows.single['status'] != 'conflict') {
      throw const ConflictResolutionBlocked(
        'هذه العملية لم تعد في حالة تعارض.',
      );
    }

    final row = rows.single;
    return _ConflictOpInfo(
      paymentId: row['payment_id'] as String,
      customerId: row['customer_id'] as String,
      deviceId: row['device_id'] as String,
      sequence: row['device_sequence'] as int,
    );
  }

  Future<void> _ensureSafeToRefresh(Transaction txn, String customerId) async {
    final rows = await txn.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM sync_queue q
      JOIN payments p ON p.id = q.payment_id
      WHERE p.customer_id = ?
        AND (q.status = 'syncing'
             OR (q.status = 'pending' AND q.outcome_unknown = 1))
      ''',
      [customerId],
    );

    if ((rows.single['total'] as int) > 0) {
      throw const ConflictResolutionBlocked(
        'هناك عمليات لهذا العميل لم يصلنا ردّها بعد. '
        'انتظر حتى يتم التأكد منها ثم راجع التعارض.',
      );
    }
  }

  Future<void> _closeConflictOp(
    Transaction txn, {
    required String operationId,
    required String paymentId,
    required String status,
    int? replacedBySequence,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await txn.update(
      'sync_queue',
      {
        'status': status,
        'resolved_at': now,
        'replaced_by_sequence': replacedBySequence,
      },
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );

    await txn.update(
      'payments',
      {'status': status},
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  Future<void> _refreshDebtCache(
    Transaction txn,
    String customerId,
    List<Map<String, Object?>> serverDebts,
  ) async {
    final confirmedRows = await txn.rawQuery(
      '''
      SELECT pa.debt_id AS debt_id, COALESCE(SUM(pa.amount), 0) AS total
      FROM payment_allocations pa
      JOIN payments p ON p.id = pa.payment_id
      WHERE p.customer_id = ? AND p.status = 'confirmed'
      GROUP BY pa.debt_id
      ''',
      [customerId],
    );
    final confirmed = {
      for (final r in confirmedRows) r['debt_id'] as String: r['total'] as int,
    };

    await txn.delete(
      'debts',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );

    int? serverVersion;
    for (final debt in serverDebts) {
      final row = Map<String, Object?>.from(debt);
      final version = row.remove('server_version') as int?;
      serverVersion ??= version;
      row['server_outstanding'] =
          (row['server_outstanding'] as int) + (confirmed[row['id']] ?? 0);
      await txn.insert('debts', row);
    }

    if (serverVersion == null) return;

    await txn.insert('app_metadata', {
      'key': 'server_version:$customerId',
      'value': serverVersion.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final unsent = await txn.rawQuery(
      '''
      SELECT q.operation_id
      FROM sync_queue q
      JOIN payments p ON p.id = q.payment_id
      WHERE p.customer_id = ? AND q.status = 'pending'
      ORDER BY q.device_sequence ASC
      ''',
      [customerId],
    );
    for (var i = 0; i < unsent.length; i++) {
      await txn.update(
        'sync_queue',
        {'expected_server_version': serverVersion + i},
        where: 'operation_id = ?',
        whereArgs: [unsent[i]['operation_id']],
      );
    }
  }

  Future<int> _availableForCustomer(Transaction txn, String customerId) async {
    final rows = await txn.query(
      'debts',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );

    var total = 0;
    for (final row in rows) {
      final collected = await _locallyCollectedForDebt(
        txn,
        row['id'] as String,
      );
      final outstanding = (row['server_outstanding'] as int) - collected;
      if (outstanding > 0) total += outstanding;
    }
    return total;
  }
}

class ConflictResolutionBlocked implements Exception {
  const ConflictResolutionBlocked(this.message);

  final String message;

  @override
  String toString() => message;
}

class _ConflictOpInfo {
  const _ConflictOpInfo({
    required this.paymentId,
    required this.customerId,
    required this.deviceId,
    required this.sequence,
  });

  final String paymentId;
  final String customerId;
  final String deviceId;
  final int sequence;
}
