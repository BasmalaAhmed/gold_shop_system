import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeTextField extends StatelessWidget {
  const CodeTextField({super.key, required this.codeController, required this.isLoading});

  final TextEditingController codeController;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: codeController,
      enabled: !isLoading,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.center,
      maxLength: 6,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 14,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), letterSpacing: 8),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'من فضلك أدخل رمز التحقق';
        }

        if (value.length != 6) {
          return 'يجب أن يحتوي الرمز على 6 أرقام';
        }

        return null;
      },
    );
  }
}
