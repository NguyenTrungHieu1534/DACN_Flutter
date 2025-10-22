import 'package:flutter/material.dart';
import 'package:music_login/screens/fav_screen.dart';
import '../theme/app_theme.dart';
import '/screens/playlist_screen.dart';
import '../screens/history_screen.dart';
import '../services/api_playlist.dart';
import '../models/playlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_favsongs.dart';
import '../models/favSongs.dart';
import '../services/api_history.dart';
import '../models/history.dart';
import 'package:music_login/screens/playlist_detail_screen.dart';
import '../widgets/library_quick_action.dart';
import '../widgets/library_section_header.dart';
import '../widgets/playlist_preview_grid.dart';
import '../widgets/playlist_preview_list.dart';
import '../widgets/favorites_preview_list.dart';
import '../widgets/history_preview_list.dart';
import '../widgets/library_empty_state.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All';
  bool _showAsGrid = true;
  final ApiPlaylist _api = ApiPlaylist();
  final FavoriteService _favService = FavoriteService();
  final HistoryService _historyService = HistoryService();
  List<Playlist> _playlists = [];
  List<FavoriteSong> _favorites = [];
  List<HistorySong> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndData();
  }

  Future<void> _loadPreferencesAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Đọc lựa chọn layout, mặc định là grid (true) nếu chưa có
      _showAsGrid = prefs.getBool('library_screens_style') ?? true;
    });
    // Sau khi có layout, tải dữ liệu
    await _handleRefresh();
  }

  Future<void> _handleRefresh() async {
    // Tải lại tất cả dữ liệu song song để tối ưu tốc độ
    await Future.wait(
        [_loadPlaylists(), _loadFavorites(), _loadHistory()]);
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _historyService.getHistory();
      print('DEBUG history loaded: ${history.length} items');
      for (var h in history) {
        print('DEBUG history item: ${h.title} - ${h.artist}');
      }
      setState(() {
        _history = history;
      });
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.getPlaylistsByUser();
      setState(() {
        _playlists = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải playlist';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final data = await _favService.getFavorites();
      setState(() {
        _favorites = data;
      });
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Chuyển đổi layout',
            onPressed: () async {
              // Cập nhật trạng thái giao diện
              setState(() => _showAsGrid = !_showAsGrid);
              // Lưu lựa chọn mới vào SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('library_screens_style', _showAsGrid);
            },
            icon: Icon(_showAsGrid
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search in your library',
                        prefixIcon: Icon(Icons.search,
                            color: Theme.of(context).iconTheme.color),
                      ),
                      onSubmitted: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    // SingleChildScrollView(
                    //   scrollDirection: Axis.horizontal,
                    //   child: Row(
                    //     children: ['All', 'Playlists', 'Liked', 'History'].map((f) {
                    //       final bool selected = _activeFilter == f;
                    //       return Padding(
                    //         padding: const EdgeInsets.only(right: 8),
                    //         child: ChoiceChip(
                    //           label: Text(f),
                    //           selected: selected,
                    //           selectedColor: AppColors.oceanBlue.withOpacity(0.15),
                    //           side: BorderSide(
                    //             color: selected ? AppColors.oceanBlue : AppColors.oceanBlue.withOpacity(0.3),
                    //           ),
                    //           labelStyle: TextStyle(
                    //             color: selected ? AppColors.oceanDeep : AppColors.oceanDeep.withOpacity(0.8),
                    //             fontWeight: FontWeight.w600,
                    //           ),
                    //           onSelected: (_) => setState(() => _activeFilter = f),
                    //         ),
                    //       );
                    //     }).toList(),
                    //   ),
                    // ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          LibraryQuickAction(
                            icon: Icons.music_note,
                            label: 'ALL',
                            color: AppColors.oceanBlue,
                            isSelected: _activeFilter == 'All',
                            onTap: () {
                              setState(() => _activeFilter = 'All');
                            },
                          ),
                          const SizedBox(width: 10),
                          LibraryQuickAction(
                            icon: Icons.favorite,
                            label: 'Liked',
                            color: AppColors.oceanBlue,
                            isSelected: _activeFilter == 'Liked',
                            onTap: () {
                              setState(() => _activeFilter = 'Liked');
                            },
                          ),
                          const SizedBox(width: 10),
                          LibraryQuickAction(
                            icon: Icons.history,
                            label: 'History',
                            color: AppColors.skyBlue,
                            isSelected: _activeFilter == 'History',
                            onTap: () {
                              setState(() => _activeFilter = 'History');
                            },
                          ),
                          const SizedBox(width: 10),
                          LibraryQuickAction(
                            icon: Icons.playlist_add,
                            label: 'Playlists',
                            color: AppColors.oceanDeep,
                            isSelected: _activeFilter == 'Playlists',
                            onTap: () {
                              setState(() => _activeFilter = 'Playlists');
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _error!,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _buildContent(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistMenu(Playlist playlist, {bool useDarkIcon = true}) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: useDarkIcon ? Colors.white : null),
      onSelected: (value) {
        if (value == 'rename') {
          _showRenamePlaylistDialog(playlist);
        } else if (value == 'delete') {
          _showDeleteConfirmationDialog(playlist);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildContent() {
    if (_playlists.isEmpty && _favorites.isEmpty && _history.isEmpty) {
      return LibraryEmptyState(onCreatePlaylist: _showCreatePlaylistDialog);
    }

    final List<Widget> content = [];

    // Playlists Section
    if (_activeFilter == 'All' || _activeFilter == 'Playlists') {
      content.addAll([
        LibrarySectionHeader(title: 'Playlists 🎵', onSeeAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlaylistScreen()),
          );
        }),
        if (_playlists.isNotEmpty)
          _showAsGrid
              ? PlaylistPreviewGrid(
                  _playlists.toList(),
                  buildPlaylistMenu: (playlist) =>
                      _buildPlaylistMenu(playlist, useDarkIcon: true),
                  onTapPlaylist: (playlist) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PlaylistDetailScreen(playlist: playlist),
                      ),
                    ).then((_) => _loadPlaylists());
                  },
                )
              : PlaylistPreviewList(
                  _playlists.take(4).toList(),
                  buildPlaylistMenu: (playlist) =>
                      _buildPlaylistMenu(playlist, useDarkIcon: false),
                  onTapPlaylist: (playlist) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PlaylistDetailScreen(playlist: playlist),
                      ),
                    ).then((_) => _loadPlaylists());
                  },
                ),
        if (_activeFilter == 'All') const SizedBox(height: 1),
      ]);
    }

    // Favorites Section
    if (_activeFilter == 'All' || _activeFilter == 'Liked') {
      content.addAll([
        LibrarySectionHeader(title: 'Bài hát yêu thích ❤️', onSeeAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavScreen()),
          );
        }),
        FavoritesPreviewList(
          favorites: _favorites.take(3).toList(),
          onDelete: (song) async {
            final result = await _favService.deleteFavoriteById(song.id.toString());
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
            }
            _loadFavorites();
          },),
        if (_activeFilter == 'All') const SizedBox(height: 1),
      ]);
    }

    // History Section
    if (_activeFilter == 'All' || _activeFilter == 'History') {
      content.addAll([
        LibrarySectionHeader(title: 'Lịch sử nghe gần đây 🕒', onSeeAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
        }),
        HistoryPreviewList(
            history: _history.take(3).toList(), formatDate: _formatDate),
      ]);
    }

    return Column(children: content);
  }

  Future<void> _showRenamePlaylistDialog(Playlist playlist) async {
    final nameController = TextEditingController(text: playlist.name);
    final descController = TextEditingController(text: playlist.description);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Playlist'),
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
                    token, playlist.id, name, desc);
                Navigator.pop(context, updatedData);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Playlist updated!')),
      );
      await _loadPlaylists();
    }
  }

  Future<void> _showDeleteConfirmationDialog(Playlist playlist) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Playlist?'),
        content: Text(
            'Bạn có chắc chắn muốn xóa playlist "${playlist.name}" không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final success = await ApiPlaylist.deletePlaylist(token, playlist.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Đã xóa playlist "${playlist.name}"'
                : 'Xóa playlist thất bại.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
      if (success) await _loadPlaylists();
    }
  }

  Future<void> _showCreatePlaylistDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration:
                    const InputDecoration(hintText: 'Description (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
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
                  Navigator.pop(context, false);
                  return;
                }
                final ok = await ApiPlaylist.createPlaylist(token, name, desc);
                Navigator.pop(context, ok);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (created == true) {
      await _loadPlaylists();
      await _loadFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist created')),
      );
    }
  }
}
