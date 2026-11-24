import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:gold_shop_app/modules/debts_payment/core/theme/app_colors.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/info_row.dart';

class PaymentSavedView extends StatelessWidget {
  const PaymentSavedView({
    super.key,
    required this.operation,
    required this.customerName,
    required this.isOnline,
  });

  final SyncOperation operation;
  final String customerName;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.syncedBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 44,
                        color: AppColors.syncedIcon,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'تم حفظ التحصيل',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatEgp(operation.amount)} من $customerName',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        children: [
                          InfoRow(
                            label: 'رقم العملية',
                            value: operation.displayId,
                          ),
                          const SizedBox(height: 10),
                          InfoRow(
                            label: 'الجهاز · الترتيب',
                            value:
                                '${operation.deviceLabel} · ${operation.deviceSequence}',
                          ),
                          const Divider(
                            height: 24,
                            thickness: 1,
                            color: AppColors.divider,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.smartphone_rounded,
                                size: 18,
                                color: AppColors.pendingNoticeText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isOnline
                                      ? 'حُفظت على الجهاز وجارٍ إرسالها للخادم. '
                                            'وإذا أغلقت التطبيق ستجدها كما هي.'
                                      : 'حُفظت على الجهاز وستُرسل تلقائياً فور '
                                            'عودة الاتصال. وإذا أغلقت التطبيق '
                                            'ستجدها كما هي.',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.pendingNoticeText,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: CustomButton(
                label: 'تم',
                height: 52,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
