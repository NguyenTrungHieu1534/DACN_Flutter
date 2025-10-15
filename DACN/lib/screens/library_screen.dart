import 'package:flutter/material.dart';
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
          SliverAppBar.large(
            backgroundColor: AppColors.retroPrimary,
            foregroundColor: AppColors.retroWhite,
            title: const Text('Your Library 🌺'),
            pinned: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _retroCard(
                  icon: Icons.favorite,
                  text: "Liked Songs",
                  color: AppColors.retroPeach.withOpacity(0.7),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavScreen()),
                    );
                  },
                ),
                _retroCard(
                  icon: Icons.history,
                  text: "Recently Played",
                  color: AppColors.retroSand.withOpacity(0.7),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
                _retroCard(
                  icon: Icons.playlist_play,
                  text: "Playlists",
                  color: AppColors.retroPrimary.withOpacity(0.7),
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
