import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Teal
  static const Color primaryTeal = Color(0xFF0F5156);
  static const Color primaryTealDark = Color(0xFF0A3C40);
  static const Color primaryTealLight = Color(0xFFE8F3F4);
  static const Color primaryTealSubtle = Color(0xFFF0F7F7);

  // Backgrounds & Surfaces
  static const Color scaffoldBackground = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // Status Badges & Banners
  // Offline
  static const Color offlineDark = Color(0xFF1E293B);
  static const Color offlineBadgeText = Colors.white;

  // Synced / Success (Green)
  static const Color syncedBg = Color(0xFFECFDF5);
  static const Color syncedText = Color(0xFF047857);
  static const Color syncedBorder = Color(0xFFA7F3D0);
  static const Color syncedIcon = Color(0xFF059669);

  // Syncing / In Progress (Blue)
  static const Color syncingBg = Color(0xFFEFF6FF);
  static const Color syncingText = Color(0xFF1D4ED8);
  static const Color syncingBorder = Color(0xFFBFDBFE);

  // Pending / On Device / Attention (Orange)
  static const Color pendingNoticeBg = Color(0xFFFFF7ED);
  static const Color pendingNoticeText = Color(0xFFC2410C);
  static const Color pendingNoticeBorder = Color(0xFFFED7AA);

  // Conflict / Error (Red)
  static const Color conflictBg = Color(0xFFFEF2F2);
  static const Color conflictText = Color(0xFFDC2626);
  static const Color conflictBorder = Color(0xFFFCA5A5);
  static const Color conflictButtonBg = Color(0xFFB91C1C);

  // Numeric Keypad
  static const Color keypadBackground = Color(0xFFFFFFFF);
  static const Color keyBackground = Color(0xFFF1F3F5);
  static const Color keyText = Color(0xFF1E293B);

  // Quick Amount Chips
  static const Color chipBackground = Color(0xFFE0F2FE);
  static const Color chipText = Color(0xFF0369A1);
  static const Color chipBorder = Color(0xFFBAE6FD);

  // Buttons
  static const Color buttonDisabled = Color(0xFF8B9CA7);
}
