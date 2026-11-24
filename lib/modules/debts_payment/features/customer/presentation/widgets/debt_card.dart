import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/debt_balance.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/debt_card_content.dart';
import 'package:flutter/material.dart';

class DebtCard extends StatelessWidget {
  const DebtCard({super.key, required this.debts});

  final List<DebtBalance> debts;

  @override
  Widget build(BuildContext context) {
    final firstOpenIndex = debts.indexWhere((d) => d.localOutstanding > 0);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < debts.length; index++) ...[
            DebtCardContent(
              number: index + 1,
              debt: debts[index],
              isFirstOpen: index == firstOpenIndex,
            ),
            if (index < debts.length - 1)
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}
