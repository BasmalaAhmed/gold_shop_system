import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_payment_method.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/tablet/summary_row.dart';

class TabletSummaryPanel extends StatefulWidget {
  const TabletSummaryPanel({
    super.key,
    required this.cart,
    required this.isPendingApproval,
    required this.isPaymentMode,
    required this.onPayPressed,
    required this.onBackToInvoice,
    required this.onCancelPendingDiscount,
    required this.onConfirmPayment,
  });

  final GoldSaleCart cart;
  final bool isPendingApproval;
  final bool isPaymentMode;
  final VoidCallback onPayPressed;
  final VoidCallback onBackToInvoice;
  final VoidCallback onCancelPendingDiscount;
  final Future<void> Function(List<GoldSalePayment> payments) onConfirmPayment;

  @override
  State<TabletSummaryPanel> createState() => _TabletSummaryPanelState();
}

class _TabletSummaryPanelState extends State<TabletSummaryPanel> {
  late TextEditingController _cashController;
  int _cashPaidPiasters = 0;
  GoldSalePaymentMethod _secondaryMethod = GoldSalePaymentMethod.other;

  final Map<GoldSalePaymentMethod, String> _methodLabels = {
    GoldSalePaymentMethod.other: 'إنستاباي',
    GoldSalePaymentMethod.mobileWallet: 'فودافون كاش',
    GoldSalePaymentMethod.card: 'كارت',
    GoldSalePaymentMethod.bankTransfer: 'تحويل',
  };

  @override
  void initState() {
    super.initState();
    _resetPaymentState();
  }

  @override
  void didUpdateWidget(covariant TabletSummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaymentMode && !oldWidget.isPaymentMode) {
      _resetPaymentState();
    }
  }

  void _resetPaymentState() {
    final due = widget.cart.amountDuePiasters;
    _cashPaidPiasters = due > 500000 ? 500000 : due;
    _cashController = TextEditingController(
      text: (_cashPaidPiasters / 100.0).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  int get _remainingPiasters =>
      (widget.cart.amountDuePiasters - _cashPaidPiasters).clamp(
        0,
        widget.cart.amountDuePiasters,
      );

  bool _isSubmitting = false;

  Future<void> _submitPayment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final payments = <GoldSalePayment>[];

    try {
      if (_cashPaidPiasters > 0) {
        payments.add(
          GoldSalePayment(
            method: GoldSalePaymentMethod.cash,
            amountPiasters: _cashPaidPiasters,
          ),
        );
      }
      if (_remainingPiasters > 0) {
        payments.add(
          GoldSalePayment(
            method: _secondaryMethod,
            amountPiasters: _remainingPiasters,
          ),
        );
      }
      await widget.onConfirmPayment(payments);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      padding: const EdgeInsets.all(20),
      child: widget.isPaymentMode ? _buildPaymentView() : _buildSummaryView(),
    );
  }

  Widget _buildSummaryView() {
    final lineResults = widget.cart.lineResults;
    final int itemsCount = widget.cart.items.length;
    final int totalDiscountPiasters = lineResults.fold(
      0,
      (sum, r) => sum + r.discountPiasters,
    );
    final int totalTaxPiasters = lineResults.fold(
      0,
      (sum, r) => sum + r.taxPiasters,
    );

    final totalEgp = (widget.cart.totalPiasters / 100.0).toStringAsFixed(2);
    final tradeInValueEgp = (widget.cart.tradeInValuePiasters / 100.0)
        .toStringAsFixed(2);
    final amountDueEgp = (widget.cart.amountDuePiasters / 100.0)
        .toStringAsFixed(2);
    final discountEgp = (totalDiscountPiasters / 100.0).toStringAsFixed(2);
    final taxEgp = (totalTaxPiasters / 100.0).toStringAsFixed(2);

    final bool isEmpty = itemsCount == 0;
    final bool hasTradeIn = widget.cart.tradeIn != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ملخص الفاتورة',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),

        if (isEmpty) ...[
          SummaryRow(label: 'القطع', value: '0 من 2'),
        ] else if (hasTradeIn) ...[
          SummaryRow(label: 'القطع', value: totalEgp),
          const SizedBox(height: 12),
          SummaryRow(
            label: 'البدل (يُخصم)',
            value: tradeInValueEgp,
            isGreen: true,
          ),
        ] else ...[
          SummaryRow(label: 'القطع', value: '$itemsCount من 2'),
          const SizedBox(height: 12),
          SummaryRow(
            label: 'الخصم على المصنعية',
            value: widget.isPendingApproval
                ? '$discountEgp (بانتظار)'
                : discountEgp,
            isGreen: !widget.isPendingApproval,
            isAmber: widget.isPendingApproval,
          ),
          const SizedBox(height: 12),
          SummaryRow(label: 'الضريبة', value: taxEgp),
        ],

        const Spacer(),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasTradeIn ? '$amountDueEgp ج.م' : '$totalEgp ج.م',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              hasTradeIn ? 'المستحق' : 'الإجمالي',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: (isEmpty || widget.isPendingApproval)
                ? null
                : widget.onPayPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: (isEmpty || widget.isPendingApproval)
                  ? const Color(0xFF94A3B8)
                  : AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              widget.isPendingApproval ? 'الدفع (بعد الموافقة)' : 'الدفع',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        if (widget.isPendingApproval) ...[
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: widget.onCancelPendingDiscount,
              child: const Text(
                'إلغاء الطلب والرجوع إلى 10%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.redText,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentView() {
    final amountDueEgp = (widget.cart.amountDuePiasters / 100.0)
        .toStringAsFixed(2);
    final remainingEgp = (_remainingPiasters / 100.0).toStringAsFixed(2);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الدفع',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'كاش',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _cashController,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              final valD =
                  double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
              setState(() {
                _cashPaidPiasters = (valD * 100).round();
              });
            },
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 10, top: 12),
                child: Text(
                  'ج.م',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
              suffixIcon: const Icon(
                Icons.payments_outlined,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.primaryTeal,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildChip('2,000', 200000),
              const SizedBox(width: 6),
              _buildChip('5,000', 500000),
              const SizedBox(width: 6),
              _buildChip('الكل كاش', widget.cart.amountDuePiasters),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'الباقي $remainingEgp يُدفع بـ:',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),

          Row(
            children: _methodLabels.entries.toList().reversed.map((entry) {
              final isSelected = _secondaryMethod == entry.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _secondaryMethod = entry.key),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryTeal : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : AppTheme.borderSubtle,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0.00 ج.م',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.greenText,
                  ),
                ),
                Text(
                  'المتبقي',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.greenText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$amountDueEgp ج.م',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Text(
                'المطلوب',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitPayment,
              icon: const Icon(Icons.check, size: 18),
              label: const Text(
                'تأكيد وتسجيل الفاتورة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Center(
            child: TextButton(
              onPressed: widget.onBackToInvoice,
              child: const Text(
                'رجوع للفاتورة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int valPiasters) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _cashPaidPiasters = valPiasters.clamp(
            0,
            widget.cart.amountDuePiasters,
          );
          _cashController.text = (_cashPaidPiasters / 100.0).toStringAsFixed(2);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
