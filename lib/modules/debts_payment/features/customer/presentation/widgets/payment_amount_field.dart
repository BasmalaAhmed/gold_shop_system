import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentAmountField extends StatelessWidget {
  const PaymentAmountField({
    super.key,
    required this.controller,
    this.errorMessage,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? errorMessage;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.right,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(
            labelText: 'مبلغ التحصيل بالجنيه',
            labelStyle: TextStyle(color: Colors.white),
            hintText: 'مثال: 1200 أو 1200.50',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFFD5F9DE))
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFFD5F9DE))
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0XFFD5F9DE))
            ),
          ),
          onChanged: onChanged,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
