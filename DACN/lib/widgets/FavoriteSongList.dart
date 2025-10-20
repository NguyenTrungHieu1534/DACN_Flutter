import 'package:flutter/material.dart';
import '../models/favSongs.dart';
import '../services/api_favsongs.dart';
class FavoriteSongList extends StatelessWidget {
  final List<FavoriteSong> songs;
  final Function(FavoriteSong song)? onDelete;
  final Function(FavoriteSong song)? onTap;
  final FavoriteService favoriteService = FavoriteService();
  FavoriteSongList({
    super.key,
    required this.songs,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
  if (songs.isEmpty) {
    return const Center(
      child: Text(
        "💔 Chưa có bài hát yêu thích nào",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
    );
  }

  final retroColors = [
    const Color(0xFFFFF4D9), // Vàng pastel
    const Color(0xFFE0F7FA), // Xanh biển nhạt
    const Color(0xFFFFE4E1), // Hồng đào nhạt
    const Color(0xFFE8F5E9), // Xanh lá nhạt
    const Color(0xFFFDEBD0), // Cam pastel
  ];

  return ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: songs.length,
    itemBuilder: (context, index) {
      final song = songs[index];
      final color = retroColors[index % retroColors.length];

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 4),
            )
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.music_note, color: Colors.brown.shade700),
          ),
          title: Text(
            song.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade800,
            ),
          ),
          subtitle: Text(
            song.artist,
            style: TextStyle(
              color: Colors.brown.shade600,
            ),
          ),
          trailing: onDelete != null
              ? GestureDetector(
                  onTap: (){
                    onDelete?.call(song);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                )
              : null,
          onTap: () => onTap?.call(song),
        ),
      );
    },
  );
}

}
