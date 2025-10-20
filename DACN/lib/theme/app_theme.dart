import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Refined ocean-inspired palette
  static const Color oceanDeep = Color(0xFF072B52); // deeper navy
  static const Color oceanBlue = Color(0xFF145A96); // richer primary blue
  static const Color skyBlue = Color(0xFF3AA2D6); // slightly darker accent sky
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

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1117),
    primaryColor: const Color(0xFF1DB954),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1DB954),
      surface: Color(0xFF161B22),
      background: Color(0xFF0D1117),
      onPrimary: Colors.white,
      onSurface: Colors.white70,
      onBackground: Colors.white70,
      secondary: AppColors.oceanBlue,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161B22),
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    cardColor: const Color(0xFF161B22),
  );
}


