import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/formatters/time_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_styles.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class DebtCardContent extends StatelessWidget {
  const DebtCardContent({
    super.key,
    required this.number,
    required this.debt,
    this.isFirstOpen = false,
  });

  final int number;
  final DebtBalance debt;
  final bool isFirstOpen;

  @override
  Widget build(BuildContext context) {
    final isPaid = debt.localOutstanding == 0;
    final hasConflict = debt.conflictAmount > 0;
    final hasPending = debt.pendingAmount > 0;

    Widget? badge;
    if (hasConflict) {
      badge = const StatusBadge(text: 'تعارض', tone: BadgeTone.red);
    } else if (hasPending) {
      badge = const StatusBadge(text: 'بانتظار التأكيد', tone: BadgeTone.orange);
    } else if (isPaid) {
      badge = const StatusBadge(text: 'مُسدّدة', tone: BadgeTone.green);
    } else if (isFirstOpen) {
      badge = const StatusBadge(text: 'تُحصَّل أولاً', tone: BadgeTone.blue);
    }

    final subtitle = (isPaid && !hasPending && !hasConflict)
        ? 'سُدّدت بالكامل'
        : formatDueDate(debt.dueDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('مديونية $number', style: AppStyles.cardTitle),
                  if (badge != null) ...[const SizedBox(width: 8), badge],
                ],
              ),
              const SizedBox(height: 5),
              Text(subtitle, style: AppStyles.cardSubtitle),
            ],
          ),
          Text(
            formatEgp(debt.localOutstanding),
            style: AppStyles.amountMedium.copyWith(
              color: isFirstOpen ? AppColors.primaryTeal : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}