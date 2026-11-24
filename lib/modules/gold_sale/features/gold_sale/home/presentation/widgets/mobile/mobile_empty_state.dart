import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/scan_barcode_widget.dart';

class MobileEmptyState extends StatelessWidget {
  const MobileEmptyState({
    super.key,
    required this.openScanner,
    required this.openManualCode,
  });

  final VoidCallback openScanner;
  final VoidCallback openManualCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const ScanBarcodeWidget(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: openScanner,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
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
          onPressed: openManualCode,
          child: const Text(
            'إدخال الكود يدويًا',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTeal,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
