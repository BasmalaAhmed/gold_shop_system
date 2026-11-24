import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/core/utils/price_formatter.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_calc.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/domain/gold_sale_cart.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/option_tab.dart';

class DiscountBottomSheet extends StatefulWidget {
  const DiscountBottomSheet({
    super.key,
    required this.currentDiscountPercent,
    required this.cart,
    required this.onApply,
    this.isDialog = false,
  });

  final int currentDiscountPercent;
  final GoldSaleCart cart;
  final Function(int discountPercent, String? approvalNumber) onApply;
  final bool isDialog;

  static void show(
    BuildContext context, {
    required int currentDiscountPercent,
    required GoldSaleCart cart,
    required Function(int discountPercent, String? approvalNumber) onApply,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 720;
    if (isTablet) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: DiscountBottomSheet(
              currentDiscountPercent: currentDiscountPercent,
              cart: cart,
              onApply: onApply,
              isDialog: true,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DiscountBottomSheet(
          currentDiscountPercent: currentDiscountPercent,
          cart: cart,
          onApply: onApply,
          isDialog: false,
        ),
      );
    }
  }

  @override
  State<DiscountBottomSheet> createState() => _DiscountBottomSheetState();
}

class _DiscountBottomSheetState extends State<DiscountBottomSheet> {
  late int _selectedPercent;
  bool _isCustomMore = false;

  @override
  void initState() {
    super.initState();
    _selectedPercent = widget.currentDiscountPercent;
    if (_selectedPercent > 10) {
      _isCustomMore = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    const calc = GoldSaleCalc();
    int simulatedTotalDiscountPiasters = 0;
    int simulatedTotalPiasters = 0;

    for (final item in widget.cart.items) {
      final res = calc.calculate(
        item.input,
        discountPercent: _selectedPercent,
        supervisorApprovalNumber: _selectedPercent > 10 ? 'MGR-APP' : null,
      );
      simulatedTotalDiscountPiasters += res.discountPiasters;
      simulatedTotalPiasters += res.totalPiasters;
    }

    final discountEgp = PriceFormatter.formatPiasters(
      simulatedTotalDiscountPiasters,
    );

    final totalAfterDiscountEgp = PriceFormatter.formatPiasters(
      simulatedTotalPiasters,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isDialog) ...[
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'خصم على المصنعية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              OptionTab(label: '0%', isSelected: !_isCustomMore && _selectedPercent == 0, onTap: () {
                  setState(() {
                    _isCustomMore = false;
                    _selectedPercent = 0;
                  });
                }),
              const SizedBox(width: 8),
              OptionTab(label: '5%', isSelected: !_isCustomMore && _selectedPercent == 5, onTap: () {
                  setState(() {
                    _isCustomMore = false;
                    _selectedPercent = 5;
                  });
                }),
              const SizedBox(width: 8),
              OptionTab(label: '10%', isSelected: !_isCustomMore && _selectedPercent == 10, onTap: () {
                  setState(() {
                    _isCustomMore = false;
                    _selectedPercent = 10;
                  });
                }),

              const SizedBox(width: 8),

              OptionTab(label: 'أكثر', isSelected: _isCustomMore, onTap: () {
                  setState(() {
                    _isCustomMore = true;
                    _selectedPercent = 15;
                  });
                }),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الخصم',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '$discountEgp ج.م',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.greenText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إجمالي الحساب بعد الخصم',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$totalAfterDiscountEgp ج.م',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'حق 10% بدون موافقة، أكثر يرسل طلبًا لصاحب المحل.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final approval = _selectedPercent > 10 ? 'MGR-APP' : null;
                widget.onApply(_selectedPercent, approval);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'تطبيق',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


