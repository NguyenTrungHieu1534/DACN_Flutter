import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MusicLoginApp());
}

class MusicLoginApp extends StatelessWidget {
  const MusicLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.oceanBlue,
        primary: AppColors.oceanBlue,
        secondary: AppColors.skyBlue,
        background: AppColors.mist,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wave Music',
      theme: AppTheme.buildTheme(base),
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}




