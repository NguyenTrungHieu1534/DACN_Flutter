import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../models/songs.dart';
import '../navigation/bottom_nav.dart';
import '../models/AudioPlayerProvider.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  final String albumImage;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.albumImage,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late Future<List<Songs>> futureSongs;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    futureSongs = fetchSongsByAlbum(widget.albumName);
  }

  Future<List<Songs>> fetchSongsByAlbum(String album) async {
    final encodedAlbum = Uri.encodeComponent(album);
    final url =
        'https://backend-dacn-9l4w.onrender.com/api/albums/$encodedAlbum/songs';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final songsJson = data['songs'] as List;
      return songsJson.map((e) => Songs.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách bài hát của album này');
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.albumName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: FutureBuilder<List<Songs>>(
          future: futureSongs,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Không có bài hát nào trong album này',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            final songs = snapshot.data!;

            return ListView.separated(
              itemCount: songs.length,
              separatorBuilder: (_, __) => const Divider(
                color: Colors.white12,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.albumImage,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white54),
                      ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    final audioProvider =
                        Provider.of<AudioPlayerProvider>(context, listen: false);

                    // ✅ Tạo bản sao bài hát có thumbnail = ảnh album
                    final updatedSong = Songs(
                      id: song.id,
                      title: song.title,
                      artist: song.artist,
                      albuml: song.albuml,
                      url: song.url,
                      thumbnail: widget.albumImage,
                      mp3Url: song.mp3Url,
                    );

                    audioProvider.playSong(updatedSong);
                    debugPrint("🎵 Đang phát: ${song.title}");
                    debugPrint("🖼️ Ảnh bìa: ${updatedSong.thumbnail}");
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: BuildNaviBot(
        currentIndex: _currentIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}
