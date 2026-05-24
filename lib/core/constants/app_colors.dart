import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF3BA38B);
  static const Color primaryDark = Color(0xFF2D8A74);
  static const Color primaryLight = Color(0xFF5BBDA6);
  static const Color primarySurface = Color(0xFFE8F5F2);
  static const Color primarySurfaceDeep = Color(0xFFD1ECE5);

  // Backgrounds
  static const Color background = Color(0xFFF0F4F3);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFDBEAFE);

  // UI Accents
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color cardShadow = Color(0x14000000);
  static const Color cardBorder = Color(0xFFEEF2F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3BA38B), Color(0xFF2D8A74)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF3BA38B), Color(0xFF1E6B5A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFFE8F5F2), Color(0xFFD1ECE5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumDarkGradient = LinearGradient(
    colors: [Color(0xFF08201D), Color(0xFF0F362F), Color(0xFF1E594E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
