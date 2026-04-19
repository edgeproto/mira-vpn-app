import 'package:flutter/material.dart';

/// Brand palette (teal-forward, distinct from typical cyan “VPN” accents).
abstract final class AppColors {
  /// Primary brand — deep teal.
  static const Color brandPrimary = Color(0xFF0F766E);

  /// Secondary accent — cooler teal for highlights.
  static const Color brandSecondary = Color(0xFF0D9488);

  static const Color statusOk = Color(0xFF059669);
  static const Color statusWarn = Color(0xFFD97706);
  static const Color statusOff = Color(0xFF94A3B8);
}
