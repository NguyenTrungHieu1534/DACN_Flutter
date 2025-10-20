import 'package:flutter/material.dart';
import '../models/album.dart';
import '../services/api_album.dart';
import '../models/songs.dart';
import '../services/api_songs.dart';
import '../widgets/TrendingAlbums.dart';
import '../widgets/TrendingSong.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/hawaii_greeting_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    // Removed unused retroAccent
    // Removed unused retroPeach, retroSand, retroWhite, retroBoxGradient, retroShadow

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D1117),
                    Color(0xFF161B22),
                  ],
                  stops: [0.0, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 112, 150, 193),
                    Color(0xFFF8F9FB),
                  ],
                  stops: [0.0, 0.4],
                ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: _combinedFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ShimmerWidgets.homeScreenShimmer();
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
                      Icon(
                        Icons.error_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Oops! Something went wrong",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
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

            final albums = (snapshot.data![0] as List<Album>)
                .where((album) => album.url.isNotEmpty)
                .toList();
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
              backgroundColor: Theme.of(context).colorScheme.surface,
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
                    HawaiiGreetingCard(
                      greeting: () =>
                          greeting(), // truyền hàm greeting() của bạn
                      getGreetingIcon: (hour) =>
                          _getGreetingIcon(hour), // truyền hàm icon của bạn
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
                        title: 'Trending Albums',
                        itemsAlbum: trendingAlbums,
                        isLoading: false),
                    const SizedBox(height: 28),

                    TrendingSong(
                        title: 'New Releases',
                        itemsAlbum: newReleases,
                        itemsSsongs: const [],
                        isLoading: false),
                    const SizedBox(height: 28),
                    TrendingSong(
                        title: 'Trending Songs',
                        itemsAlbum: const [],
                        itemsSsongs: trendingSongs,
                        isLoading: false),
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
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.secondary;

    return Material(
      elevation: 3,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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

// Removed unused _buildRetroDivider

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
