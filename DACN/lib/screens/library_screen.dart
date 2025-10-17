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
    _loadPlaylists();
    _loadFavorites();
    _loadHistory();
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
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Toggle layout',
            onPressed: () => setState(() => _showAsGrid = !_showAsGrid),
            icon: Icon(_showAsGrid
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
          ),
        ],
      ),
      body: CustomScrollView(
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
                    decoration: const InputDecoration(
                      hintText: 'Search in your library',
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.oceanDeep),
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
                        _quickAction(
                          icon: Icons.music_note,
                          label: 'ALL',
                          color: AppColors.oceanBlue,
                          isSelected: _activeFilter == 'All',
                          onTap: () {
                            setState(() => _activeFilter = 'All');
                          },
                        ),
                        const SizedBox(width: 10),
                        _quickAction(
                          icon: Icons.favorite,
                          label: 'Liked',
                          color: AppColors.oceanBlue,
                          isSelected: _activeFilter == 'Liked',
                          onTap: () {
                            setState(() => _activeFilter = 'Liked');
                          },
                        ),
                        const SizedBox(width: 10),
                        _quickAction(
                          icon: Icons.history,
                          label: 'History',
                          color: AppColors.skyBlue,
                          isSelected: _activeFilter == 'History',
                          onTap: () {
                            setState(() => _activeFilter = 'History');
                          },
                        ),
                        const SizedBox(width: 10),
                        _quickAction(
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
                  style: const TextStyle(color: AppColors.oceanDeep),
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
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return SizedBox(
      width: 120,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : AppColors.oceanBlue.withOpacity(0.15),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.oceanDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collectionCard({required String title, required String subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.skyBlue.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.album, size: 36, color: AppColors.oceanBlue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.oceanDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppColors.oceanDeep.withOpacity(0.7), fontSize: 12),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String type, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.oceanDeep,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(
                color: AppColors.oceanBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewGrid(List<Playlist> playlists) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final item = playlists[index];
        return _collectionCard(
          title: item.name,
          subtitle: 'Playlist • ${item.songs.length} songs',
        );
      },
    );
  }

  Widget _buildPreviewList(List<Playlist> playlists) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final item = playlists[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.oceanBlue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.queue_music, color: AppColors.oceanBlue),
            ),
            title: Text(
              item.name,
              style: const TextStyle(
                color: AppColors.oceanDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Playlist • ${item.songs.length} songs',
              style: TextStyle(color: AppColors.oceanDeep.withOpacity(0.7)),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.oceanDeep),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(List<FavoriteSong> favorites) {
    if (favorites.isEmpty) {
      return const Center(
        child: Text('No favorite songs yet',
            style: TextStyle(color: AppColors.oceanDeep)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final song = favorites[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.oceanBlue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: AppColors.oceanBlue),
            ),
            title: Text(
              song.title,
              style: const TextStyle(
                color: AppColors.oceanDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(color: AppColors.oceanDeep.withOpacity(0.7)),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.oceanDeep),
            onTap: () {}, // Navigate to song detail or start playing
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<HistorySong> history) {
    if (history.isEmpty) {
      return const Center(
        child: Text('No listening history yet',
            style: TextStyle(color: AppColors.oceanDeep)),
      );
    }

    return Column(
      children: history
          .map((song) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.oceanBlue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.history, color: AppColors.oceanBlue),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(
                      color: AppColors.oceanDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${song.artist} • ${_formatDate(song.playedAt)}',
                    style:
                        TextStyle(color: AppColors.oceanDeep.withOpacity(0.7)),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.oceanDeep),
                  onTap: () {},
                ),
              ))
          .toList(),
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

  Widget _emptyStateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No collections yet',
            style: TextStyle(
              color: AppColors.oceanDeep,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first playlist to get started.',
            style: TextStyle(color: AppColors.oceanDeep.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _showCreatePlaylistDialog,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Create playlist'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_playlists.isEmpty && _favorites.isEmpty && _history.isEmpty) {
      return _emptyStateCard();
    }

    final List<Widget> content = [];

    // Playlists Section
    if (_activeFilter == 'All' || _activeFilter == 'Playlists') {
      content.addAll([
        _buildSectionTitle('Playlists 🎵', 'Playlists', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlaylistScreen()),
          );
        }),
        if (_playlists.isNotEmpty)
          _showAsGrid
              ? _buildPreviewGrid(_playlists)
              : _buildPreviewList(_playlists),
        if (_activeFilter == 'All') const SizedBox(height: 1),
      ]);
    }

    // Favorites Section
    if (_activeFilter == 'All' || _activeFilter == 'Liked') {
      content.addAll([
        _buildSectionTitle('Bài hát yêu thích ❤️', 'Liked', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavScreen()),
          );
        }),
        _buildFavoritesList(_favorites),
        if (_activeFilter == 'All') const SizedBox(height: 1),
      ]);
    }

    // History Section
    if (_activeFilter == 'All' || _activeFilter == 'History') {
      content.addAll([
        _buildSectionTitle('Lịch sử nghe gần đây 🕒', 'History', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
        }),
        _buildHistoryList(_history),
      ]);
    }

    return Column(children: content);
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
