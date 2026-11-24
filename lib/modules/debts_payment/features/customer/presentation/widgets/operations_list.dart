import 'package:gold_shop_app/modules/debts_payment/core/formatters/time_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/operation_queue_banner.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/operations_section.dart';
import 'package:flutter/material.dart';

class OperationsList extends StatelessWidget {
  const OperationsList({
    super.key,
    required this.operations,
    required this.network,
    required this.isSyncing,
    required this.autoSyncing,
    required this.onRefresh,
    required this.onOpenConflict,
  });

  final List<SyncOperation> operations;
  final MockNetwork network;
  final bool isSyncing;
  final bool autoSyncing;
  final Future<void> Function() onRefresh;
  final ValueChanged<SyncOperation> onOpenConflict;

  @override
  Widget build(BuildContext context) {
    final review = operations
        .where((o) => o.uiState == OpUiState.conflict)
        .toList();
    final waiting = operations
        .where(
          (o) =>
              o.uiState == OpUiState.pending ||
              o.uiState == OpUiState.syncing ||
              o.uiState == OpUiState.verifying,
        )
        .toList();
    final now = DateTime.now();
    final doneToday = operations
        .where(
          (o) =>
              o.uiState == OpUiState.confirmed &&
              o.confirmedAt != null &&
              isSameLocalDay(o.confirmedAt!, now),
        )
        .toList();
    final closed = operations
        .where(
          (o) =>
              o.uiState == OpUiState.cancelled ||
              o.uiState == OpUiState.superseded,
        )
        .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          OperationQueueBanner(
            operations: operations,
            network: network,
            isSyncing: isSyncing,
            autoSyncing: autoSyncing,
            waitingCount: waiting.length,
            conflictsCount: review.length,
          ),
          if (operations.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Text(
                  'لا يوجد عمليات تحصيل حتى الآن',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          if (review.isNotEmpty)
            OperationsSection(
              title: 'تحتاج مراجعتك',
              items: review,
              onItemTap: onOpenConflict,
            ),
          if (waiting.isNotEmpty)
            OperationsSection(title: 'بانتظار الإرسال', items: waiting),
          if (doneToday.isNotEmpty)
            OperationsSection(title: 'تم الإرسال اليوم', items: doneToday),
          if (closed.isNotEmpty)
            OperationsSection(title: 'تمت مراجعتها', items: closed),
        ],
      ),
    );
  }
}
