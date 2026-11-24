import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';


class GoldItemCard extends StatelessWidget {
  const GoldItemCard({
    super.key,
    required this.item,
    required this.result,
    required this.discountPercent,
    required this.isPendingApproval,
    this.onShowCalculation,
    this.onEditDiscount,
    this.onRemove,
  });

  final GoldSaleCartItem item;
  final GoldSaleLineResult result;
  final int discountPercent;
  final bool isPendingApproval;
  final VoidCallback? onShowCalculation;
  final VoidCallback? onEditDiscount;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final netWeightGm = result.netWeightMg / 1000.0;
    final totalPriceEgp = PriceFormatter.formatPiasters(result.totalPiasters);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.pillTealBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: AppTheme.primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} · عيار ${item.input.karat}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.input.laborPricingType == LaborPricingType.fixed
                          ? 'صافي ${netWeightGm.toStringAsFixed(3)} جم · مصنعية ${item.code} ثابتة'
                          : 'صافي ${netWeightGm.toStringAsFixed(3)} جم · ${item.code}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                totalPriceEgp,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onEditDiscount,
                borderRadius: BorderRadius.circular(16),
                child: _buildDiscountBadge(),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onShowCalculation,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppTheme.primaryTeal,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'عرض الحساب',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge() {
    if (isPendingApproval) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.amberLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.amberBorder),
        ),
        child: Text(
          'خصم $discountPercent% · بانتظار',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.amberText,
          ),
        ),
      );
    } else if (discountPercent > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.greenLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'خصم $discountPercent%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.greenText,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.greenLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'بدون خصم',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.greenText,
          ),
        ),
      );
    }
  }
}
