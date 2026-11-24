import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/scan_barcode_widget.dart';

class TabletEmptyState extends StatelessWidget {
  const TabletEmptyState({super.key, required this.openScanner, required this.openManualCode});

  final VoidCallback openScanner;
  final VoidCallback openManualCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ScanBarcodeWidget(),
            const SizedBox(height: 32),
            SizedBox(
              width: 260,
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
            const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}