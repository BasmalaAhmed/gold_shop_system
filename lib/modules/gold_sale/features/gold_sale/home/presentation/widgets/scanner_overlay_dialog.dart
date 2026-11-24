import 'package:flutter/material.dart';
import 'package:gold_shop_app/core/unified_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/data/gold_sale_demo_catalog.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_item_status.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_product.dart';

class ScannerOverlayDialog extends StatelessWidget {
  const ScannerOverlayDialog({
    super.key,
    required this.currentItemCodes,
    required this.onCodeSelected,
    required this.onManualInputSelected,
  });

  final List<String> currentItemCodes;
  final Function(String code) onCodeSelected;
  final VoidCallback onManualInputSelected;

  static Future<void> show(
    BuildContext context, {
    required List<String> currentItemCodes,
    required Function(String code) onCodeSelected,
    required VoidCallback onManualInputSelected,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerOverlayDialog(
          currentItemCodes: currentItemCodes,
          onCodeSelected: onCodeSelected,
          onManualInputSelected: onManualInputSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = GoldSaleDemoCatalog();
    final demoItems = [
      catalog.findByCode('DEMO-1001'),
      catalog.findByCode('DEMO-1002'),
      catalog.findByCode('DEMO-1003'),
      catalog.findByCode('G-1042'),
      catalog.findByCode('G-2207'),
      catalog.findByCode('G-1180'),
    ].whereType<GoldSaleProduct>().toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'مسح الباركود',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Container(
                        height: 2,
                        width: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'وجّه الكاميرا على الباركود',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'باركود تجريبي',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...demoItems.map((prod) {
                      final isAdded = currentItemCodes.any(
                        (c) => c.toUpperCase() == prod.code.toUpperCase(),
                      );
                      final isWorkshop =
                          prod.status == GoldItemStatus.inWorkshop;
                      final isReserved = prod.status == GoldItemStatus.reserved;
                      final isTransit = prod.status == GoldItemStatus.inTransit;

                      String subtitle;
                      if (isWorkshop) {
                        subtitle = 'في الورشة · لا تُباع';
                      } else if (isAdded) {
                        subtitle = 'مضافة في الفاتورة';
                      } else if (isReserved) {
                        subtitle = 'القطعة محجوزة او مباعة';
                      } else if (isTransit) {
                        subtitle = 'مضافة في الشحن';
                      } else {
                        subtitle = 'متاحة · ${prod.name} · عيار ${prod.karat}';
                      }

                      final isUnLocked =
                          prod.status == GoldItemStatus.available;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            onCodeSelected(prod.code);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: UnifiedTheme.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  color: isUnLocked
                                      ? UnifiedTheme.textPrimary
                                      : UnifiedTheme.textSecondary,
                                  size: 24,
                                ),

                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.code,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isUnLocked
                                            ? UnifiedTheme.textPrimary
                                            : UnifiedTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isUnLocked
                                            ? (isAdded
                                                  ? UnifiedTheme.teal
                                                  : UnifiedTheme.emerald)
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),

                                if (!isUnLocked)
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onManualInputSelected();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Center(
                          child: Text(
                            'إدخال الكود يدويًا',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: UnifiedTheme.teal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
