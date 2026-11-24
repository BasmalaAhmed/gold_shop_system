import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/amount_keypad.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class KeypadSection extends StatelessWidget {
  const KeypadSection({
    super.key,
    this.amount,
    required this.isSaving,
    required this.canSave,
    this.saveError,
    required this.onSave,
    required this.onKey,
  });

  final int? amount;
  final bool isSaving;
  final bool canSave;
  final String? saveError;
  final VoidCallback onSave;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.keypadBackground,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    saveError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.conflictText,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CustomButton(
                  label: isSaving
                      ? 'جارٍ الحفظ...'
                      : (canSave && amount != null)
                      ? 'حفظ ${formatEgp(amount!)}'
                      : 'حفظ',
                  icon: (canSave && amount != null) ? Icons.check : null,
                  height: 50,
                  onPressed: canSave ? onSave : null,
                ),
              ),
              const SizedBox(height: 10),
              AmountKeypad(onKey: onKey),
            ],
          ),
        ),
      ),
    );
  }
}
