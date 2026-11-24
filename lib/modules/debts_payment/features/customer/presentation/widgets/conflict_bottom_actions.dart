import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class ConflictBottomActions extends StatelessWidget {
  const ConflictBottomActions({
    super.key,
    required this.busy,
    this.error,
    required this.canReplace,
    required this.exceeds,
    this.serverBalance,
    required this.onReplace,
    required this.onCancel,
  });

  final bool busy;
  final String? error;
  final bool canReplace;
  final bool exceeds;
  final int? serverBalance;
  final VoidCallback onReplace;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.conflictText,
                      height: 1.6,
                    ),
                  ),
                ),
              if (canReplace) ...[
                CustomButton(
                  label: exceeds
                      ? 'تعديل المبلغ إلى ${formatEgpNumber(serverBalance!)}'
                      : 'إعادة التسجيل بنفس المبلغ',
                  height: 52,
                  onPressed: busy ? null : onReplace,
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: CustomButton(
                  label: 'إلغاء التحصيل',
                  isOutlined: true,
                  onPressed: busy ? null : onCancel,
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => Navigator.of(context).pop(false),
                child: const Text(
                  'تأجيل المراجعة',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
