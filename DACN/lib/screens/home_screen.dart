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
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<dynamic>>(
        future: _combinedFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Lỗi: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final albums = snapshot.data![0] as List<Album>;
          final songs = snapshot.data![1] as List<Songs>;

          final trendingAlbums = albums.take(10).toList();
          final newReleases = albums
              .skip(albums.length > 5 ? albums.length - 5 : 0)
              .toList()
              .reversed
              .toList();
          final trendingSongs = songs.take(10).toList();

          String greeting() {
            final hour = DateTime.now().hour;
            if (hour < 12) return 'Good Morning';
            if (hour < 18) return 'Good Afternoon';
            return 'Good Evening';
          }

          return RefreshIndicator(
            color: AppColors.oceanBlue,
            backgroundColor: Colors.white,
            onRefresh: () async {
              setState(() {
                _albumsFuture = AlbumService.fetchAlbums();
                _songsFuture = SongService.fetchSongs();
                _combinedFuture = Future.wait([_albumsFuture, _songsFuture]);
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8 + 48, 12, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      greeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HorizontalSection(
                    title: 'Trending album right now',
                    itemsAlbum: trendingAlbums,
                    itemsSsongs: const [],
                  ),
                  const SizedBox(height: 16),
                  _HorizontalSection(
                    title: 'New releases',
                    itemsAlbum: newReleases,
                    itemsSsongs: const [],
                  ),
                  const SizedBox(height: 16),
                  _HorizontalSection(
                    title: 'Trending songs right now',
                    itemsAlbum: const [],
                    itemsSsongs: trendingSongs,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection(
      {required this.title,
      required this.itemsAlbum,
      required this.itemsSsongs});

  final String title;
  final List<Album> itemsAlbum;
  final List<Songs> itemsSsongs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SectionListScreen(title: title, items: itemsAlbum),
                    ),
                  );
                },
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: itemsAlbum.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final album = itemsAlbum[index];
              final heroTag = 'albumArt-${album.url}-h-$index';
              return SizedBox(
                width: 150,
                child: Material(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            title: album.name,
                            subtitle: album.artist,
                            imageUrl: album.url,
                            heroTag: heroTag,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Hero(
                            tag: heroTag,
                            child: Ink.image(
                              image: NetworkImage(album.url),
                              fit: BoxFit.cover,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                          child: Text(
                            album.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Text(
                            album.artist,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(
      {required this.icon,
      required this.label,
      this.active = false,
      this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? Colors.white : Colors.white70;
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: content,
      ),
    );
  }
}

void _showProfileSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: FutureBuilder<bool>(
            future: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('auth_token');
              return token != null && token.isNotEmpty;
            }(),
            builder: (context, snapshot) {
              final bool isLoggedIn = snapshot.data == true;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.person_outline),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Profile',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    ],
                  ),
                  const Divider(height: 20),
                  if (!snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (isLoggedIn)
                    ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Logout'),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('auth_token');
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    )
                  else
                    ListTile(
                      leading:
                          const Icon(Icons.login, color: Colors.blueAccent),
                      title: const Text('Login'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
