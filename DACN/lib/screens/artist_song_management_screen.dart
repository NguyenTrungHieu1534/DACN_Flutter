import 'package:flutter/material.dart';
import '../models/songs.dart';
import '../services/api_artist.dart';

class ArtistSongManagementScreen extends StatefulWidget {
  final String artistId;
  final String artistName;

  const ArtistSongManagementScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistSongManagementScreen> createState() =>
      _ArtistSongManagementScreenState();
}

class _ArtistSongManagementScreenState extends State<ArtistSongManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ArtistService _artistService = ArtistService();

  List<Songs> _visibleSongs = [];
  List<Songs> _hiddenSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSongs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final visibleSongs =
          await _artistService.fetchSongsByArtist(widget.artistName);
      final hiddenSongs = await _artistService.getHiddenSongs(widget.artistId);
      if (mounted) {
        setState(() {
          _visibleSongs = visibleSongs;
          _hiddenSongs = hiddenSongs;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải bài hát: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _hideSong(String songId) async {
    final success = await _artistService.hideSong(songId, widget.artistId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Đã ẩn bài hát.'
              : 'Không thể ẩn bài hát.')));
      if (success) _loadSongs();
    }
  }

  Future<void> _unhideSong(String songId) async {
    final success = await _artistService.unhideSong(songId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Đã bỏ ẩn bài hát.'
              : 'Không thể bỏ ẩn bài hát.')));
      if (success) _loadSongs();
    }
  }

  Future<void> _deleteSong(String songId) async {
    final success = await _artistService.deleteSong(songId, widget.artistId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              success ? 'Đã xóa bài hát.' : 'Không thể xóa bài hát.')));
      if (success) _loadSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý bài hát'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang hiển thị'),
            Tab(text: 'Đã ẩn'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSongList(_visibleSongs, isVisible: true),
                _buildSongList(_hiddenSongs, isVisible: false),
              ],
            ),
    );
  }

  Widget _buildSongList(List<Songs> songs, {required bool isVisible}) {
    if (songs.isEmpty) {
      return Center(
        child: Text(
            'Không có bài hát nào trong danh sách này.',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSongs,
      child: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: song.thumbnail.isNotEmpty
                    ? NetworkImage(song.thumbnail)
                    : null,
                child: song.thumbnail.isEmpty ? const Icon(Icons.music_note) : null,
              ),
              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'hide') {
                    _hideSong(song.id);
                  } else if (value == 'unhide') {
                    _unhideSong(song.id);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(song.id);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (isVisible)
                    const PopupMenuItem<String>(
                      value: 'hide',
                      child: Text('Ẩn bài hát'),
                    )
                  else
                    const PopupMenuItem<String>(
                      value: 'unhide',
                      child: Text('Bỏ ẩn'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(String songId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
              'Bạn có chắc chắn muốn xóa vĩnh viễn bài hát này không? Hành động này không thể hoàn tác.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSong(songId);
              },
            ),
          ],
        );
      },
    );
  }
}