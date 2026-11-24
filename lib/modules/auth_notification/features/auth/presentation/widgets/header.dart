import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Color(0xFF0D9488).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.lock_person_rounded,
            size: 38,
            color: Color(0xFF0D9488),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'مرحبا بك!',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'ادخل بياناتك لتسجيل دخولك',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
