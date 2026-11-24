import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class DebtStatusBadge extends StatelessWidget {
  const DebtStatusBadge({
    super.key,
    required this.operations,
    required this.isOnline,
  });

  final List<SyncOperation> operations;
  final bool isOnline;
  

  @override
  Widget build(BuildContext context) {
    final conflictCount = operations
        .where((o) => o.uiState == OpUiState.conflict)
        .length;
    final openCount = operations
        .where(
          (o) =>
              o.uiState == OpUiState.pending ||
              o.uiState == OpUiState.syncing ||
              o.uiState == OpUiState.verifying,
        )
        .length;

    if (conflictCount > 0) {
      return StatusBadge(
        text: '$conflictCount تحتاج مراجعتك',
        tone: BadgeTone.red,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (!isOnline) {
      return const StatusBadge(
        text: 'بدون اتصال',
        tone: BadgeTone.dark,
        icon: Icons.wifi_off_rounded,
      );
    }
    if (openCount > 0) {
      return StatusBadge(
        text: '$openCount بانتظار الإرسال',
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
