import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:music_login/screens/fav_screen.dart';
import '../theme/app_theme.dart';
import '../screens/playlist_screen.dart';
import '../screens/history_screen.dart';
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.retroWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.75),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Library',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Favorites, playlists, and history',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _retroCard(
                  icon: Icons.favorite_rounded,
                  text: "Liked Songs",
                  color: AppColors.retroPeach.withOpacity(0.85),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavScreen()),
                    );
                  },
                ),
                _retroCard(
                  icon: Icons.history_rounded,
                  text: "Recently Played",
                  color: AppColors.retroSand.withOpacity(0.85),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
                _retroCard(
                  icon: Icons.playlist_play_rounded,
                  text: "Playlists",
                  color: AppColors.retroPrimary.withOpacity(0.85),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlaylistScreen()),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retroCard({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.retroAccent.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(2, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppColors.retroAccent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.retroAccent,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.retroAccent),
          ],
        ),
      ),
    );
  }
}
