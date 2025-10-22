import 'package:flutter/material.dart';
import '../models/favSongs.dart';
import '../theme/app_theme.dart';

class FavoritesPreviewList extends StatelessWidget {
  final List<FavoriteSong> favorites;

  const FavoritesPreviewList({
    super.key,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text('No favorite songs yet',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final song = favorites[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.oceanBlue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: AppColors.oceanBlue),
            ),
            title: Text(
              song.title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
            trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
            onTap: () {}, // Navigate to song detail or start playing
          ),
        );
      },
    );
  }
}