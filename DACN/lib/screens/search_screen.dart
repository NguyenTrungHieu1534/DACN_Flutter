import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_songs.dart';
import '../models/songs.dart';
import 'package:provider/provider.dart';
import '../models/AudioPlayerProvider.dart';
import 'player_screen.dart';
import 'album_detail_screen.dart';
import 'artist_detail_screen.dart';
import '../services/api_album.dart';
import '../services/api_user.dart';
import 'user_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchScreen> {
  List<Songs> songResults = [];
  List<Map<String, dynamic>> artistResults = [];
  List<Map<String, dynamic>> albumResults = [];
  List<Map<String, dynamic>> userResults = [];
  List<String> history = ["Love", "Rap", "Chill"];
  bool isLoading = false;
  String selectedFilter = "All";
  String _activeQuery = '';
  final SongService songService = SongService();
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  final UserService _userService = UserService();
  final int _minQueryLength = 3;

  void handleSearch(String query) async {
if (query.trim().isEmpty) return;

 if (!mounted) return;
setState(() {
isLoading = true;

history.remove(query);
history.insert(0, query);
});
try {
 final data = await songService.searchSongs(query);
final users = await _userService.searchUsers(query); 
 
 final List<Songs> songs = [];
 final List<Map<String, dynamic>> artists = [];
final List<Map<String, dynamic>> albumsData = [];
for (final item in data) {
 if (item is Map<String, dynamic>) {
 final type = item['type'];
 if (type == 'song' || item.containsKey('mp3Url')) {
 songs.add(Songs.fromJson(item));
 } else if (type == 'album' || (item.containsKey('name') && item.containsKey('artist'))) {
 albumsData.add(item);
} else if (type == 'artist' || item.containsKey('followerCount')) {

 artists.add(item);
}
}
 }
      
final Map<String, String> albumCoverCache = {};
      
 final updatedSongs = await Future.wait(
 songs.map((song) async {
if (song.thumbnail.isNotEmpty) return song;
final albumName = song.album;
 if (albumName.isEmpty) return song; 

if (!albumCoverCache.containsKey(albumName)) {
 albumCoverCache[albumName] = await AlbumService.fetchAlbumCover(albumName);
 }
 return song.copyWith(thumbnail: albumCoverCache[albumName]);
 }),
 );
 final updatedAlbums = await Future.wait(
 albumsData.map((album) async {
 final albumName = album['name'];
 final imageUrl = album['image'] as String?;
 if (imageUrl != null && imageUrl.isNotEmpty) return album;
 if (!albumCoverCache.containsKey(albumName)) {
 albumCoverCache[albumName] = await AlbumService.fetchAlbumCover(albumName);
 }
 return {
 ...album,
'image': albumCoverCache[albumName],
 };
 }),
);
 if (!mounted) return;
 setState(() {
 songResults = updatedSongs;

artistResults = artists.isNotEmpty ? artists : _deriveArtistsFromSongs(updatedSongs);
 albumResults = updatedAlbums.isNotEmpty ? updatedAlbums : _deriveAlbumsFromSongs(updatedSongs);
 userResults = users;
 isLoading = false;
 });
 } catch (e) {
 print("Search error: $e");
if (!mounted) return;
 setState(() {
 songResults = [];
 artistResults = [];
 albumResults = [];
 userResults = [];
 isLoading = false;
 });
 }
 }

  void _onQueryChanged(String value) {
 final trimmedValue = value.trim();
 _debounce?.cancel();
 
 final bool isShortOrEmpty = trimmedValue.isEmpty || trimmedValue.length < _minQueryLength;

 if (isShortOrEmpty) {
 if (!mounted) return;
 setState(() {
 songResults = [];
 artistResults = [];
 albumResults = [];
 userResults = [];
 _activeQuery = '';
 });
 return;
 }

 if (!mounted) return;
 setState(() {
 _activeQuery = trimmedValue;
 if (selectedFilter != 'All') { 
 selectedFilter = 'All';
 }
 });
 _debounce = Timer(const Duration(milliseconds: 250), () {
 if (!mounted) return;
 handleSearch(trimmedValue); 
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
      final albumName = (s.album).trim();
      if (albumName.isEmpty) continue;
      final key = albumName.toLowerCase();
      if (seen.add(key)) {
        derived.add({
          'name': albumName,
          'artist': s.artist,
          'image': s.thumbnail,
        });
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, albums...',                  
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                ),
              ),
            ),

            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["All", "Users", "Songs", "Artists", "Albums"].map((type) {
                  final bool selected = selectedFilter == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      side: BorderSide(
                        color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                      labelStyle: TextStyle(
                        color: selected ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
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

  Widget _buildSectionedResults() {
    final List<Widget> sections = [];

    bool show(String section) => selectedFilter == 'All' || selectedFilter == section;

    if (show('Users') && userResults.isNotEmpty) {
      sections.add(_sectionHeader('Người dùng'));
      sections.addAll(userResults.map((u) => _userTile(u)));
    }
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
        style: TextStyle(
          color: Theme.of(context).textTheme.headlineSmall?.color,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _userTile(Map<String, dynamic> user) {
    final id = (user['id'] ?? user['_id'] ?? '').toString();
    final name = (user['username'] ?? '').toString();
    final ava = (user['ava'] ?? '').toString();
    final isPrivate = user['isPrivate'] == true;
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: ava.isNotEmpty ? NetworkImage(ava) : null,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: ava.isEmpty ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary) : null,
        ),
        title: Text(
          name.isNotEmpty ? name : 'Unknown',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: isPrivate
            ? Text('Private', style: TextStyle(color: Theme.of(context).colorScheme.error.withOpacity(0.8)))
            : null,
        onTap: () {
          if (id.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserScreen(),
              settings: RouteSettings(arguments: {'viewUserId': id}),
            ),
          );
        },
      ),
    );
  }

  Widget _songTile(Songs song) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: song.thumbnail.isNotEmpty ? NetworkImage(song.thumbnail) : null,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: song.thumbnail.isEmpty ? Icon(Icons.music_note, color: Theme.of(context).colorScheme.onPrimary) : null,
        ),
        title: Text(
          song.title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          song.artist,
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
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
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArtistDetailScreen(artistName: name),
            ),
          );
        },
      ),
    );
  }

  Widget _albumTile(Map<String, dynamic> album) {
    final title = album['name'] ?? 'Unknown Album';
    final by = album['artist'] ?? '';
    final imageUrl = album['image'] as String?;

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          child: imageUrl == null || imageUrl.isEmpty ? Icon(Icons.album, color: Theme.of(context).colorScheme.primary) : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: by.isNotEmpty ? Text(by, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))) : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlbumDetailScreen(
                albumName: title,
                albumImage: imageUrl ?? '',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView(
      children: history.map((item) {
        return Card(
          color: Theme.of(context).cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(
              item,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w500),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.12)),
        ),
      ),
    );
  }
}