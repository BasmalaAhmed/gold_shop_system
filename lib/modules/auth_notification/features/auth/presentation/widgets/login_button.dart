import 'package:flutter/material.dart';
import 'package:gold_shop_app/core/unified_theme.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: UnifiedTheme.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0xFF1E293B).withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'سجل دخول',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),

                  SizedBox(width: 10),

                  Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    );
  }
}
