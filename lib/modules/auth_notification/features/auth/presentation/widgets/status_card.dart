import 'package:gold_shop_app/modules/auth_notification/features/auth/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.isSessionValid});

  final bool isSessionValid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF0D9488),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة المصادقة',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'مُوَثَّق',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          StatusBadge(
            label: isSessionValid ? 'نشط' : 'منتهي',
            isActive: isSessionValid,
          ),
        ],
      ),
    );
  }
}
