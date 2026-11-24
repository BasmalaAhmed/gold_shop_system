import 'package:gold_shop_app/modules/debts_payment/core/allocation_preview.dart';
import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_styles.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/allocation_preview_card.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/amount_chip.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/hint_box.dart';
import 'package:flutter/material.dart';

class PaymentEntryBody extends StatelessWidget {
  const PaymentEntryBody({
    super.key,
    this.amount,
    required this.available,
    required this.unconfirmed,
    required this.exceeds,
    required this.debts,
    required this.customerFirstName,
    required this.onSelectAmount,
  });

  final int? amount;
  final int available;
  final int unconfirmed;
  final bool exceeds;
  final List<DebtBalance> debts;
  final String customerFirstName;
  final ValueChanged<int> onSelectAmount;

  @override
  Widget build(BuildContext context) {
    final openDebts = debts.where((d) => d.localOutstanding > 0).toList();
    final oldest = openDebts.isEmpty ? 0 : openDebts.first.localOutstanding;
    final showOldestChip = openDebts.length > 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount == null ? '0.00 ج.م' : formatEgp(amount!),
              style: AppStyles.amountHero.copyWith(
                fontSize: 42,
                color: exceeds
                    ? AppColors.conflictText
                    : amount == null
                    ? AppColors.textDisabled
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            exceeds
                ? 'أكبر من المتبقي. الحد الأقصى ${formatEgp(available)}'
                : 'الحد الأقصى ${formatEgp(available)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: exceeds ? FontWeight.w700 : FontWeight.w400,
              color: exceeds ? AppColors.conflictText : AppColors.textMuted,
            ),
          ),
          if (unconfirmed > 0) ...[
            const SizedBox(height: 4),
            Text(
              'بعد خصم ${formatEgp(unconfirmed)} محفوظة على الجهاز '
              'ولم تُؤكَّد بعد',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.pendingNoticeText,
              ),
            ),
          ],
          if (available > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showOldestChip) ...[
                  AmountChip(
                    label: 'القسط الأقدم',
                    value: oldest,
                    selected: amount == oldest,
                    onTap: () => onSelectAmount(oldest),
                  ),
                  const SizedBox(width: 10),
                ],
                AmountChip(
                  label: 'كل المتبقي',
                  value: available,
                  selected: amount == available,
                  onTap: () => onSelectAmount(available),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (amount == null)
            const HintBox(
              text:
                  'اكتب المبلغ أو اختر من الأعلى، وسنعرض لك توزيعه على '
                  'المديونيات قبل الحفظ.',
            )
          else if (!exceeds)
            AllocationPreviewCard(
              lines: previewAllocation(debts, amount!),
              remainingAfter: available - amount!,
              customerFirstName: customerFirstName,
            ),
        ],
      ),
    );
  }
}
