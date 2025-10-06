import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ocean-inspired palette from the provided swatches
  static const Color oceanDeep = Color(0xFF083D77); // deep navy
  static const Color oceanBlue = Color(0xFF1B6CA8); // primary blue
  static const Color skyBlue = Color(0xFF4DB6E5); // accent sky
  static const Color mist = Color(0xFFE8EDF1); // very light gray
  static const Color sand = Color(0xFFC9B8A6); // warm sand
}

class AppTheme {
  AppTheme._();

  static ThemeData buildTheme(ThemeData base) {
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.mist,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.oceanDeep,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: AppColors.oceanDeep.withOpacity(0.55)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.oceanBlue.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.oceanBlue.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.oceanBlue, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.oceanBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.oceanBlue),
      ),
    );
  }
}


