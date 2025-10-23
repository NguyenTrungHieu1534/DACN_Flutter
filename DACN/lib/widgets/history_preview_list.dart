import 'package:flutter/material.dart';
import '../models/history.dart';
import '../theme/app_theme.dart';

class HistoryPreviewList extends StatelessWidget {
  final List<HistorySong> history;
  final String Function(DateTime) formatDate;

  const HistoryPreviewList({
    super.key,
    required this.history,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Text('No listening history yet',
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
      );
    }

    return Column(
      children: history
          .map((song) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.oceanBlue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.history, color: AppColors.oceanBlue),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${song.artist} • ${formatDate(song.playedAt)}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  onTap: () {},
                ),
              ))
          .toList(),
    );
  }
}