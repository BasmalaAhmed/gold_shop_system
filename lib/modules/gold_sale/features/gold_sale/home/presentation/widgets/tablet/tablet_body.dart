import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/models/invoice_model.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/tablet/tablet_empty_state.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/tablet/tablet_invoice_content.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/tablet/tablet_summary_panel.dart';

class TabletBody extends StatelessWidget {
  const TabletBody({
    super.key,
    required this.cart,
    required this.isPendingApproval,
    required this.isPaymentMode,
    required this.invoiceError,
    required this.onPayPressed,
    required this.onBackToInvoice,
    required this.onCancelPendingDiscount,
    required this.onConfirmPayment,
    required this.onShowCalculation,
    required this.onEditDiscount,
    required this.onRemove,
    required this.onOpenScanner,
    required this.onOpenManualCode,
    required this.onOpenTradeIn,
  });

  final GoldSaleCart cart;
  final bool isPendingApproval;
  final bool isPaymentMode;
  final InvoiceError? invoiceError;

  final VoidCallback onPayPressed;
  final VoidCallback onBackToInvoice;
  final VoidCallback onCancelPendingDiscount;
  final Future<void> Function(List<GoldSalePayment>) onConfirmPayment;

  final ValueChanged<int> onShowCalculation;
  final VoidCallback onEditDiscount;
  final ValueChanged<String> onRemove;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenManualCode;
  final VoidCallback onOpenTradeIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? TabletEmptyState(
                    openScanner: onOpenScanner,
                    openManualCode: onOpenManualCode,
                  )
                : TabletInvoiceContent(
                    cart: cart,
                    isPendingApproval: isPendingApproval,
                    invoiceError: invoiceError,
                    onShowCalculation: onShowCalculation,
                    onEditDiscount: onEditDiscount,
                    onRemove: onRemove,
                    onOpenScanner: onOpenScanner,
                    onOpenTradeIn: onOpenTradeIn,
                  ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 330,
            child: TabletSummaryPanel(
              cart: cart,
              isPendingApproval: isPendingApproval,
              isPaymentMode: isPaymentMode,
              onPayPressed: onPayPressed,
              onBackToInvoice: onBackToInvoice,
              onCancelPendingDiscount: onCancelPendingDiscount,
              onConfirmPayment: onConfirmPayment,
            ),
          ),
        ],
      ),
    );
  }
}
