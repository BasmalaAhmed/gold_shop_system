import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class DebtErrorView extends StatelessWidget {
  const DebtErrorView({super.key, required this.errorMessage, required this.onRetry});

   final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'حدث خطأ أثناء تحميل المديونيات:\n$errorMessage',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            CustomButton(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
