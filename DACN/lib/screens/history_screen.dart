import 'package:flutter/material.dart';
import '../services/api_history.dart';
import '../models/history.dart';
import '../models/songs.dart';
import '../services/api_album.dart';
import '../services/api_songs.dart';
import '../screens/album_detail_screen.dart';
import 'package:provider/provider.dart';
import '../models/AudioPlayerProvider.dart';
import '../navigation/custom_page_route.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<HistorySong>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _historyService.getHistory();
    });
  }

  Future<Songs> _getCompleteSongDetails(HistorySong historySong) async {
    Songs songData;
    if (historySong.album.isEmpty) {
      songData = await SongService.fetchSongDetailsById(historySong.songId);
    } else {
      songData = Songs(
        id: historySong.songId,
        title: historySong.title,
        artist: historySong.artist,
        album: historySong.album,
        thumbnail: historySong.thumbnail,
        url: '',
        mp3Url: '',
        songId: historySong.songId,
      );
    }

    final albumCoverUrl = await AlbumService.fetchAlbumCover(
        songData.album.isNotEmpty ? songData.album : "Unknown Album");
    return songData.copyWith(thumbnail: albumCoverUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<List<HistorySong>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Lỗi tải dữ liệu 😢",
                    style: TextStyle(color: theme.colorScheme.error)));
          }
          final history = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                floating: false,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 1,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'Lịch sử nghe',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                                theme.primaryColor.withOpacity(0.3),
                                theme.scaffoldBackgroundColor
                              ]
                            : [const Color(0xFF70A0C1), Colors.white],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.history_rounded,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              if (history.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Lịch sử của bạn trống trơn ',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final historySong = history[index];
                      return FutureBuilder<Songs>(
                        future: _getCompleteSongDetails(historySong),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade300,
                                child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.0)),
                              ),
                              title: Text(historySong.title),
                              subtitle: Text(historySong.artist),
                            );
                          }

                          if (snapshot.hasError || !snapshot.hasData) {
                            return ListTile(
                              leading: const Icon(Icons.error_outline,
                                  color: Colors.red, size: 40),
                              title: Text(historySong.title),
                              subtitle: Text(historySong.artist),
                              trailing: const Icon(Icons.play_disabled,
                                  color: Colors.grey),
                            );
                          }

                          final song = snapshot.data!;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                song.thumbnail,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.music_note, size: 30),
                              ),
                            ),
                            title: Text(song.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(song.artist,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: Icon(Icons.play_arrow,
                                  color: theme.primaryColor),
                              onPressed: () {
                                final audioProvider =
                                    Provider.of<AudioPlayerProvider>(context,
                                        listen: false);
                                audioProvider.setNewPlaylist([song], 0);
                              },
                            ),
                            onTap: () {
                              if (song.album.isNotEmpty &&
                                  song.thumbnail.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  FadePageRoute(
                                    child: AlbumDetailScreen(
                                      albumName: song.album,
                                      albumImage: song.thumbnail,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Không đủ thông tin để mở album.')),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                    childCount: history.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
