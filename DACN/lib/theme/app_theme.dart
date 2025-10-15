import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Retro palette from home_screen.dart
  static const Color retroPrimary = Color(0xFF76B5FF); // Sky Blue primary
  static const Color retroAccent = Color(0xFF247BA0); // Dark blue
  static const Color retroPeach = Color(0xFFFFB6B9); // Pastel pink
  static const Color retroSand = Color(0xFFFFE066); // Sand yellow
  static const Color retroWhite = Color(0xFFFFFFFF);
}

class AppTheme {
  AppTheme._();

  static final retroBoxGradient = LinearGradient(
    colors: [
      AppColors.retroPrimary.withOpacity(0.25),
      AppColors.retroAccent.withOpacity(0.15),
    ],
  );

  static final retroShadow = [
    BoxShadow(
      color: AppColors.retroPrimary.withOpacity(0.25),
      blurRadius: 12,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData buildTheme(ThemeData base) {
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.retroWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.retroPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: AppColors.retroPrimary.withOpacity(0.55)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.retroAccent.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.retroAccent.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.retroAccent, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.retroAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.retroAccent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.retroPrimary,
        secondary: AppColors.retroAccent,
      ),
    );
  }
}


