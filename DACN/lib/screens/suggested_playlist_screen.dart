import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../services/api_album.dart';
import '../services/api_playlist.dart';
import 'playlist_detail_screen.dart';
import '../navigation/custom_page_route.dart';
import '../models/songs.dart';
import '../models/AudioPlayerProvider.dart';

class SuggestedPlaylistScreen extends StatefulWidget {
  const SuggestedPlaylistScreen({super.key});

  @override
  _SuggestedPlaylistScreenState createState() =>
      _SuggestedPlaylistScreenState();
}

class _SuggestedPlaylistScreenState extends State<SuggestedPlaylistScreen> {
  late Future<List<Songs>> _suggestedPlaylistsFuture;

  @override
  void initState() {
    super.initState();
    _suggestedPlaylistsFuture = _fetchSuggestedPlaylists();
  }

  Future<List<Songs>> _fetchSuggestedPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final songs = await ApiPlaylist.fetchSuggestedPlaylists(token);
    debugPrint("songs: $songs");
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested Playlists'),
      ),
      body: FutureBuilder<List<Songs>>(
        future: _suggestedPlaylistsFuture, // Future<List<Song>>
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No suggested songs found.'));
          } else {
            final songs = snapshot.data!;
            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index]; // each song
                return SongListItem(song: song);
              },
            );
          }
        },
      ),
    );
  }
}

class SongListItem extends StatefulWidget {
  final Songs song;

  const SongListItem({Key? key, required this.song}) : super(key: key);

  @override
  _SongListItemState createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem> {
  String? _albumCoverUrl;

  @override
  void initState() {
    super.initState();
    _fetchCover();
  }

  void _fetchCover() async {
    try {
      if (widget.song.album != null) {
        final url = await AlbumService.fetchAlbumCover(widget.song.album!);
        if (mounted) {
          setState(() {
            _albumCoverUrl = url;
          });
        }
      }
    } catch (e) {
      // Handle or log the error appropriately
      print('Failed to fetch album cover: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    return GestureDetector(
      onTap: () {
        widget.song.thumbnail = _albumCoverUrl ?? '';
        audioPlayerProvider.playSong(widget.song);
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: (_albumCoverUrl == null || _albumCoverUrl!.isEmpty)
                ? Image.asset(
                    'assets/default_pic/playlist_suggest_01.jpg',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    _albumCoverUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/default_pic/playlist_suggest_01.jpg',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
          ),
          title: Text(widget.song.title),
          subtitle: Text(widget.song.artist),
        ),
      ),
    );
  }
}
