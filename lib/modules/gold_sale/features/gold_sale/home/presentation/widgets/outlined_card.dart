import 'package:flutter/material.dart';
import 'package:gold_shop_app/core/unified_theme.dart';

class OutlinedCard extends StatelessWidget {
  const OutlinedCard({super.key, required this.title, required this.icon, required this.onTap});

  final String title;
    final IconData icon;
    final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: UnifiedTheme.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: UnifiedTheme.teal, size: 20),
             const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: UnifiedTheme.teal,
              ),
            ),
           
            
          ],
        ),
      ),
    );
  }
}