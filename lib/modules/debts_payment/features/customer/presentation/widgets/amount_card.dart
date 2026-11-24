import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/amount_row.dart';
import 'package:flutter/material.dart';

class AmountCard extends StatelessWidget {
  const AmountCard({super.key, required this.amount, this.serverBalance, required this.exceeds});

    final int amount;
  final int? serverBalance;
  final bool exceeds;

  @override
  Widget build(BuildContext context) {
    return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        AmountRow(
                          label: 'المبلغ الذي سجّلته',
                          value: formatEgp(amount),
                        ),
                        if (serverBalance != null) ...[
                          const SizedBox(height: 10),
                          AmountRow(
                            label: 'المتبقي على الخادم',
                            value: formatEgp(serverBalance!),
                          ),
                        ],
                        if (exceeds) ...[
                          const Divider(
                            height: 24,
                            thickness: 1,
                            color: AppColors.divider,
                          ),
                          AmountRow(
                            label: 'الفرق',
                            value: formatEgp(amount - serverBalance!),
                            color: AppColors.conflictText,
                            bold: true,
                          ),
                        ],
                      ],
                    ),
                  );
  }
}