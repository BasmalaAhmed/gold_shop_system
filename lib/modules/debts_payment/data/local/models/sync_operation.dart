enum OpUiState {
  conflict,
  verifying,
  syncing,
  pending,
  confirmed,
  cancelled,
  superseded,
}

class SyncOperation {
  const SyncOperation({
    required this.operationId,
    required this.paymentId,
    required this.customerId,
    required this.deviceId,
    required this.deviceSequence,
    required this.amount,
    required this.paymentStatus,
    required this.syncStatus,
    required this.createdAt,
    required this.lastError,
    this.outcomeUnknown = false,
    this.alreadyProcessed = false,
    this.confirmedAt,
    this.conflictServerBalance,
    this.conflictOtherDevice,
    this.conflictOtherAmount,
    this.conflictOtherAt,
    this.resolvedAt,
    this.replacedBySequence,
    this.replacesSequence,
  });

  final String operationId;
  final String paymentId;
  final String customerId;
  final String deviceId;
  final int deviceSequence;
  final int amount;
  final String paymentStatus;
  final String syncStatus;
  final DateTime createdAt;
  final String? lastError;
  final bool outcomeUnknown;
  final bool alreadyProcessed;
  final DateTime? confirmedAt;
  final int? conflictServerBalance;
  final String? conflictOtherDevice;
  final int? conflictOtherAmount;
  final DateTime? conflictOtherAt;
  final DateTime? resolvedAt;
  final int? replacedBySequence;
  final int? replacesSequence;

  OpUiState get uiState {
    if (syncStatus == 'cancelled') return OpUiState.cancelled;
    if (syncStatus == 'superseded') return OpUiState.superseded;
    if (syncStatus == 'conflict') return OpUiState.conflict;
    if (syncStatus == 'confirmed') return OpUiState.confirmed;
    if (syncStatus == 'syncing') return OpUiState.syncing;
    if (outcomeUnknown) return OpUiState.verifying;
    return OpUiState.pending;
  }

  String get deviceLabel =>
      deviceId.length < 2 ? deviceId : deviceId.substring(0, 2).toUpperCase();
  String _idFor(int sequence) =>
      'OP-$deviceLabel-${sequence.toString().padLeft(4, '0')}';
  String get displayId => _idFor(deviceSequence);
  String? get replacedByDisplayId =>
      replacedBySequence == null ? null : _idFor(replacedBySequence!);

  String? get replacesDisplayId =>
      replacesSequence == null ? null : _idFor(replacesSequence!);

  factory SyncOperation.fromRow(Map<String, Object?> row) {
    DateTime? parseDate(Object? value) =>
        value == null ? null : DateTime.parse(value as String);

    return SyncOperation(
      operationId: row['operation_id'] as String,
      paymentId: row['payment_id'] as String,
      customerId: row['customer_id'] as String,
      deviceId: row['device_id'] as String,
      deviceSequence: row['device_sequence'] as int,
      amount: row['amount'] as int,
      paymentStatus: row['payment_status'] as String,
      syncStatus: row['sync_status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      lastError: row['last_error'] as String?,
      outcomeUnknown: ((row['outcome_unknown'] as int?) ?? 0) == 1,
      alreadyProcessed: ((row['already_processed'] as int?) ?? 0) == 1,
      confirmedAt: parseDate(row['confirmed_at']),
      conflictServerBalance: row['conflict_server_balance'] as int?,
      conflictOtherDevice: row['conflict_other_device'] as String?,
      conflictOtherAmount: row['conflict_other_amount'] as int?,
      conflictOtherAt: parseDate(row['conflict_other_at']),
      resolvedAt: parseDate(row['resolved_at']),
      replacedBySequence: row['replaced_by_sequence'] as int?,
      replacesSequence: row['replaces_sequence'] as int?,
    );
  }
}
