import 'package:flutter/material.dart';
import 'package:gold_shop_app/modules/gold_sale/core/theme/app_theme.dart';

class MoreButton extends StatelessWidget {
  const MoreButton({
    super.key,
    required this.onSaveDraft,
    required this.onDeleteInvoice,
  });

  final Future<bool> Function() onSaveDraft;
  final VoidCallback onDeleteInvoice;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Icon(
          Icons.more_vert,
          color: AppTheme.textPrimary,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 44),
      onSelected: (value) async {
        if (value == 'draft') {
          final isSaved = await onSaveDraft();

          if (isSaved && context.mounted) {
            Navigator.pop(context);
          }
        } else if (value == 'delete') {
          onDeleteInvoice();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'draft',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حفظ كمسودة والخروج',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Icon(
                Icons.description_outlined,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'حذف الفاتورة',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.redText,
                ),
              ),
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppTheme.redText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
