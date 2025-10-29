import 'package:flutter/material.dart';
import 'dart:math';
import '../screens/suggested_playlist_screen.dart';
class SuggestedPlaylists extends StatelessWidget {
  const SuggestedPlaylists({super.key});

  @override
  Widget build(BuildContext context) {
    final numbers = [1, 2, 3, 4];
    numbers.shuffle();

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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Suggested Playlists',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: index == playlists.length - 1 ? 16 : 0,
                ),
                child: _PlaylistCard(
                  title: playlist['title']!,
                  image: playlist['image']!,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String title;
  final String image;

  const _PlaylistCard({
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SuggestedPlaylistScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              children: [
                Image.asset(
                  image,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(48, 97, 103, 158).withOpacity(0.7),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
