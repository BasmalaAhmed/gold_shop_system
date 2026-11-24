import 'package:gold_shop_app/modules/debts_payment/core/formatters/time_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/data/mock/mock_network.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/queue_banner.dart';
import 'package:flutter/material.dart';

class OperationQueueBanner extends StatelessWidget {
  const OperationQueueBanner({
    super.key,
    required this.operations,
    required this.network,
    required this.isSyncing,
    required this.autoSyncing,
    required this.waitingCount,
    required this.conflictsCount,
  });

  final List<SyncOperation> operations;
  final MockNetwork network;
  final bool isSyncing;
  final bool autoSyncing;
  final int waitingCount;
  final int conflictsCount;

  bool _has(OpUiState state) => operations.any((o) => o.uiState == state);

  @override
  Widget build(BuildContext context) {
    Widget? banner;

    if (!network.isOnline) {
      banner = QueueBanner(
        tone: BannerTone.dark,
        icon: Icons.wifi_off_rounded,
        title: 'لا يوجد اتصال',
        message:
            'سيُرسل تلقائياً فور عودة الاتصال. (اضغط هنا لمحاولة عودة الاتصال)',
        onTap: () => network.setOnline(true),
      );
    } else if (waitingCount > 0 &&
        (isSyncing || autoSyncing || _has(OpUiState.syncing))) {
      banner = const QueueBanner(
        tone: BannerTone.blue,
        icon: Icons.sync_rounded,
        title: 'عاد الاتصال · جارٍ الإرسال',
        message:
            'تُرسل العمليات بترتيبها، وإذا أغلقت التطبيق سنكمل من النقطة نفسها.',
      );
    } else if (_has(OpUiState.verifying)) {
      banner = const QueueBanner(
        tone: BannerTone.blue,
        icon: Icons.sync_rounded,
        title: 'جارٍ التأكد من عمليات لم يصلنا ردّها',
        message:
            'وجدنا عمليات لم نتأكد من وصولها. سنعيد إرسالها بنفس رقمها وترتيبها فلا تتكرر.',
      );
    } else if (operations.isNotEmpty &&
        waitingCount == 0 &&
        conflictsCount == 0 &&
        _has(OpUiState.confirmed)) {
      final last = operations
          .map((o) => o.confirmedAt)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
      banner = QueueBanner(
        tone: BannerTone.green,
        icon: Icons.check_rounded,
        title: 'وصلت جميع التحصيلات إلى الخادم',
        message: last == null
            ? 'لا توجد عمليات معلقة.'
            : 'آخر مزامنة ${formatClock(last)}',
      );
    }
    if (banner == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: banner);
  }
}
