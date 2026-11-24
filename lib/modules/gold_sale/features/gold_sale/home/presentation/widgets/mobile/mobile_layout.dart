import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/fixed_price_widget.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/scan_barcode_widget.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({
    super.key,
    required this.refreshPrices,
    required this.onScanBarcode,
    required this.onManualCode,
    this.price = 4200.0,
    this.karat = 21,
  });

  final VoidCallback refreshPrices;
  final VoidCallback onScanBarcode;
  final VoidCallback onManualCode;
  final double price;
  final int karat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FixedPriceWidget(
          price: price,
          karat: karat,
          onRefresh: refreshPrices,
        ),
        const Spacer(),
        const ScanBarcodeWidget(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onScanBarcode,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0XFF0E5E6F),
              ),
              icon: const Icon(Icons.qr_code_scanner_outlined),
              label: const Text(
                'مسح باركود',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onManualCode,
          child: const Text(
            'إدخال الكود يدويًا',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0XFF0E5E6F),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
