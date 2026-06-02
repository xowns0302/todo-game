import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF3B82F6);
  static const background = Color(0xFFF0F4F8);
  static const card = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF1E293B);
  static const muted = Color(0xFFF1F5F9);
  static const mutedForeground = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const destructive = Color(0xFFEF4444);
  static const secondary = Color(0xFFE0E7FF);
}

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.card,
  ),
  scaffoldBackgroundColor: AppColors.background,
  cardTheme: const CardThemeData(
    color: AppColors.card,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);
