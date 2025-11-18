import 'package:flutter/material.dart';
import '../models/songs.dart';
import '../services/api_repost.dart';

class RepostButton extends StatefulWidget {
  final Songs song;
  final RepostService _repostService = RepostService();

  RepostButton({super.key, required this.song});

  @override
  State<RepostButton> createState() => _RepostButtonState();
}

class _RepostButtonState extends State<RepostButton> {
  late Future<bool> _isRepostedFuture;

  @override
  void initState() {
    super.initState();
    _isRepostedFuture = widget._repostService.isSongReposted(widget.song.id);
  }

  void _handleToggleRepost(bool currentlyReposted) async {
    setState(() {
      _isRepostedFuture = Future.value(!currentlyReposted);
    });

    try {
      final newStatus = await widget._repostService.toggleRepost(
        widget.song,
        currentlyReposted,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Đã Repost lên Profile!' : 'Đã hủy Repost.'),
          backgroundColor: newStatus ? Colors.green : Colors.grey,
        ),
      );
      
    } catch (e) {
      setState(() {
        _isRepostedFuture = Future.value(currentlyReposted);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi Repost: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isRepostedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0));
        }

        final bool isReposted = snapshot.data ?? false;
        
        return IconButton(
          icon: Icon(
            Icons.repeat,
            color: isReposted ? Theme.of(context).colorScheme.primary : Colors.white70,
          ),
          onPressed: () => _handleToggleRepost(isReposted),
          tooltip: isReposted ? 'Hủy Repost' : 'Repost lên Profile',
        );
      },
    );
  }
}