import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_songs.dart';
import '../models/songs.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchScreen> {
  List<Songs> results = [];
  List<String> history = ["Love", "Rap", "Chill"];
  bool isLoading = false;
  String selectedFilter = "All";
  final SongService songService = SongService();
  final TextEditingController searchController = TextEditingController();

  void handleSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      history.remove(query);
      history.insert(0, query);
    });

    final data = await songService.searchSongs(query);  
    
    if (data != null) {
      setState(() {
        results = data.map((e) => Songs.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        results = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: const Color.fromARGB(255, 163, 159, 170),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: handleSearch,
                decoration: const InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Row(
              children: ["All", "Songs", "Artists", "Albums"].map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: selectedFilter == type,
                    onSelected: (_) => setState(() => selectedFilter = type),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            
            Expanded(
              child: isLoading
                  ? _buildShimmerLoading()
                  : results.isNotEmpty
                      ? _buildResultList()
                      : _buildHistoryList(),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildResultList() {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return ListTile(
          leading: const Icon(Icons.music_note, color: Colors.white),
          title: Text(song.title!, style: const TextStyle(color: Colors.white)),
          subtitle: Text(song.artist!, style: const TextStyle(color: Colors.white70)),
        );
      },
    );
  }
  Widget _buildHistoryList() {
    return ListView(
      children: history.map((item) {
        return ListTile(
          leading: const Icon(Icons.history, color: Colors.white70),
          title: Text(item, style: const TextStyle(color: Colors.white)),
          onTap: () {
            searchController.text = item;
            handleSearch(item);
          },
        );
      }).toList(),
    );
  }
  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 60,
        color: Colors.grey.shade800,
      ),
    );
  }
}