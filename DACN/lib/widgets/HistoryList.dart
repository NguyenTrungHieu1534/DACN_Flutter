import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/history.dart';

class HistoryList extends StatelessWidget {
  final List<HistorySong> songs;
  final Function(HistorySong)? onTap;

  const HistoryList({super.key, required this.songs, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(
        child: Text(
          " Chưa có lịch sử nghe nào",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      );
    }
    final List<Color> cardColors = [
      const Color(0xFFFFF4D9), // vàng pastel
      const Color(0xFFD0F4DE), // xanh lá pastel
      const Color(0xFFFFE0F0), // hồng pastel
      const Color(0xFFD0E7FF), // xanh sky pastel
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final cardColor = cardColors[index % cardColors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
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
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.oceanBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Colors.white),
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
