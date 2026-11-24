import 'package:flutter/material.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.waving_hand_rounded, color: Color(0xFFFBBF24), size: 32),
          SizedBox(height: 16),
          Text(
            'مرحبًا بعودتك!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "تمت المصادقة بنجاح.",
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
