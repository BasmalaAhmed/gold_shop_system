import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_styles.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final Color? borderColor;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.borderColor,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    if (isOutlined) {
      final borderC = isEnabled
          ? (borderColor ?? AppColors.conflictBorder)
          : AppColors.cardBorder;
      final textC = isEnabled
          ? (foregroundColor ?? AppColors.conflictText)
          : AppColors.textMuted;

      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderC, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: textC),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppStyles.buttonText.copyWith(color: textC),
            ),
          ],
        ),
      );
    }

    final bg = isEnabled
        ? (backgroundColor ?? AppColors.primaryTeal)
        : AppColors.buttonDisabled;
    final fg = foregroundColor ?? Colors.white;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppStyles.buttonText.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
