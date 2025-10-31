import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/songs.dart';
import '../services/api_artist.dart';
import '../models/AudioPlayerProvider.dart';
import '../widgets/shimmer_widgets.dart';
import '../navigation/custom_page_route.dart';
import 'player_screen.dart';
import '../theme/app_theme.dart';

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;

  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  late Future<Map<String, dynamic>> _artistDetailsFuture;
  final ArtistService _artistService = ArtistService();

  @override
  void initState() {
    super.initState();
    _artistDetailsFuture = _loadArtistDetails();
  }

  Future<Map<String, dynamic>> _loadArtistDetails() async {
    try {
      final songs = await _artistService.fetchSongsByArtist(widget.artistName);
      final photoUrl = await _artistService.fetchArtistPhotoUrl(widget.artistName);
      return {'songs': songs, 'photoUrl': photoUrl};
    } catch (e) {
      // Rethrow to be caught by FutureBuilder
      throw Exception('Failed to load artist details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _artistDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final songs = snapshot.data?['songs'] as List<Songs>? ?? [];
          final photoUrl = snapshot.data?['photoUrl'] as String? ?? '';

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                floating: false,
                backgroundColor: AppColors.mist,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    widget.artistName,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                        ),
                      ),
                      Container(color: Colors.black.withOpacity(0.2)),
                      Center(
                        child: CircleAvatar(
                          radius: 80,
                          backgroundImage: NetworkImage(photoUrl),
                          onBackgroundImageError: (_, __) {},
                          child: photoUrl.isEmpty ? const Icon(Icons.person, size: 80) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: songs.isEmpty
                ? const Center(child: Text('Không tìm thấy bài hát nào của nghệ sĩ này.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _buildSongTile(context, song, photoUrl);
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, Songs song, String artistPhotoUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.oceanBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

            if (song.thumbnail.isEmpty) {
              song.thumbnail = artistPhotoUrl;
            }
            audioProvider.playSong(song);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(song.thumbnail.isNotEmpty ? song.thumbnail : artistPhotoUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    ),
                  ),
                  child: song.thumbnail.isEmpty && artistPhotoUrl.isEmpty
                      ? const Icon(Icons.music_note, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.oceanDeep,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        song.artist,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.skyBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_arrow_rounded, color: AppColors.oceanBlue, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}