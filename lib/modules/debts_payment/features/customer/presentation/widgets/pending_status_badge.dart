import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class PendingStatusBadge extends StatelessWidget {
  const PendingStatusBadge({
    super.key,
    required this.operations,
    required this.isOnline,
    required this.isSyncing,
  });

  final List<SyncOperation> operations;
  final bool isOnline;
  final bool isSyncing;
  bool _has(OpUiState state) => operations.any((o) => o.uiState == state);

  @override
  Widget build(BuildContext context) {
    final conflicts = operations
        .where((o) => o.uiState == OpUiState.conflict)
        .length;
    final waiting = operations
        .where(
          (o) =>
              o.uiState == OpUiState.pending ||
              o.uiState == OpUiState.syncing ||
              o.uiState == OpUiState.verifying,
        )
        .length;
    if (conflicts > 0) {
      return StatusBadge(
        text: '$conflicts تحتاج مراجعتك',
        tone: BadgeTone.red,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (_has(OpUiState.syncing) || isSyncing) {
      return const StatusBadge(
        text: 'جارٍ الإرسال',
        tone: BadgeTone.blue,
        icon: Icons.sync_rounded,
      );
    }
    if (_has(OpUiState.verifying)) {
      return const StatusBadge(
        text: 'جارٍ التأكد',
        tone: BadgeTone.blue,
        icon: Icons.sync_rounded,
      );
    }
    if (!isOnline) {
      return const StatusBadge(
        text: 'بدون اتصال',
        tone: BadgeTone.dark,
        icon: Icons.wifi_off_rounded,
      );
    }
    if (waiting > 0) {
      return StatusBadge(
        text: '$waiting بانتظار الإرسال',
        tone: BadgeTone.orange,
        icon: Icons.schedule_rounded,
      );
    }
    return const StatusBadge(
      text: 'متزامن',
      tone: BadgeTone.green,
      icon: Icons.check_rounded,
    );
  }
}
