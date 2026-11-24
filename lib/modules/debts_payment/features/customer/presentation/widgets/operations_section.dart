import 'package:gold_shop_app/modules/debts_payment/core/theme/app_styles.dart';
import 'package:gold_shop_app/modules/debts_payment/data/local/models/sync_operation.dart';
import 'package:gold_shop_app/modules/debts_payment/features/customer/presentation/widgets/sync_operation_card.dart';
import 'package:flutter/material.dart';

class OperationsSection extends StatelessWidget {
  const OperationsSection({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  final String title;
  final List<SyncOperation> items;
  final ValueChanged<SyncOperation>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(
            '$title (${items.length})',
            style: AppStyles.sectionHeader,
          ),
        ),
        for (final op in items)
          SyncOperationCard(
            operation: op,
            onTap: onItemTap != null ? () => onItemTap!(op) : null,
          ),
      ],
    );
  }
}
