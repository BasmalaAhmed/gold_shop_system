import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HintBox extends StatelessWidget {
  const HintBox({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.keyBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }
}
