import 'package:flutter/material.dart';
import 'package:music_login/screens/fav_screen.dart';
import '../theme/app_theme.dart';
import '/screens/playlist_screen.dart';
import '../screens/history_screen.dart';
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF), // Nền xanh pastel nhạt
      appBar: AppBar(
        backgroundColor: const Color(0xFF76B5FF), // Skyblue đậm hơn chút
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Your Library 🌺',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _retroCard(
            icon: Icons.favorite,
            text: "Liked Songs",
            color: const Color(0xFFFFD6E8), // Pastel hồng
            onTap: () {
              Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FavScreen(),
              ),
            );
            },
          ),
          _retroCard(
            icon: Icons.history,
            text: "Recently Played",
            color: const Color(0xFFFFF5C0), // Vàng nhạt retro
            onTap: () {
               Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HistoryScreen(),
              ),
            );
            },
          ),
          _retroCard(
            icon: Icons.playlist_play,
            text: "Playlists",
            color: const Color(0xFFC8F7C5), // Xanh lá pastel
            onTap: () {
              Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PlaylistScreen(),
              ),
            );
            },
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(2, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.brown.shade700),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
