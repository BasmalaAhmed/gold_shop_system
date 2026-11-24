import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/fixed_price_widget.dart';
import 'package:gold_shop_app/modules/gold_sale/features/gold_sale/home/presentation/widgets/more_button.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.isTablet,
    required this.goldPriceEgp,
    required this.buyPriceEgp,
    required this.lastSavedAt,
    required this.onRefresh,
    required this.onSaveDraft,
    required this.onDeleteInvoice,
  });

  final bool isTablet;
  final double goldPriceEgp;
  final double buyPriceEgp;
  final DateTime? lastSavedAt;
  final VoidCallback onRefresh;
  final VoidCallback onDeleteInvoice;
  final Future<bool> Function() onSaveDraft;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      title: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          isTablet ? 'فاتورة بيع · فرع المهندسين' : 'فاتورة بيع',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          lastSavedAt == null
              ? 'مسودة · لم يتم الحفظ بعد'
              : 'مسودة · حُفظت ${TimeOfDay.fromDateTime(lastSavedAt!.toLocal()).format(context)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppTheme.greenText,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () async {
          final isSaved = await onSaveDraft();

          if (isSaved && context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        if (isTablet)
          FixedPriceWidget(
            price: goldPriceEgp,
            buyPrice: buyPriceEgp,
            karat: 21,
            showBuyPrice: true,
            onRefresh: onRefresh,
          ),
        MoreButton(onSaveDraft: onSaveDraft, onDeleteInvoice: onDeleteInvoice),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
