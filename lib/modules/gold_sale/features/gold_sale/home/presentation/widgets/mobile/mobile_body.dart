import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';

import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/models/invoice_model.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/fixed_price_widget.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/mobile/mobile_bottom_bar.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/mobile/mobile_empty_state.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/mobile/mobile_invoice_content.dart';

class MobileBody extends StatelessWidget {
  const MobileBody({
    super.key,
    required this.cart,
    required this.goldPriceEgp,
    required this.isPendingApproval,
    required this.onRefreshPrices,
    required this.onOpenScanner,
    required this.onOpenManualCode,
    required this.onShowCalculation,
    required this.onEditDiscount,
    required this.onRemove,
    required this.onAddTradeIn,
    required this.onCancelPending,
    required this.onPay,
    this.invoiceError,
  });

  final GoldSaleCart cart;
  final double goldPriceEgp;
  final bool isPendingApproval;
  final InvoiceError? invoiceError;
  final VoidCallback onRefreshPrices;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenManualCode;
  final ValueChanged<int> onShowCalculation;
  final VoidCallback onEditDiscount;
  final ValueChanged<String> onRemove;
  final VoidCallback onAddTradeIn;
  final VoidCallback onCancelPending;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          FixedPriceWidget(
            price: goldPriceEgp,
            karat: 21,
            onRefresh: onRefreshPrices,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: cart.items.isEmpty && invoiceError == null
                ? MobileEmptyState(
                    openScanner: onOpenScanner,
                    openManualCode: onOpenManualCode,
                  )
                : MobileInvoiceContent(
                    cart: cart,
                    isPendingApproval: isPendingApproval,
                    onShowCalculation: onShowCalculation,
                    onEditDiscount: onEditDiscount,
                    onRemove: onRemove,
                    onAddItem: onOpenScanner,
                    onAddTradeIn: onAddTradeIn,
                    invoiceError: invoiceError,
                  ),
          ),
          if (cart.items.isNotEmpty)
            MobileBottomBar(
              totalEgp: PriceFormatter.formatPiasters(cart.totalPiasters),
              tradeInValueEgp: PriceFormatter.formatPiasters(
                cart.tradeInValuePiasters,
              ),
              amountDueEgp: PriceFormatter.formatPiasters(
                cart.amountDuePiasters,
              ),
              hasTradeIn: cart.tradeIn != null,
              isPendingApproval: isPendingApproval,
              onCancelPending: onCancelPending,
              onPay: onPay,
            ),
        ],
      ),
    );
  }
}
