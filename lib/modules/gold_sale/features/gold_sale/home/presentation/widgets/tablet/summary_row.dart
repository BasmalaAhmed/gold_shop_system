import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isGreen = false,
    this.isAmber = false,
  });
  final String label;
  final String value;
  final bool isGreen, isAmber;

  @override
  Widget build(BuildContext context) {
    Color textColor = AppTheme.textPrimary;
    if (isGreen) textColor = AppTheme.greenText;
    if (isAmber) textColor = AppTheme.amberText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
