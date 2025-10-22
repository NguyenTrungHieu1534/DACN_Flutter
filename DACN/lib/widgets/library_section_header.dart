import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LibrarySectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const LibrarySectionHeader({
    super.key,
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See all',
                style: TextStyle(color: AppColors.oceanBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}