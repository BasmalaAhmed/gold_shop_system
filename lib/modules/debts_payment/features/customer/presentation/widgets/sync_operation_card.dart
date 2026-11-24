import 'package:gold_shop_app/modules/debts_payment/core/customers/customer_info.dart';
import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/formatters/time_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_styles.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class SyncOperationCard extends StatelessWidget {
  const SyncOperationCard({super.key, required this.operation, this.onTap});

  final SyncOperation operation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final op = operation;
    final isConflict = op.uiState == OpUiState.conflict;
    final (badgeText, tone) = _badge(op.uiState);
    final note = _note(op);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isConflict ? AppColors.conflictText : AppColors.cardBorder,
            width: isConflict ? 1.2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatEgp(op.amount), style: AppStyles.amountMedium),
                    StatusBadge(text: badgeText, tone: tone),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  customerInfoFor(op.customerId).name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ترتيب ${op.deviceSequence} · '
                  '${formatClock(op.createdAt)} · ${op.displayId}',
                  style: AppStyles.cardSubtitle,
                ),
                if (note != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    note.text,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: note.color,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, BadgeTone) _badge(OpUiState state) => switch (state) {
    OpUiState.conflict => ('تعارض', BadgeTone.red),
    OpUiState.verifying => ('جارٍ التأكد', BadgeTone.blue),
    OpUiState.syncing => ('جارٍ الإرسال', BadgeTone.blue),
    OpUiState.pending => ('على الجهاز', BadgeTone.orange),
    OpUiState.confirmed => ('تم', BadgeTone.green),
    OpUiState.cancelled => ('أُلغيت', BadgeTone.grey),
    OpUiState.superseded => ('استُبدلت', BadgeTone.grey),
  };

  ({String text, Color color})? _note(SyncOperation op) {
    switch (op.uiState) {
      case OpUiState.conflict:
        final balance = op.conflictServerBalance;
        return (
          text: balance == null
              ? 'تعارض مع الخادم. اضغط لعرض التفاصيل.'
              : 'المتبقي على الخادم ${formatEgp(balance)} فقط. '
                    'اضغط لعرض التفاصيل.',
          color: AppColors.conflictText,
        );
      case OpUiState.verifying:
        return (
          text:
              'لم يصلنا رد الخادم. سنعيد الإرسال بالرقم نفسه '
              'ولن تُسجَّل مرتين.',
          color: AppColors.syncingText,
        );
      case OpUiState.confirmed:
        if (op.alreadyProcessed) {
          return (
            text: 'تم التحقق: الخادم سجّلها من قبل. تحصيل واحد فقط دون تكرار.',
            color: AppColors.syncedText,
          );
        }
        final at = op.confirmedAt;
        return at == null
            ? null
            : (
                text: 'أكّده الخادم ${formatClock(at)}',
                color: AppColors.syncedText,
              );
      case OpUiState.cancelled:
        return (
          text: 'رفضها الخادم وأُلغيت بقرارك. العملية محفوظة في السجل.',
          color: AppColors.textSecondary,
        );
      case OpUiState.superseded:
        final next = op.replacedByDisplayId;
        return (
          text: next == null
              ? 'استُبدلت بعملية جديدة. هذه العملية محفوظة في السجل.'
              : 'استُبدلت بالعملية $next. هذه العملية محفوظة في السجل.',
          color: AppColors.textSecondary,
        );
      case OpUiState.syncing:
      case OpUiState.pending:
        final from = op.replacesDisplayId;
        return from == null
            ? null
            : (
                text: 'بديلة للعملية $from بعد مراجعة التعارض.',
                color: AppColors.textSecondary,
              );
    }
  }
}
