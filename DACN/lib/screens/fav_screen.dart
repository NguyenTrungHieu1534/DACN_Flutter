import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/favSongs.dart';
import '../models/songs.dart';
import '../models/AudioPlayerProvider.dart';
import '../services/api_favsongs.dart';
import '../services/api_album.dart';
import '../theme/app_theme.dart';

class FavScreen extends StatefulWidget {
  const FavScreen({super.key});

  @override
  _FavScreenState createState() => _FavScreenState();
}

class _FavScreenState extends State<FavScreen> {
  final FavoriteService _favService = FavoriteService();
  late Future<List<FavoriteSong>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _favService.getFavorites();
    });
  }

  void _playAll(List<FavoriteSong> favSongs, {bool shuffle = false}) async {
    if (favSongs.isEmpty) return;

    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

    final songsToPlay = await Future.wait(favSongs.map((fav) async {
      String thumbnailUrl = '';
      if (fav.album.isNotEmpty) {
        try {
          thumbnailUrl = await AlbumService.fetchAlbumCover(fav.album);
        } catch (e) {
        }
      }
      return Songs(
        id: fav.songId,
        title: fav.title,
        artist: fav.artist,
        album: fav.album,
        thumbnail: thumbnailUrl,
        url: '',
        mp3Url: '',
      );
    }).toList());

    if (shuffle) {
      songsToPlay.shuffle();
    }

    audioProvider.setNewPlaylist(songsToPlay, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<FavoriteSong>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading data: ${snapshot.error}"));
          }

          final favorites = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  centerTitle: false,
                  title: Text(
                    'Favorites',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (favorites.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _playAll(favorites),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.oceanBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _playAll(favorites, shuffle: true),
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Shuffle'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.oceanBlue,
                              side: const BorderSide(color: AppColors.oceanBlue),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (favorites.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No favorite songs yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Press ❤️ on a song to add it here.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final favSong = favorites[index];
                      return _FavoriteSongTile(
                        favoriteSong: favSong,
                        index: index + 1,
                        onRemoved: () {
                          setState(() {
                            favorites.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Removed from Favorites'), duration: Duration(seconds: 1)),
                          );
                        },
                        onTap: () async {
                          final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
                          
                          final songsToPlay = await Future.wait(favorites.map((fav) async {
                            String thumbnailUrl = '';
                            if (fav.album.isNotEmpty) {
                              try {
                                thumbnailUrl = await AlbumService.fetchAlbumCover(fav.album);
                              } catch (e) {  }
                            }
                            return Songs(
                              id: fav.songId,
                              title: fav.title,
                              artist: fav.artist,
                              album: fav.album,
                              thumbnail: thumbnailUrl,
                              url: '', mp3Url: '',
                            );
                          }).toList());
                          audioProvider.setNewPlaylist(songsToPlay, index);
                        },
                      );
                    },
                    childCount: favorites.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoriteSongTile extends StatefulWidget {
  final FavoriteSong favoriteSong;
  final int index;
  final VoidCallback onRemoved;
  final VoidCallback onTap;

  const _FavoriteSongTile({
    required this.favoriteSong,
    required this.index,
    required this.onRemoved,
    required this.onTap,
  });

  @override
  State<_FavoriteSongTile> createState() => _FavoriteSongTileState();
}

class _FavoriteSongTileState extends State<_FavoriteSongTile> {
  String? _thumbnailUrl;

  @override
  void initState() {
    super.initState();
    _fetchThumbnail();
  }

  Future<void> _fetchThumbnail() async {
    if (widget.favoriteSong.album.isNotEmpty) {
      try {
        final url = await AlbumService.fetchAlbumCover(widget.favoriteSong.album);
        if (mounted) {
          setState(() {
            _thumbnailUrl = url;
          });
        }
      } catch (e) {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24, 
            child: Text(
              '${widget.index}',
              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _thumbnailUrl != null
                ? Image.network(_thumbnailUrl!, width: 40, height: 40, fit: BoxFit.cover)
                : Container(width: 40, height: 40, color: Colors.grey.shade300, child: const Icon(Icons.music_note, color: Colors.white)),
          ),
        ],
      ),
      title: Text(widget.favoriteSong.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(widget.favoriteSong.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: widget.onTap,
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
        tooltip: 'Remove from Favorites',
        onPressed: () async {
          await FavoriteService().deleteFavoriteById(widget.favoriteSong.id.toString());
          widget.onRemoved();
        },
      ),
    );
  }
}
