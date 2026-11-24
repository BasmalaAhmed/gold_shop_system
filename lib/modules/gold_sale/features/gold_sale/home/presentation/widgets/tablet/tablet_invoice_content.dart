import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/models/invoice_model.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/disabled_card.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/gold_item_card.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/gold_trade_in_card.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/outlined_card.dart';

class TabletInvoiceContent extends StatelessWidget {
  const TabletInvoiceContent({
    super.key,
    required this.cart,
    required this.isPendingApproval,
    required this.invoiceError,
    required this.onShowCalculation,
    required this.onEditDiscount,
    required this.onRemove,
    required this.onOpenScanner,
    required this.onOpenTradeIn,
  });

  final GoldSaleCart cart;
  final bool isPendingApproval;
  final InvoiceError? invoiceError;

  final ValueChanged<int> onShowCalculation;
  final VoidCallback onEditDiscount;
  final ValueChanged<String> onRemove;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenTradeIn;

  @override
  Widget build(BuildContext context) {
    final lineResults = cart.lineResults;
    final pendingItemsLabel = cart.items.isEmpty
        ? ''
        : cart.items.map((item) => '${item.name} (${item.code})').join('، ');

    return SingleChildScrollView(
      child: Column(
        children: [
          if (invoiceError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.redLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.redBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoiceError!.title,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.redText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoiceError!.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.redText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.redText,
                    size: 24,
                  ),
                ],
              ),
            ),

          if (isPendingApproval)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.amberLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.amberBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بانتظار موافقة صاحب المحل',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.amberText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'خصم ${cart.discountPercent}% على $pendingItemsLabel، سنكمل تلقائيًا فور الرد.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.amberText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.access_time_rounded,
                    color: AppTheme.amberText,
                    size: 24,
                  ),
                ],
              ),
            ),

          for (int i = 0; i < cart.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GoldItemCard(
                item: cart.items[i],
                result: lineResults[i],
                discountPercent: cart.discountPercent,
                isPendingApproval: isPendingApproval,
                onShowCalculation: () => onShowCalculation(i),
                onEditDiscount: onEditDiscount,
                onRemove: () => onRemove(cart.items[i].code),
              ),
            ),

          if (cart.tradeIn != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GoldTradeInCard(
                tradeIn: cart.tradeIn!,
                tradeInValuePiasters: cart.tradeInValuePiasters,
                onTap: onOpenTradeIn,
              ),
            ),

          if (cart.items.length < 2)
            OutlinedCard(
              title: 'إضافة قطعة أخرى (${cart.items.length} من 2)',
              icon: Icons.filter_center_focus_rounded,
              onTap: onOpenScanner,
            )
          else
            DisabledCard(
              title: 'وصلت للحد الأقصى (قطعتين)',
              icon: Icons.filter_center_focus_rounded,
            ),

          const SizedBox(height: 10),

          if (cart.tradeIn == null)
            OutlinedCard(
              title: 'إضافة بدل (ذهب قديم)',
              icon: Icons.monetization_on_outlined,
              onTap: onOpenTradeIn,
            ),
        ],
      ),
    );
  }
}
