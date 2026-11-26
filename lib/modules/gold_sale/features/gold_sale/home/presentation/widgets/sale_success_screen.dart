import 'package:flutter/material.dart';
import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';

class SaleSuccessScreen extends StatelessWidget {
  const SaleSuccessScreen({
    super.key,
    required this.amountDuePiasters,
    required this.cashPaidPiasters,
    required this.secondaryPaidPiasters,
    required this.secondaryMethodName,
    required this.goldPricePiasters,
    required this.onNewInvoice,
    this.invoiceNumber = 'INV-2026-01842',
  });

  final int amountDuePiasters;
  final int cashPaidPiasters;
  final int secondaryPaidPiasters;
  final String secondaryMethodName;
  final int goldPricePiasters;
  final VoidCallback onNewInvoice;
  final String invoiceNumber;

  void _handleNewInvoice(BuildContext context) {
    Navigator.of(context).pop();
    onNewInvoice();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 720;
    final amountDueEgp = PriceFormatter.formatPiasters(amountDuePiasters);
    final cashPaidEgp = PriceFormatter.formatPiasters(cashPaidPiasters);
    final secondaryPaidEgp = PriceFormatter.formatPiasters(
      secondaryPaidPiasters,
    );
    final goldPriceEgp = PriceFormatter.formatPiasters(goldPricePiasters);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleNewInvoice(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isTablet ? 'فاتورة بيع · فرع المهندسين' : 'فاتورة بيع',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 24),
            onPressed: () => _handleNewInvoice(context),
          ),
          actions: isTablet
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: UnifiedTheme.emerald,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'سعر جرام 21 المثبّت: $goldPriceEgp ج.م',
                          style: const TextStyle(
                            color: UnifiedTheme.emerald,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: isTablet
              ? _buildTabletSuccess(
                  context: context,
                  amountDueEgp: amountDueEgp,
                  cashPaidEgp: cashPaidEgp,
                  secondaryPaidEgp: secondaryPaidEgp,
                  goldPriceEgp: goldPriceEgp,
                )
              : _buildMobileSuccess(
                  amountDueEgp: amountDueEgp,
                  cashPaidEgp: cashPaidEgp,
                  secondaryPaidEgp: secondaryPaidEgp,
                  goldPriceEgp: goldPriceEgp,
                  context: context,
                ),
        ),
      ),
    );
  }

  Widget _buildTabletSuccess({
    required String amountDueEgp,
    required String cashPaidEgp,
    required String secondaryPaidEgp,
    required String goldPriceEgp,
    required BuildContext context,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF0F766E),
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'تم تسجيل الفاتورة',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'المستحق $amountDueEgp · كاش $cashPaidEgp · $secondaryMethodName $secondaryPaidEgp · سعر 21 ثابت $goldPriceEgp · $invoiceNumber',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: UnifiedTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 240,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleNewInvoice(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'فاتورة جديدة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: UnifiedTheme.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSuccess({
    required String amountDueEgp,
    required String cashPaidEgp,
    required String secondaryPaidEgp,
    required String goldPriceEgp,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F7F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF0F766E),
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'تم تسجيل الفاتورة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              invoiceNumber,
              style: const TextStyle(
                fontSize: 14,
                color: UnifiedTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: UnifiedTheme.border),
            ),
            child: Column(
              children: [
                _buildRow('المستحق', '$amountDueEgp ج.م', isBold: true),
                const SizedBox(height: 14),
                _buildRow('كاش', cashPaidEgp),
                if (secondaryPaidPiasters > 0) ...[
                  const SizedBox(height: 14),
                  _buildRow(secondaryMethodName, secondaryPaidEgp),
                ],
                const SizedBox(height: 14),
                _buildRow('سعر جرام 21 في المستند', '$goldPriceEgp ج.م (ثابت)'),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _handleNewInvoice(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'فاتورة جديدة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UnifiedTheme.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: UnifiedTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
