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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/ThemeProvider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'navigation/custom_page_route.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import '../models/audio_handler.dart';
import '../screens/login_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  late final AudioHandler audioHandler;
  WidgetsFlutterBinding.ensureInitialized();
  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.app.channel.audio',
      androidNotificationChannelName: 'Wave Music',
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'mipmap/ic_launcher', // Icon app
    ),
  );
  final session = await AudioSession.instance;
  await Firebase.initializeApp();
  String? FCMtoken = await FirebaseMessaging.instance.getToken();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcmToken', FCMtoken.toString());
  // print(" FCM Token: $FCMtoken");
  await session.configure(const AudioSessionConfiguration.music());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AudioPlayerProvider(audioHandler: audioHandler),
        ),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(
        ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF8F9FB),
        ),
      ),
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      title: 'Wave Music',
      home: const AuthCheck(),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/login': (context) => const LoginScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/verifyOTP': (context) => const VerifyOtpScreen(email: ''),
        '/resetPassword': (context) =>
            const ResetPasswordScreen(email: '', otp: ''),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
          return const MainNavigation();
        } else {
          return const LoginScreen();
        }
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

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<Widget> _rootScreens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    UserScreen(),
  ];
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = List.generate(
      _rootScreens.length,
      (index) => Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) => FadePageRoute(
          child: _rootScreens[index],
          settings: routeSettings,
        ),
      ),
    );
  }

  Stream<bool> get connectionStream async* {
    yield* Connectivity().onConnectivityChanged.asyncMap((status) async {
      if (status == ConnectivityResult.none) return false;
      return await InternetConnectionChecker().hasConnection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: connectionStream,
      builder: (context, snapshot) {
        final hasInternet = snapshot.data ?? true;

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            final navigator = _navigatorKeys[_currentIndex].currentState!;
            if (navigator.canPop()) {
              navigator.pop();
            }
          },
          child: Scaffold(
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
                if (_currentIndex == index) {
                  _navigatorKeys[index]
                      .currentState
                      ?.popUntil((route) => route.isFirst);
                } else {
                  setState(() => _currentIndex = index);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
