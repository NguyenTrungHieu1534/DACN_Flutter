import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/AudioPlayerProvider.dart';
import '../models/playlist.dart';
import '../models/songs.dart';
import '../services/api_playlist.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  _PlaylistDetailScreenState createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final ApiPlaylist _api = ApiPlaylist();
  late Future<List<Songs>> _songsFuture;
  String? _currentPicUrl;
  String _currentPlaylistName = '';
  String _currentPlaylistDesc = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentPicUrl = widget.playlist.picUrl;
    _songsFuture = _loadSongs();
    _currentPlaylistName = widget.playlist.name;
    _currentPlaylistDesc = widget.playlist.description;
  }

  Future<void> _showImagePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      final result = await _api.uploadPlaylistPic(
        playlistId: widget.playlist.id,
        imageFile: File(pickedFile.path),
      );
      setState(() => _isUploading = false);

      if (result != null && result['picUrl'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Cập nhật ảnh thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        setState(() => _songsFuture = _loadSongs());
      }
    }
  }

  Future<List<Songs>> _loadSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        _currentPicUrl = null;
        return [];
      }

      final decoded = JwtDecoder.decode(token);
      final username = decoded['username'] as String? ?? '';

      final songsFuture =
          _api.fetchPlaylistSong(username, widget.playlist.name, token);
      final picUrlFuture =
          _api.fetchPlaylistPicUrl(username, widget.playlist.name, token);

      final results = await Future.wait([songsFuture, picUrlFuture]);

      final songs = results[0] as List<Songs>;
      final picUrl = results[1] as String?;

      setState(() => _currentPicUrl = picUrl);

      return songs;
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }

  Future<void> _showRenameDialog() async {
    final nameController = TextEditingController(text: _currentPlaylistName);
    final descController = TextEditingController(text: _currentPlaylistDesc);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isEmpty) return;

                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');
                if (token == null) {
                  Navigator.pop(context);
                  return;
                }

                final updatedData = await ApiPlaylist.renamePlaylist(
                    token, widget.playlist.id, name, desc);
                Navigator.pop(context, updatedData);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result['playlist'] != null) {
      final updatedPlaylist = Playlist.fromJson(result['playlist']);
      setState(() {
        _currentPlaylistName = updatedPlaylist.name;
        _currentPlaylistDesc = updatedPlaylist.description;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.fromARGB(0, 100, 180, 246), Color(0xFFF8F9FB)],
          stops: [0.0, 0.5],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async {
            // Khi refresh, gán lại Future để FutureBuilder rebuild
            setState(() => _songsFuture = _loadSongs());
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: size.height * 0.4,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: _showRenameDialog,
                    tooltip: 'Edit playlist details',
                  ),
                ],
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Text(
                    _currentPlaylistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: FadeInImage.assetNetwork(
                          placeholder:
                              'default_pic/default_playlistPic.png', // Corrected path
                          image: _currentPicUrl ?? '',
                          fit: BoxFit.cover,
                          imageErrorBuilder: (_, __, ___) => Image.asset(
                            'default_pic/default_playlistPic.png', // Corrected path
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ),
                      Center(
                        child: GestureDetector(
                          onTap: () => _showImagePicker(context),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Hero(
                              tag: widget.playlist.id,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      FadeInImage.assetNetwork(
                                        placeholder:
                                            'default_pic/default_playlistPic.png', // Corrected path
                                        image: _currentPicUrl ?? '',
                                        fit: BoxFit.cover,
                                        imageErrorBuilder: (_, __, ___) =>
                                            Image.asset(
                                          'default_pic/default_playlistPic.png', // Corrected path
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (_isUploading)
                                        Container(
                                          color: Colors.black.withOpacity(0.5),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 48,
                        left: 24,
                        right: 24,
                        child: Text(
                          _currentPlaylistDesc,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            shadows: const [
                              Shadow(color: Colors.black26, blurRadius: 4)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- DANH SÁCH BÀI HÁT ----
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: FutureBuilder<List<Songs>>(
                    future: _songsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "Lỗi tải playlist: ${snapshot.error}",
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      final songs = snapshot.data ?? [];
                      if (songs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              "Không có bài hát nào trong playlist này.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        itemCount: songs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return Dismissible(
                            key: ValueKey(song.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token = prefs.getString('token');
                              if (token == null) return;

                              final success =
                                  await ApiPlaylist.removeSongFromPlaylist(
                                token,
                                widget.playlist.id,
                                song.id,
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Đã xóa bài hát khỏi playlist'
                                        : 'Xóa bài hát thất bại'),
                                    backgroundColor:
                                        success ? Colors.green : Colors.red,
                                  ),
                                );
                                if (success) {
                                  setState(() {
                                    songs.removeAt(index);
                                  });
                                }
                              }
                            },
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Xóa',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 2,
                              shadowColor: Colors.blue.withOpacity(0.1),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: song.thumbnail.isNotEmpty
                                      ? Image.network(
                                          song.thumbnail,
                                          width: 55,
                                          height: 55,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 55,
                                          height: 55,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.music_note,
                                              color: Colors.grey),
                                        ),
                                ),
                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                trailing: const Icon(Icons.play_arrow_rounded,
                                    color: Colors.blueAccent, size: 30),
                                onTap: () => audioProvider.playSong(song),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
