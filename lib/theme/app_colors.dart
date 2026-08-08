import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF33210D);
  static const Color background = Color(0xFFFCF9F8);
  static const Color splashBackground = Color(0xFFF8EDDD);
  static const Color appName = Color(0xFF4B3621); // Espresso
  static const Color espresso = Color(0xFF4B3621);
  static const Color textPrimary = Color(0xFF1B1C1C);
  static const Color textSecondary = Color(0xFF4E453D); // onSurfaceVariant
  // Muted text (hints, field labels, meta). Was 0xFF80756C, which sits at
  // 4.28:1 on `background` and fails WCAG AA for normal text (needs 4.5:1).
  // 0xFF6E645B measures 5.5:1, leaving headroom for the .withOpacity() calls
  // these are often wrapped in.
  static const Color placeholder = Color(0xFF6E645B);
  static const Color outline = Color(0xFF6E645B);
  // Decorative hairlines/borders only — no text sits on these, so the lighter
  // tone is fine here.
  static const Color outlineVariant = Color(0xFFD2C4BA);
  static const Color signUpLink = Color(0xFF4B3621);
  static const Color fieldLabel = Color(0xFF6E645B);
  static const Color greyLine = Color(0xFFD2C4BA);
  static const Color googleBorder = Color(0xFFD2C4BA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // New tokens for Dashboard
  static const Color primaryFixed = Color(0xFFFEDCBE);
  static const Color primaryContainer = Color(0xFF4B3621);
  static const Color primaryFixedDim = Color(0xFFE1C1A4);
}
