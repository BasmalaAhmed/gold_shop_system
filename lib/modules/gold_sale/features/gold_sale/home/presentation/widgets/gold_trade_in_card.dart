import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_trade_in.dart';

class GoldTradeInCard extends StatelessWidget {
  const GoldTradeInCard({
    super.key,
    required this.tradeIn,
    required this.tradeInValuePiasters,
    this.onTap,
  });

  final TradeInInput tradeIn;
  final int tradeInValuePiasters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {

    final valueEgp = PriceFormatter.formatPiasters(tradeInValuePiasters);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monetization_on_outlined,
                color: AppTheme.greenText,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بدل · عيار ${tradeIn.karat}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),

                Text(
                  '${(tradeIn.weightMg / 1000).toStringAsFixed(3)} جم',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),

            Text(
              'يُخصم $valueEgp',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.greenText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
