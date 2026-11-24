import 'package:flutter/material.dart';

class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    required this.label,
    required this.amount,
    this.bold = false,
  });

  final String label;
  final int amount;
  final bool bold;

  String _formatPiasters(int amount) {
    final pounds = amount ~/ 100;
    final piasters = (amount % 100).toString().padLeft(2, '0');
    return '$pounds.$piasters ج.م';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
            ),
          ),
          Text(
            _formatPiasters(amount),
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}
