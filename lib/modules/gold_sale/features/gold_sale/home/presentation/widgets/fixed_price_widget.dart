import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';

class FixedPriceWidget extends StatelessWidget {
  const FixedPriceWidget({
    super.key,
    this.price = 4200.0,
    this.buyPrice = 4050.0,
    this.karat = 21,
    this.onRefresh,
    this.showBuyPrice = false,
  });

  final double price;
  final double buyPrice;
  final int karat;
  final VoidCallback? onRefresh;
  final bool showBuyPrice;

  @override
  Widget build(BuildContext context) {
    final formattedPrice = PriceFormatter.format(price);
    final formattedBuyPrice = PriceFormatter.format(buyPrice);

    final text = showBuyPrice
        ? 'سعر $karat مثبّت: $formattedPrice · شراء $formattedBuyPrice'
        : 'سعر $karat مثبّت: $formattedPrice';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.pillTealBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppTheme.pillTealText,
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  color: AppTheme.pillTealText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onRefresh,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'تحديث السعر',
            style: TextStyle(
              color: AppTheme.primaryTeal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
