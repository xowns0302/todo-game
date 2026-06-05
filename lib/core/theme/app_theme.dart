import 'package:flutter/material.dart';

class AppColors {
  // ── Dark Dungeon Palette ──────────────────────────────────────
  static const background = Color(0xFF1A1D24);
  static const card = Color(0xFF252A34);
  static const cardElevated = Color(0xFF2D3444);
  static const foreground = Color(0xFFF8FAFC);
  static const muted = Color(0xFF2D3444);
  static const mutedForeground = Color(0xFF94A3B8);
  static const border = Color(0xFF3D4456);
  static const primary = Color(0xFF1D8BE6);    // Neon blue (retro border)
  static const secondary = Color(0xFF1E2A3D);
  static const destructive = Color(0xFFEF4444);
  static const gold = Color(0xFFFFC107);        // Warm gold
  static const complete = Color(0xFF10B981);    // Neon emerald (HP)
  static const neonBlue = Color(0xFF06B6D4);   // Neon teal (XP)
  static const goldBorder = Color(0xFFD4AF37); // Antique gold border
}

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    surface: AppColors.card,
  ),
  scaffoldBackgroundColor: AppColors.background,

  cardTheme: const CardThemeData(
    color: AppColors.card,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      side: BorderSide(color: AppColors.primary, width: 2),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.card,
    foregroundColor: AppColors.foreground,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  tabBarTheme: const TabBarTheme(
    labelColor: AppColors.gold,
    unselectedLabelColor: AppColors.mutedForeground,
    indicatorColor: AppColors.gold,
    dividerColor: AppColors.border,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 6,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.cardElevated,
    contentTextStyle: const TextStyle(color: AppColors.foreground),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardElevated,
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
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColors.mutedForeground),
    hintStyle: const TextStyle(color: AppColors.mutedForeground),
  ),
);
