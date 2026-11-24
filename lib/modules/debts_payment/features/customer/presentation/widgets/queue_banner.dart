import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum BannerTone { dark, blue, green }

class QueueBanner extends StatelessWidget {
  const QueueBanner({
    super.key,
    required this.tone,
    required this.title,
    required this.message,
    required this.icon,
    this.onTap,
  });

  final BannerTone tone;
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onTap;

  (Color bg, Color fg, Color border) get _colors => switch (tone) {
    BannerTone.dark => (
      AppColors.offlineDark,
      Colors.white,
      AppColors.offlineDark,
    ),
    BannerTone.blue => (
      AppColors.syncingBg,
      AppColors.syncingText,
      AppColors.syncingBorder,
    ),
    BannerTone.green => (
      AppColors.syncedBg,
      AppColors.syncedText,
      AppColors.syncedBorder,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _colors;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(fontSize: 12, color: fg, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 22, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}