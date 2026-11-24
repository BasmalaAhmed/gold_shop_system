import 'package:flutter/material.dart';

class DeviceInfo extends StatelessWidget {
  const DeviceInfo({super.key, required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFF0D9488).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.laptop_windows_outlined,
            color: Color(0xFF0D9488),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'جهاز جديد',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  deviceName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}