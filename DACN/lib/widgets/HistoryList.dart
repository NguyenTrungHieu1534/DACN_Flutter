import 'package:flutter/material.dart';
import '../models/history.dart';

class HistoryList extends StatelessWidget {
  final List<HistorySong> songs;
  final Function(HistorySong)? onTap;
  final Map<String, String>? titleToCoverUrl; // optional map for covers

  const HistoryList({super.key, required this.songs, this.onTap, this.titleToCoverUrl});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Center(
        child: Text(
          "💔 Chưa có lịch sử nghe nào",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      );
    }

    final List<Color> cardColors = [
      Color(0xFFFFF4D9), // vàng pastel
      Color(0xFFD0F4DE), // xanh lá pastel
      Color(0xFFFFE0F0), // hồng pastel
      Color(0xFFD0E7FF), // xanh sky pastel
    ];

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final cardColor = cardColors[index % cardColors.length];
        final coverUrl = titleToCoverUrl?[song.title] ?? '';

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
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
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.blueAccent,
                      child: Icon(Icons.history, color: Colors.white),
                    ),
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
            trailing: Text(
              "${song.playedAt.hour}:${song.playedAt.minute.toString().padLeft(2, '0')}",
              style: TextStyle(color: Colors.brown.shade400, fontSize: 12),
            ),
            onTap: () => onTap?.call(song),
          ),
        );
      },
    );
  }
}
