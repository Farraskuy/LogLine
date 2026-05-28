import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFDBEAFE);
  static const teal = Color(0xFF0D9488);
  static const tealSoft = Color(0xFFCCFBF1);
  static const coral = Color(0xFFF97316);
  static const coralSoft = Color(0xFFFFEDD5);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFEF3C7);
  static const ink = Color(0xFF0F172A);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7FAFC);
  static const camera = Color(0xFF080F1F);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme(),
      primaryTextTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
