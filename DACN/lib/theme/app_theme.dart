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
    scaffoldBackgroundColor: const Color(0xFF0A1929), // Deeper ocean-inspired background
    primaryColor: AppColors.oceanBlue,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.oceanBlue,
      surface: Color(0xFF1A2332), // Slightly lighter surface for cards
      onPrimary: Colors.white,
      onSurface: Color(0xFFE8EDF1), // Mist color for better readability
      secondary: AppColors.skyBlue,
      onSecondary: Colors.white,
      error: Color(0xFFFF6B6B), // Softer red for errors
      onError: Colors.white,
      surfaceContainerHighest: Color(0xFF233044), // For elevated surfaces
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A2332),
      foregroundColor: Color(0xFFE8EDF1),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFE8EDF1)),
      bodySmall: TextStyle(color: Color(0xFFB0B7C3)), // Lighter for secondary text
      titleMedium: TextStyle(color: Color(0xFFE8EDF1)),
      headlineSmall: TextStyle(color: Color(0xFFE8EDF1)),
    ),
    cardColor: const Color(0xFF1A2332),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A2332),
      hintStyle: const TextStyle(color: Color(0xFFB0B7C3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.oceanBlue.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.oceanBlue.withOpacity(0.3)),
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
        elevation: 2,
        shadowColor: AppColors.oceanBlue.withOpacity(0.3),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.skyBlue),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A2332),
      selectedItemColor: AppColors.oceanBlue,
      unselectedItemColor: Color(0xFFB0B7C3),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF1A2332),
      textStyle: TextStyle(color: Color(0xFFE8EDF1)),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: Color(0xFFE8EDF1)),
    ),
  );
}


