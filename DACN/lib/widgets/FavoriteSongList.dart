import 'package:flutter/material.dart';
import '../models/favSongs.dart';

class FavoriteSongList extends StatelessWidget {
  final List<FavoriteSong> songs;
  final Function(FavoriteSong song)? onDelete;
  final Function(FavoriteSong song)? onTap;

  const FavoriteSongList({
    Key? key,
    required this.songs,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
  if (songs.isEmpty) {
    return Center(
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
    Color(0xFFFFF4D9), // Vàng pastel
    Color(0xFFE0F7FA), // Xanh biển nhạt
    Color(0xFFFFE4E1), // Hồng đào nhạt
    Color(0xFFE8F5E9), // Xanh lá nhạt
    Color(0xFFFDEBD0), // Cam pastel
  ];

  return ListView.builder(
    padding: EdgeInsets.all(12),
    itemCount: songs.length,
    itemBuilder: (context, index) {
      final song = songs[index];
      final color = retroColors[index % retroColors.length]; // Đổi màu tuần hoàn

      return Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(2, 4),
            )
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(10),
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
                  onTap: () => onDelete!(song),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete, color: Colors.white),
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
