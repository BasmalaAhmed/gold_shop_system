import 'package:gold_shop_app/modules/debts_payment/core/formatters/egp_formatter.dart';
import 'package:flutter/material.dart';

class AvailableBalanceCard extends StatelessWidget {
  const AvailableBalanceCard({super.key, required this.availableAmount});

  final int availableAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0XFFCAD2C5),
      child: ListTile(
        title: const Text(
          'المتبقي المحلي',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'يشمل التحصيلات المحلية والمعلقة',
          style: TextStyle(fontSize: 14),
        ),
        trailing: Text(
          formatEgp(availableAmount),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
