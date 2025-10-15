import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/api_playlist.dart';
import '../theme/app_theme.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Future<List<Playlist>> _playlistsFuture;
  final ApiPlaylist apiPlaylist = ApiPlaylist();

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlistsFuture = apiPlaylist.getPlaylistsByUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.retroWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.retroPrimary,
            foregroundColor: AppColors.retroWhite,
            title: const Text('Playlists 🌴'),
            pinned: true,
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: FutureBuilder<List<Playlist>>(
              future: _playlistsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.retroAccent)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải playlist 😢", style: TextStyle(color: AppColors.retroAccent),));
                }

                final playlists = snapshot.data ?? [];

                if (playlists.isEmpty) {
                  return const Center(
                    child: Text(
                      "💔 Chưa có playlist nào",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.retroAccent),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final color = AppColors.retroPrimary.withOpacity(0.7 - (index * 0.1)); // Adjusted for a retro feel

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.retroAccent.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          )
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          playlist.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.retroAccent),
                        ),
                        subtitle: Text("${playlist.songs.length} bài hát", style: TextStyle(color: AppColors.retroAccent.withOpacity(0.7))),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.retroAccent),
                        onTap: () {
                          // TODO: Mở chi tiết playlist
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
