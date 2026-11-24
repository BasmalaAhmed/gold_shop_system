import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_styles.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:flutter/material.dart';

class DeptSummaryCard extends StatelessWidget {
  const DeptSummaryCard({
    super.key,
    required this.customerFirstName,
    required this.localTotal,
    required this.serverTotal,
    required this.pendingTotal,
    this.conflictOp,
    this.hasConfirmed = false,
  });

  final String customerFirstName;
  final int localTotal;
  final int serverTotal;
  final int pendingTotal;
  final SyncOperation? conflictOp;
  final bool hasConfirmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المتبقي على $customerFirstName',
            style: AppStyles.screenSubtitle,
          ),
          const SizedBox(height: 8),
          Text(formatEgp(localTotal), style: AppStyles.amountHero),
          const SizedBox(height: 12),
          _footer(),
        ],
      ),
    );
  }

  Widget _footer() {
    final conflict = conflictOp;

    if (conflict != null) {
      return _Notice(
        background: AppColors.conflictBg,
        border: AppColors.conflictBorder,
        color: AppColors.conflictText,
        message:
            'يوجد تعارض: سجّلت ${formatEgp(conflict.amount)} بينما المتبقي '
            'على الخادم ${formatEgp(serverTotal)} فقط. '
            'لا تسجّل تحصيلاً جديداً من $customerFirstName قبل المراجعة.',
        detail: 'أكّده الخادم: ${formatEgp(serverTotal)}',
      );
    }

    if (pendingTotal > 0) {
      return _Notice(
        background: AppColors.pendingNoticeBg,
        border: AppColors.pendingNoticeBorder,
        color: AppColors.pendingNoticeText,
        message:
            'منها ${formatEgp(pendingTotal)} محفوظة على الجهاز '
            'ولم يؤكدها الخادم بعد.',
        detail: 'أكّده الخادم: ${formatEgp(serverTotal)}',
      );
    }

    return Row(
      children: [
        Text(
          hasConfirmed
              ? 'مطابق للخادم · تم تأكيد جميع التحصيلات'
              : 'مطابق للخادم',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.syncedText,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.check_rounded, size: 16, color: AppColors.syncedIcon),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.background,
    required this.border,
    required this.color,
    required this.message,
    required this.detail,
  });

  final Color background;
  final Color border;
  final Color color;
  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(detail, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
