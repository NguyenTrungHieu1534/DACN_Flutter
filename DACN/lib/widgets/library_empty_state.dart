import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LibraryEmptyState extends StatelessWidget {
  final VoidCallback onCreatePlaylist;

  const LibraryEmptyState({
    super.key,
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No collections yet',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first playlist to get started.',
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onCreatePlaylist,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Create playlist'),
            ),
          ),
        ],
      ),
    );
  }
}