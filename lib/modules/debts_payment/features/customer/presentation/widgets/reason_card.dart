import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ReasonCard extends StatelessWidget {
  const ReasonCard({super.key, required this.reasonText});

  final String reasonText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.keyBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'السبب',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                reasonText,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'لم نحذف العملية ولم نغيّر مبلغها. '
                'القرار لك بعد المراجعة مع العميل.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
