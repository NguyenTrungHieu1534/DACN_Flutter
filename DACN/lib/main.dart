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
import '../screens/library_screen.dart';
import '../screens/album_detail_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'services/network_check.dart';
import '../models/ThemeProvider.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
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
     final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
       debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),  // Light mode
      darkTheme: ThemeData.dark(), // Dark mode
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      title: 'Wave Music',
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
    LibraryScreen(),
    UserScreen(),
    FavScreen(),
  ];
  Stream<bool> get connectionStream async* {
    yield* Connectivity().onConnectivityChanged.asyncMap((status) async {
      if (status == ConnectivityResult.none) return false;
      return await InternetConnectionChecker().hasConnection;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: connectionStream,
      builder: (context, snapshot) {
        final hasInternet = snapshot.data ?? true;

        return Stack(
          children: [
            Scaffold(
              extendBody: true,
              body: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
              bottomNavigationBar: BuildNaviBot(
                currentIndex: _currentIndex,
                hasInternet: hasInternet,
                onRetry: () async {
                  final ok = await InternetConnectionChecker().hasConnection;
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  // Remove any existing snackbars to avoid stacking
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Đã kết nối' : 'Vẫn mất kết nối'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor:
                          ok ? Colors.greenAccent.shade700 : Colors.redAccent,
                    ),
                  );
                },
                onItemSelected: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
