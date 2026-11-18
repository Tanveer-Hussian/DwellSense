import 'dart:ui';

class AppColors {
  AppColors._();
 
  // Primary brand color (deep teal)
  static const Color primary = Color(0xFF006D77);
  static const Color primaryLight = Color(0xFF83C5BE);
  static const Color primaryDark = Color(0xFF004D55);
 
  // Accent / highlight
  static const Color accent = Color(0xFFE29578);
 
  // Semantic colors
  static const Color success = Color(0xFF2D9D5A);
  static const Color warning = Color(0xFFF4A261);
  static const Color error = Color(0xFFE63946);
  static const Color info = Color(0xFF4895EF);
  // Neutral shades
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color divider = Color(0xFFE9ECEF);

  // Dark Mode neutral shades
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFF0F0F0);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkDivider = Color(0xFF2C2C2C);
  static const Color darkInputFill = Color(0xFF252525);

  // Status chip colors
  static const Color chipPending = Color(0xFFFFF3CD);
  static const Color chipApproved = Color(0xFFD4EDDA);
  static const Color chipRejected = Color(0xFFF8D7DA);
}
