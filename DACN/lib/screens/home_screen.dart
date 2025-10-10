import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album.dart';
import '../services/api_album.dart';
import 'login_screen.dart';
import 'player_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'section_list_screen.dart';
import '../theme/app_theme.dart';
import '../models/songs.dart';
import '../services/api_songs.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../widgets/TrendingAlbums.dart';
import '../widgets/TrendingSong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Album>> _albumsFuture;
  late Future<List<Songs>> _songsFuture;

  late Future<List<dynamic>> _combinedFuture;

  @override
  void initState() {
    super.initState();
    _albumsFuture = AlbumService.fetchAlbums();
    _songsFuture = SongService.fetchSongs();
    // Kết hợp 2 Future cùng lúc
    _combinedFuture = Future.wait([_albumsFuture, _songsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    // 🌴 AppTheme — gộp trực tiếp
    const retroPrimary = Color(0xFF70C1B3); // xanh ngọc retro
    const retroAccent = Color(0xFF247BA0); // xanh biển đậm
    const retroPeach = Color(0xFFFFB6B9); // hồng pastel
    const retroSand = Color(0xFFFFE066); // vàng cát
    const retroWhite = Color(0xFFFFFFFF);

    final retroBoxGradient = LinearGradient(
      colors: [
        retroPrimary.withOpacity(0.25),
        retroAccent.withOpacity(0.15),
      ],
    );

    final retroShadow = [
      BoxShadow(
        color: retroPrimary.withOpacity(0.25),
        blurRadius: 12,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 112, 150, 193), // xanh ngọc retro
              Color(0xFFFFFFFF), // trắng pastel
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: _combinedFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: retroPrimary.withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        color: retroPrimary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading your retro vibes...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.2),
                        Colors.red.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Oops! Something went wrong",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final albums = snapshot.data![0] as List<Album>;
            final songs = snapshot.data![1] as List<Songs>;

            albums.shuffle();
            songs.shuffle();

            final trendingAlbums = albums.take(4).toList();
            final trendingSongs = songs.take(5).toList();
            final newReleases = albums
                .skip(albums.length > 5 ? albums.length - 5 : 0)
                .toList()
                .reversed
                .toList();

            for (var song in songs) {
              final album = albums.firstWhere(
                (a) => a.name == song.albuml,
                orElse: () => albums.first,
              );
              song.thumbnail = album.url;
            }

            String greeting() {
              final hour = DateTime.now().hour;
              if (hour < 12) return 'Good Morning';
              if (hour < 18) return 'Good Afternoon';
              return 'Good Evening';
            }

            return RefreshIndicator(
              color: retroPrimary,
              backgroundColor: retroWhite,
              strokeWidth: 3,
              onRefresh: () async {
                setState(() {
                  _albumsFuture = AlbumService.fetchAlbums();
                  _songsFuture = SongService.fetchSongs();
                  _combinedFuture = Future.wait([_albumsFuture, _songsFuture]);
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌸 Greeting Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF00C6FB), // Xanh biển sáng
                            Color(0xFF005BEA), // Xanh biển đậm
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007BFF).withOpacity(0.25),
                            offset: const Offset(0, 6),
                            blurRadius: 12,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.15),
                            offset: const Offset(-4, -4),
                            blurRadius: 8,
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF8EE7FF).withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon tròn kiểu mặt trời Hawaii
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFC371), // Vàng cam mặt trời
                                  Color(0xFFFF5F6D), // Cam hồng nhiệt đới
                                ],
                              ),
                            ),
                            child: Icon(
                              _getGreetingIcon(DateTime.now().hour),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Text chào
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFFFE29F), // Vàng ánh sáng
                                    Color(0xFFFF719A), // Hồng đào
                                    Color(0xFF9BFFF9), // Aqua sáng
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  greeting(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 6,
                                        color: Color(0xFF004C97),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Let’s ride the wave of music 🌊',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🌴 Quick Chips retro
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _QuickChip(
                              label: 'Liked Songs', icon: Icons.favorite),
                          SizedBox(width: 8),
                          _QuickChip(
                              label: 'Recently Played', icon: Icons.history),
                          SizedBox(width: 8),
                          _QuickChip(
                              label: 'For You', icon: Icons.auto_awesome),
                          SizedBox(width: 8),
                          _QuickChip(
                              label: 'Trending', icon: Icons.trending_up),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    TrendingAlbum(
                        title: 'Trending Albums', itemsAlbum: trendingAlbums),
                    const SizedBox(height: 28),
                    _buildRetroDivider(),
                    TrendingSong(
                        title: 'New Releases',
                        itemsAlbum: newReleases,
                        itemsSsongs: const []),
                    const SizedBox(height: 28),
                    _buildRetroDivider(),
                    TrendingSong(
                        title: 'Trending Songs',
                        itemsAlbum: const [],
                        itemsSsongs: trendingSongs),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    super.key,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final themeColor =
        const Color.fromARGB(255, 114, 148, 180); // màu retro xanh biển nhạt

    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: themeColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildRetroDivider() {
  return Container(
    height: 1.2,
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          Color.fromARGB(255, 112, 150, 193), // xanh pastel đồng bộ
          Colors.transparent,
        ],
        stops: [0.1, 0.5, 0.9],
      ),
    ),
  );
}

IconData _getGreetingIcon(int hour) {
  if (hour < 12) return Icons.wb_sunny_rounded;
  if (hour < 18) return Icons.wb_twilight_rounded;
  return Icons.nightlight_round;
}

// void _showProfileSheet(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     backgroundColor: Colors.white,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//     ),
//     builder: (ctx) {
//       return SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//           child: FutureBuilder<bool>(
//             future: () async {
//               final prefs = await SharedPreferences.getInstance();
//               final token = prefs.getString('auth_token');
//               return token != null && token.isNotEmpty;
//             }(),
//             builder: (context, snapshot) {
//               final bool isLoggedIn = snapshot.data == true;
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const CircleAvatar(
//                         radius: 20,
//                         child: Icon(Icons.person_outline),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Profile',
//                         style:
//                             Theme.of(context).textTheme.titleMedium?.copyWith(
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.pop(ctx),
//                       )
//                     ],
//                   ),
//                   const Divider(height: 20),
//                   if (!snapshot.hasData)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 12),
//                       child: Center(child: CircularProgressIndicator()),
//                     )
//                   else if (isLoggedIn)
//                     ListTile(
//                       leading:
//                           const Icon(Icons.logout, color: Colors.redAccent),
//                       title: const Text('Logout'),
//                       onTap: () async {
//                         final prefs = await SharedPreferences.getInstance();
//                         await prefs.remove('auth_token');
//                         if (ctx.mounted) Navigator.pop(ctx);
//                       },
//                     )
//                   else
//                     ListTile(
//                       leading:
//                           const Icon(Icons.login, color: Colors.blueAccent),
//                       title: const Text('Login'),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (_) => const LoginScreen()),
//                         );
//                       },
//                     ),
//                   const SizedBox(height: 8),
//                 ],
//               );
//             },
//           ),
//         ),
//       );
//     },
//   );
// }
