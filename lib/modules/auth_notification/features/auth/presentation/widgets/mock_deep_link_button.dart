import 'package:flutter/material.dart';

class MockDeepLinkButton extends StatelessWidget {
  const MockDeepLinkButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.notifications_active_outlined),
        label: const Text('محاكاة إشعار الموافقة'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0D9488),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}