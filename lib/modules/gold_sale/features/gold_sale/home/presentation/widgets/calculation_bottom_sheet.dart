import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';

class CalculationBottomSheet extends StatelessWidget {
  const CalculationBottomSheet({
    super.key,
    required this.item,
    required this.result,
    required this.discountPercent,
    this.isDialog = false,
  });

  final GoldSaleCartItem item;
  final GoldSaleLineResult result;
  final int discountPercent;
  final bool isDialog;

  static void show(
    BuildContext context, {
    required GoldSaleCartItem item,
    required GoldSaleLineResult result,
    required int discountPercent,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 720;
    if (isTablet) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CalculationBottomSheet(
              item: item,
              result: result,
              discountPercent: discountPercent,
              isDialog: true,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CalculationBottomSheet(
          item: item,
          result: result,
          discountPercent: discountPercent,
          isDialog: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final netWeightGm = result.netWeightMg / 1000.0;
    final goldPriceGm = item.input.goldPricePerGramPiasters / 100.0;
    final laborRate = item.input.laborValue / 100.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDialog) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'حساب القطعة · ${item.code}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _metricBox('عيار', '${item.input.karat}'),
              const SizedBox(width: 8),
              _metricBox('صافي', '${netWeightGm.toStringAsFixed(3)} جم'),
              const SizedBox(width: 8),
              _metricBox('فصوص', '${item.input.stonesWeightMg} مجم'),
              const SizedBox(width: 8),
              _metricBox('قائم', '${item.input.grossWeightMg} مجم'),
            ],
          ),
          const SizedBox(height: 20),
          _row(
            title:
                'قيمة الذهب (${netWeightGm.toStringAsFixed(3)} جم × ${PriceFormatter.format(goldPriceGm)})',
            value: PriceFormatter.formatPiasters(result.goldValuePiasters),
          ),
          const SizedBox(height: 12),
          _row(
            title: item.input.laborPricingType == LaborPricingType.fixed
                ? 'المصنعية (ثابتة)'
                : 'المصنعية (${netWeightGm.toStringAsFixed(3)} جم × ${PriceFormatter.format(laborRate)})',
            value: PriceFormatter.formatPiasters(
              result.laborBeforeDiscountPiasters,
            ),
          ),
          const SizedBox(height: 12),
          _row(
            title: 'خصم $discountPercent% على المصنعية',
            value: PriceFormatter.formatPiasters(
              result.discountPiasters,
            ),
            isGreen: true,
          ),
          const SizedBox(height: 12),
          _row(
            title:
                'ضريبة 14% على ${PriceFormatter.formatPiasters(result.laborAfterDiscountPiasters)}',
            value: PriceFormatter.formatPiasters(result.taxPiasters),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppTheme.borderSubtle),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي القطعة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${PriceFormatter.formatPiasters(result.totalPiasters)} ج.م',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryTeal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'تمام',
                style: TextStyle(
                  color: AppTheme.primaryTeal,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required String title,
    required String value,
    bool isGreen = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isGreen ? AppTheme.greenText : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
