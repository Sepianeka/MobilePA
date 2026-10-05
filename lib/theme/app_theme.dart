import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna mengikuti DESIGN.md dari Stitch.
class AppColors {
  static const primary = Color(0xFF1E3A8A);
  static const teal = Color(0xFF14B8A6);
  static const tealDark = Color(0xFF0F766E);
  static const tealSoft = Color(0xFFCCFBF1);
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFFECFDF5);
  static const successText = Color(0xFF047857);
  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0xFFFEF2F2);
  static const dangerText = Color(0xFFB91C1C);
  static const bg = Color(0xFFF8FAFC);
  static const recessed = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const hint = Color(0xFF94A3B8);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.teal,
    error: AppColors.danger,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
  );
  OutlineInputBorder border(Color c, [double w = 0]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
      );
  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.recessed,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.hint),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(AppColors.teal, 2),
      errorBorder: border(AppColors.danger, 1.5),
      focusedErrorBorder: border(AppColors.danger, 2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withOpacity(0.12),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
