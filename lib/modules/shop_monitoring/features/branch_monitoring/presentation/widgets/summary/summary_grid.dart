import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/shop_monitoring/core/theme/app_colors.dart';
import 'summary_card.dart';

class SummaryGrid extends StatelessWidget {
  const SummaryGrid({
    super.key,
    required this.totalSales,
    required this.totalCash,
  });

  final int totalSales;
  final int totalCash;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth < 600 ? 1.05 : 1.6,
          children: [
            SummaryCard(
              title: 'إجمالي المبيعات',
              value: totalSales.toString(),
              icon: Icons.trending_up_rounded,
              iconColor: AppColors.secondary,
            ),
            SummaryCard(
              title: 'إجمالي النقدية',
              value: totalCash.toString(),
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.gold,
            ),
          ],
        );
      },
    );
  }
}
