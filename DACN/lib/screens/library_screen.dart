import 'package:flutter/material.dart';
import 'package:music_login/screens/fav_screen.dart';
import '../theme/app_theme.dart';
import '/screens/playlist_screen.dart';
import '../screens/history_screen.dart';
import '../services/api_playlist.dart';
import '../models/playlist.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
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
            icon: Icon(_showAsGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
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
                      prefixIcon: Icon(Icons.search, color: AppColors.oceanDeep),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Playlists', 'Liked', 'History'].map((f) {
                        final bool selected = _activeFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: selected,
                            selectedColor: AppColors.oceanBlue.withOpacity(0.15),
                            side: BorderSide(
                              color: selected ? AppColors.oceanBlue : AppColors.oceanBlue.withOpacity(0.3),
                            ),
                            labelStyle: TextStyle(
                              color: selected ? AppColors.oceanDeep : AppColors.oceanDeep.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) => setState(() => _activeFilter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _quickAction(
                        icon: Icons.favorite,
                        label: 'Liked',
                        color: AppColors.oceanBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        icon: Icons.history,
                        label: 'History',
                        color: AppColors.skyBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        icon: Icons.playlist_add,
                        label: 'Playlists',
                        color: AppColors.oceanDeep,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlaylistScreen()),
                          );
                        },
                      ),
                    ],
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
          else if (_filteredPlaylists().isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _emptyStateCard(),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: _showAsGrid ? _buildGridSection() : _buildListSection(),
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
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.oceanBlue.withOpacity(0.15)),
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

  SliverGrid _buildGridSection() {
    final items = _filteredPlaylists();
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _collectionCard(
            title: item.name,
            subtitle: 'Playlist • ${item.songs.length} songs',
          );
        },
        childCount: items.length,
      ),
    );
  }

  SliverList _buildListSection() {
    final items = _filteredPlaylists();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
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
              trailing: const Icon(Icons.chevron_right, color: AppColors.oceanDeep),
              onTap: () {},
            ),
          );
        },
        childCount: items.length,
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
            style: TextStyle(color: AppColors.oceanDeep.withOpacity(0.7), fontSize: 12),
          )
        ],
      ),
    );
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

  List<Playlist> _filteredPlaylists() {
    final query = _searchController.text.trim().toLowerCase();
    final base = _playlists;
    final filteredByQuery = query.isEmpty
        ? base
        : base.where((p) => p.name.toLowerCase().contains(query)).toList();
    switch (_activeFilter) {
      case 'Playlists':
      case 'All':
        return filteredByQuery;
      default:
        return filteredByQuery; // future: add other categories
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
                decoration: const InputDecoration(hintText: 'Description (optional)'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist created')),
      );
    }
  }
}
