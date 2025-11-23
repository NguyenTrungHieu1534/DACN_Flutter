import 'package:flutter/material.dart';
import '../services/api_repost.dart';
import '../theme/app_theme.dart';
import '../models/repost.dart'; 
import 'dart:async';

class RepostListScreen extends StatefulWidget {
  final String userId;
  const RepostListScreen({super.key, required this.userId});

  @override
  State<RepostListScreen> createState() => _RepostListScreenState();
}

class _RepostListScreenState extends State<RepostListScreen> {
 
  List<Repost> _reposts = []; 
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReposts();
  }

  Future<void> _loadReposts() async {
    try {
      final service = RepostService();
      final data = await service.fetchRepostsByUser(widget.userId); 
      if (mounted) {
        setState(() {

          _reposts = data; 
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reposts: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatRepostDate(DateTime? repostedAt) {
    if (repostedAt == null) return 'Reposted';
    return 'Reposted on ${repostedAt.day}/${repostedAt.month}/${repostedAt.year}';
  }

  Widget _buildRepostItem(Repost repost, bool isTablet) {

    final song = repost.songInfo;
    final repostDate = _formatRepostDate(repost.repostedAt);

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 12 : 8,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            song.thumbnail.isNotEmpty ? song.thumbnail : 'https://via.placeholder.com/150',
            width: isTablet ? 72 : 56,
            height: isTablet ? 72 : 56,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          song.title,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.artist,
              style: TextStyle(
                fontSize: isTablet ? 15 : 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              repostDate,
              style: TextStyle(
                fontSize: isTablet ? 13 : 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.repeat,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        onTap: () {
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài hát đã Repost'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reposts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Chưa có bài hát nào được repost.',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  itemCount: _reposts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final repost = _reposts[index];
                    return _buildRepostItem(repost, isTablet);
                  },
                ),
    );
  }
}