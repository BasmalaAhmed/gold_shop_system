import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_styles.dart';
import 'package:flutter/material.dart';

class CustomerHeader extends StatelessWidget {
  const CustomerHeader({
    super.key,
    required this.name,
    required this.phone,
    required this.chip,
    this.onDebugTap,
  });

  final String name;
  final String phone;
  final Widget chip;
  final VoidCallback? onDebugTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppStyles.screenTitle),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        textDirection: TextDirection.ltr,
                        style: AppStyles.cardSubtitle,
                      ),
                  ],
                ),
              ),
              chip,
              if (onDebugTap != null)
                IconButton(
                  onPressed: onDebugTap,
                  icon: const Icon(Icons.bug_report_outlined, size: 20),
                  tooltip: 'أدوات التجربة',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
