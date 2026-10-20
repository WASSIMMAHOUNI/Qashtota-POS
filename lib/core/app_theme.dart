import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const cream = Color(0xFFEFF4FB);
  static const creamDark = Color(0xFFDDEAF6);
  static const creamMedium = Color(0xFFC2D7EE);
  static const gold = Color(0xFF2A7DE1);
  static const goldLight = Color(0xFF5599E8);
  static const goldDark = Color(0xFF1A5FB8);
  static const brown = Color(0xFF1A3A6B);
  static const brownLight = Color(0xFF2952A3);
  static const textDark = Color(0xFF0D1F3C);
  static const textMedium = Color(0xFF2C4A72);
  static const textLight = Color(0xFF6B8DB5);
  static const sidebarBg = Color(0xFF0D1F3C);
  static const sidebarAccent = Color(0xFF162E54);
  static const success = Color(0xFF4CAF7D);
  static const danger = Color(0xFFE57373);
  static const warning = Color(0xFFFFB74D);
  static const info = Color(0xFF64B5F6);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    final arabicTextTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.gold),
      textTheme: arabicTextTheme,
      primaryTextTheme: arabicTextTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
      ),
    );
  }
}
