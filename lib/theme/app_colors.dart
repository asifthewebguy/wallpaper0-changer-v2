import 'package:flutter/material.dart';

abstract final class AppColors {
  // Base surfaces
  static const Color base = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF111118);
  static const Color surfaceAlt = Color(0xFF0D0D14);
  static const Color card = Color(0xFF1A1A2E);
  static const Color border = Color(0xFF1E1E2E);
  static const Color borderAlt = Color(0xFF2A2A4A);

  // Accents
  static const Color primary = Color(0xFF6366F1);   // indigo
  static const Color secondary = Color(0xFFA855F7); // purple
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF4A4A6A);
}
