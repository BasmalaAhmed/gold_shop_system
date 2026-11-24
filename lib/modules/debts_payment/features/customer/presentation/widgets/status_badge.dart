import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_styles.dart';
import 'package:flutter/material.dart';

enum BadgeTone { dark, orange, blue, green, red, grey }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.text,
    this.tone = BadgeTone.green,
    this.icon,
  });

  final String text;
  final BadgeTone tone;
  final IconData? icon;

  (Color, Color) get _colors => switch (tone) {
    BadgeTone.dark => (AppColors.offlineDark, AppColors.offlineBadgeText),
    BadgeTone.orange => (
      AppColors.pendingNoticeBg,
      AppColors.pendingNoticeText,
    ),
    BadgeTone.blue => (AppColors.syncingBg, AppColors.syncingText),
    BadgeTone.green => (AppColors.syncedBg, AppColors.syncedText),
    BadgeTone.red => (AppColors.conflictBg, AppColors.conflictText),
        BadgeTone.grey => (AppColors.keyBackground, AppColors.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: AppStyles.badgeText.copyWith(color: fg)),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 13, color: fg),
          ],
        ],
      ),
    );
  }
}
