import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:music_login/screens/home_screen.dart';
import 'package:music_login/screens/forgot_password_screen.dart';
import 'package:music_login/screens/verify_otp_screen.dart';
import 'package:music_login/screens/reset_password_screen.dart';
import 'package:music_login/screens/search_screen.dart';
import 'package:music_login/screens/fav_screen.dart';
import 'package:music_login/screens/user_screen.dart';
import 'models/AudioPlayerProvider.dart';
import 'theme/app_theme.dart';
import 'navigation/bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioPlayerProvider(),
      child: const WaveMusicApp(),
    ),
  );
}

class WaveMusicApp extends StatelessWidget {
  const WaveMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF8F9FB),
    );

    return MaterialApp(
      title: 'Wave Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(base),
      home: const MainNavigation(),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/verifyOTP': (context) => const VerifyOtpScreen(email: ''),
        '/resetPassword': (context) =>
            const ResetPasswordScreen(email: '', otp: ''),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    FavScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex, // Set the current index for IndexedStack
        children: _screens,
      ),
      bottomNavigationBar: BuildNaviBot(
          currentIndex: _currentIndex,
          onItemSelected: (index) {
            setState(() => _currentIndex = index);
          }),
    );
  }
}
