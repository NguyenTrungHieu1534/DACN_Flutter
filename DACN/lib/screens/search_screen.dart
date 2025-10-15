import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_songs.dart';
import '../models/songs.dart';
import 'package:provider/provider.dart';
import '../models/AudioPlayerProvider.dart';
import 'player_screen.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchScreen> {
  List<Songs> songResults = [];
  List<Map<String, dynamic>> artistResults = [];
  List<Map<String, dynamic>> albumResults = [];
  List<String> history = ["Love", "Rap", "Chill"];
  bool isLoading = false;
  String selectedFilter = "All";
  final SongService songService = SongService();
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  void handleSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      history.remove(query);
      history.insert(0, query);
    });

    try {
      final data = await songService.searchSongs(query);
      final List<Songs> songs = [];
      final List<Map<String, dynamic>> artists = [];
      final List<Map<String, dynamic>> albums = [];

      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final type = item['type'];
          if (type == 'song' || item.containsKey('title')) {
            songs.add(Songs.fromJson(item));
          } else if (type == 'album' || (item.containsKey('name') && item.containsKey('artist'))) {
            albums.add(item);
          } else if (type == 'artist' || item.containsKey('name')) {
            artists.add(item);
          }
        }
      }

      setState(() {
        songResults = songs;
        artistResults = artists.isNotEmpty ? artists : _deriveArtistsFromSongs(songs);
        albumResults = albums.isNotEmpty ? albums : _deriveAlbumsFromSongs(songs);
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        songResults = [];
        artistResults = [];
        albumResults = [];
        isLoading = false;
      });
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (value.trim().isNotEmpty) {
        handleSearch(value.trim());
      } else {
        setState(() {
          songResults = [];
          artistResults = [];
          albumResults = [];
        });
      }
    });
  }

  List<Map<String, dynamic>> _deriveArtistsFromSongs(List<Songs> songs) {
    final seen = <String>{};
    final List<Map<String, dynamic>> derived = [];
    for (final s in songs) {
      final name = (s.artist).trim();
      if (name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) {
        derived.add({'name': name});
      }
    }
    // Optional: sort by name
    derived.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return derived;
  }

  List<Map<String, dynamic>> _deriveAlbumsFromSongs(List<Songs> songs) {
    final seen = <String>{};
    final List<Map<String, dynamic>> derived = [];
    for (final s in songs) {
      final albumName = (s.albuml).trim();
      if (albumName.isEmpty) continue;
      final key = albumName.toLowerCase();
      if (seen.add(key)) {
        derived.add({'name': albumName, 'artist': s.artist});
      }
    }
    derived.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return derived;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              elevation: 0,
              color: Colors.transparent,
              child: TextField(
                controller: searchController,
                onChanged: _onQueryChanged,
                onSubmitted: handleSearch,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  prefixIcon: Icon(Icons.search, color: AppColors.oceanDeep),
                ),
              ),
            ),

            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["All", "Songs", "Artists", "Albums"].map((type) {
                  final bool selected = selectedFilter == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      selectedColor: AppColors.oceanBlue.withOpacity(0.15),
                      side: BorderSide(
                        color: selected ? AppColors.oceanBlue : AppColors.oceanBlue.withOpacity(0.3),
                      ),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.oceanDeep : AppColors.oceanDeep.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => selectedFilter = type),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? _buildShimmerLoading()
                  : (songResults.isEmpty && artistResults.isEmpty && albumResults.isEmpty)
                      ? _buildHistoryList()
                      : _buildSectionedResults(),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildResultList() {
    return ListView.builder(
      itemCount: songResults.length,
      itemBuilder: (context, index) {
        final song = songResults[index];
        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.oceanBlue,
              child: Icon(Icons.music_note, color: Colors.white),
            ),
            title: Text(
              song.title ?? '-',
              style: const TextStyle(
                color: AppColors.oceanDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              song.artist ?? '-',
              style: TextStyle(color: AppColors.oceanDeep.withOpacity(0.7)),
            ),
            onTap: () async {
              try {
                await context.read<AudioPlayerProvider>().playSong(song);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(song: song),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không thể phát bài hát này')),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionedResults() {
    final List<Widget> sections = [];

    bool show(String section) => selectedFilter == 'All' || selectedFilter == section;

    if (show('Songs') && songResults.isNotEmpty) {
      sections.add(_sectionHeader('Bài hát'));
      sections.addAll(songResults.map((s) => _songTile(s)));
    }
    if (show('Artists') && artistResults.isNotEmpty) {
      sections.add(_sectionHeader('Nghệ sĩ'));
      sections.addAll(artistResults.map((a) => _artistTile(a)));
    }
    if (show('Albums') && albumResults.isNotEmpty) {
      sections.add(_sectionHeader('Album'));
      sections.addAll(albumResults.map((a) => _albumTile(a)));
    }

    return ListView(
      children: sections,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.oceanDeep,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _songTile(Songs song) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.oceanBlue,
          child: Icon(Icons.music_note, color: Colors.white),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            color: AppColors.oceanDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          song.artist,
          style: TextStyle(color: AppColors.oceanDeep.withOpacity(0.7)),
        ),
        onTap: () async {
          try {
            await context.read<AudioPlayerProvider>().playSong(song);
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlayerScreen(song: song)),
            );
          } catch (_) {}
        },
      ),
    );
  }

  Widget _artistTile(Map<String, dynamic> artist) {
    final name = artist['name'] ?? artist['artist'] ?? 'Unknown Artist';
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.oceanBlue.withOpacity(0.15),
          child: const Icon(Icons.person, color: AppColors.oceanBlue),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: AppColors.oceanDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _albumTile(Map<String, dynamic> album) {
    final title = album['name'] ?? 'Unknown Album';
    final by = album['artist'] ?? '';
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.skyBlue.withOpacity(0.2),
          child: const Icon(Icons.album, color: AppColors.oceanBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.oceanDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: by.isNotEmpty ? Text(by, style: TextStyle(color: AppColors.oceanDeep.withOpacity(0.7))) : null,
        onTap: () {},
      ),
    );
  }
  Widget _buildHistoryList() {
    return ListView(
      children: history.map((item) {
        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.oceanBlue.withOpacity(0.2),
              child: const Icon(Icons.history, color: AppColors.oceanBlue),
            ),
            title: Text(
              item,
              style: const TextStyle(color: AppColors.oceanDeep, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              searchController.text = item;
              handleSearch(item);
            },
          ),
        );
      }).toList(),
    );
  }
  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.oceanBlue.withOpacity(0.12)),
        ),
      ),
    );
  }
}