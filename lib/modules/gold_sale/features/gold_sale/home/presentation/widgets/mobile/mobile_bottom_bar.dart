import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';

class MobileBottomBar extends StatelessWidget {
  const MobileBottomBar({
    super.key,
    required this.totalEgp,
    required this.tradeInValueEgp,
    required this.amountDueEgp,
    required this.hasTradeIn,
    required this.isPendingApproval,
    required this.onCancelPending,
    required this.onPay,
  });

  final String totalEgp;
  final String tradeInValueEgp;
  final String amountDueEgp;

  final bool hasTradeIn;
  final bool isPendingApproval;

  final VoidCallback onCancelPending;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPendingApproval) ...[
            GestureDetector(
              onTap: onCancelPending,
              child: const Text(
                'إلغاء الطلب والرجوع إلى 10%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.redText,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (hasTradeIn)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'القطع $totalEgp · البدل $tradeInValueEgp',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasTradeIn ? 'المستحق' : 'الإجمالي',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '$amountDueEgp ج.م',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isPendingApproval ? null : onPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPendingApproval
                    ? const Color(0xFF94A3B8)
                    : AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                isPendingApproval ? 'الدفع (بعد الموافقة)' : 'الدفع',
                style: const TextStyle(
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
}
