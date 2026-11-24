import 'package:flutter/material.dart';

class IconWidget extends StatelessWidget {
  const IconWidget({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: Color(0xFF0D9488).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          size: 38,
          color: Color(0xFF0D9488),
        ),
      ),
    );
  }
}
