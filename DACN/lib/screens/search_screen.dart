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
    
    try {
      setState(() {
        results = data.map((e) => Songs.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        results = [];
        isLoading = false;
        // Optionally display an error message to the user
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Error: ${e.toString()}')),
        // );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.retroWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.retroPrimary,
            foregroundColor: AppColors.retroWhite,
            title: const Text('Search'),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.retroWhite,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: searchController,
                      onSubmitted: handleSearch,
                      decoration: const InputDecoration(
                        hintText: 'Search songs, artists, albums...',
                        prefixIcon: Icon(Icons.search, color: AppColors.retroAccent),
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
                          selectedColor: AppColors.retroAccent, 
                          labelStyle: TextStyle(color: selectedFilter == type ? AppColors.retroWhite : AppColors.retroAccent), 
                          backgroundColor: AppColors.retroWhite, 
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
               ],
             ),
           ),
         ),
         SliverFillRemaining(
           hasScrollBody: true,
           child: isLoading
               ? _buildShimmerLoading()
               : results.isNotEmpty
                   ? _buildResultList()
                   : _buildHistoryList(),
         )
       ],
      ),
    );
  }
  Widget _buildResultList() {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return ListTile(
          leading: const Icon(Icons.music_note, color: AppColors.retroAccent),
          title: Text(song.title, style: const TextStyle(color: AppColors.retroAccent)),
          subtitle: Text(song.artist, style: TextStyle(color: AppColors.retroAccent.withOpacity(0.7))), 
        );
      },
    );
  }
  Widget _buildHistoryList() {
    return ListView(
      children: history.map((item) {
        return ListTile(
          leading: Icon(Icons.history, color: AppColors.retroAccent.withOpacity(0.7)),
          title: Text(item, style: const TextStyle(color: AppColors.retroAccent)),
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
        color: AppColors.retroPrimary.withOpacity(0.3),
      ),
    );
  }
}