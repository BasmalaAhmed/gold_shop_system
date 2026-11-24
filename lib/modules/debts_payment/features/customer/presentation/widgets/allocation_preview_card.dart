import 'package:gold_shop_app/modules/debts_payment/core/allocation_preview.dart';
import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AllocationPreviewCard extends StatelessWidget {
  const AllocationPreviewCard({
    super.key,
    required this.lines,
    required this.remainingAfter,
    required this.customerFirstName,
  });

  final List<AllocationLine> lines;
  final int remainingAfter;
  final String customerFirstName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'سيُوزَّع المبلغ كالتالي:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    line.closesDebt
                        ? 'مديونية ${line.debtNumber} · تُسدَّد بالكامل ✓'
                        : 'مديونية ${line.debtNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: line.closesDebt
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: line.closesDebt
                          ? AppColors.syncedText
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    formatEgpNumber(line.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 16, thickness: 1, color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المتبقي على $customerFirstName',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatEgp(remainingAfter),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
