import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album.dart';
import '../services/api_album.dart';
import 'login_screen.dart';
import 'player_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Album>> _albumsFuture;

  @override
  void initState() {
    super.initState();
    _albumsFuture = AlbumService.fetchAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "🎵 Album Library",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Ocean gradient background + sand overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.oceanDeep,
                  AppColors.oceanBlue,
                  AppColors.skyBlue,
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.sand],
                ),
              ),
            ),
          ),
          FutureBuilder<List<Album>>(
            future: _albumsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "Không có album nào",
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final albums = snapshot.data!;

              return RefreshIndicator(
                color: AppColors.oceanBlue,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  setState(() {
                    _albumsFuture = AlbumService.fetchAlbums();
                  });
                },
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final heroTag = 'albumArt-${album.url}-$index';
                    return Material(
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
                    );
                  },
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 0.6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const _NavIcon(icon: Icons.home_filled, label: 'Home', active: true),
                  const _NavIcon(icon: Icons.search, label: 'Search'),
                  const _NavIcon(icon: Icons.library_music, label: 'Library'),
                  _NavIcon(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () => _showProfileSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.label, this.active = false, this.onTap});

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
          child: Column(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('auth_token');
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

