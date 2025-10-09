import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:music_login/screens/home_screen.dart';
import 'package:music_login/screens/login_screen.dart';
import 'package:music_login/screens/forgot_password_screen.dart';
import 'package:music_login/screens/verify_otp_screen.dart';
import 'package:music_login/screens/reset_password_screen.dart';
import 'package:music_login/screens/search_screen.dart';
import 'package:music_login/screens/fav_screen.dart';
import 'package:music_login/screens/user_screen.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const WaveMusicApp());
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
      home: const HomeScreen(),
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
    HomeScreen(key: ValueKey('home')),
    SearchScreen(key: ValueKey('search')),
    FavScreen(key: ValueKey('fav')),
    UserScreen(key: ValueKey('user')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildMacDock(),
    );
  }

  Widget _buildMacDock() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _dockItem(Icons.home, 0),
          _dockItem(Icons.search, 1),
          _dockItem(Icons.favorite, 2),
          _dockItem(Icons.person, 3),
        ],
      ),
    );
  }

  Widget _dockItem(IconData icon, int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: isActive ? 34 : 28,
          color: isActive ? Colors.blueAccent : Colors.grey[500],
        ),
      ),
    );
  }
}
