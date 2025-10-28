import 'package:flutter/material.dart';
import 'dart:math';

class SuggestedPlaylists extends StatelessWidget {
  const SuggestedPlaylists({super.key});

  @override
  Widget build(BuildContext context) {
    final numbers = [1, 2, 3, 4];
    numbers.shuffle();

    // Danh sách 2 playlist cố định
    final playlists = [
      {
        'title': 'Discover Mix',
        'image': 'assets/default_pic/playlist_suggest_0${numbers[0]}.jpg',
      },
      {
        'title': 'Daily Mix',
        'image': 'assets/default_pic/playlist_suggest_0${numbers[1]}.jpg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Suggested Playlists',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: playlists.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cột
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1, // vuông
            ),
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      playlist['image']!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    playlist['title']!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
