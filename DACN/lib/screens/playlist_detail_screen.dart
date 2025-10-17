import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/songs.dart';
import '../services/api_playlist.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;
  const PlaylistDetailScreen({Key? key, required this.playlistName})
      : super(key: key);

  @override
  _PlaylistDetailScreenState createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final ApiPlaylist _api = ApiPlaylist();
  late Future<List<Songs>> _songsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        setState(() {
          _songsFuture = Future.value([]);
        });
        return;
      }

      final decoded = JwtDecoder.decode(token);
      final username = decoded['username'] as String? ?? '';

      setState(() {
        _songsFuture =
            _api.fetchPlaylistSong(username, widget.playlistName, token);
      });
    } catch (e) {
      setState(() {
        _songsFuture = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 112, 150, 193),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSongs,
        child: FutureBuilder<List<Songs>>(
          future: _songsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Không thể tải playlist'));
            }

            final songs = snapshot.data ?? [];
            if (songs.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 160),
                  Center(child: Text('Playlist trống')),
                ],
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(12),
              itemCount: songs.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: song.thumbnail.isNotEmpty
                        ? NetworkImage(song.thumbnail)
                        : null,
                    child:
                        song.thumbnail.isEmpty ? Icon(Icons.music_note) : null,
                  ),
                  title: Text(song.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    // You can navigate to the player screen if available
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
