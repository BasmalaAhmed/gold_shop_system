import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class DebtBottomBar extends StatelessWidget {
  const DebtBottomBar({
    super.key,
    required this.hasConflict,
    required this.onPressed,
  });

  final bool hasConflict;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: CustomButton(
        label: hasConflict ? 'مراجعة التعارض' : 'تسجيل تحصيل',
        icon: Icons.add,
        height: 52,
        backgroundColor: hasConflict ? AppColors.conflictButtonBg : null,
        onPressed: onPressed,
      ),
    );
  }
}
