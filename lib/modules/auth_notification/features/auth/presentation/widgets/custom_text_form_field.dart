import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.isLoading,
    this.isPassword = false,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool isPassword;
  final VoidCallback onSubmitted;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool isPasswordVisible;

  @override
  void initState() {
    super.initState();
    isPasswordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: !widget.isLoading,
      obscureText: widget.isPassword && !isPasswordVisible,
      textInputAction: widget.isPassword
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: (_) => widget.isLoading ? null : widget.onSubmitted,
      decoration:
          _inputDecoration(
            hint: widget.isPassword
                ? 'أدخل كلمة المرور'
                : 'أدخل البريد الالكتروني',
            icon: widget.isPassword
                ? Icons.lock_outline_rounded
                : Icons.email_outlined,
          ).copyWith(
            suffixIcon: widget.isPassword
                ? IconButton(
                    onPressed: widget.isLoading
                        ? null
                        : () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF94A3B8),
                    ),
                  )
                : null,
          ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return widget.isPassword
              ? 'من فضلك أدخل كلمة المرور.'
              : 'من فضلك أدخل البريد الالكتروني.';
        }

        if (!widget.isPassword) {
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value.trim())) {
            return 'من فضلك أدخل البريد الالكتروني صحيح.';
          }
        }

        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BAC7), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
