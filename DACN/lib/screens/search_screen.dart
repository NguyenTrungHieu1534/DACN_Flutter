import 'package:flutter/material.dart';
import 'dart:ui';
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.75),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Search',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: TextField(
                                controller: searchController,
                                onSubmitted: handleSearch,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Songs, artists, albums',
                                  prefixIcon: const Icon(Icons.search, color: Colors.black87),
                                  suffixIcon: searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close, color: Colors.black54),
                                          onPressed: () {
                                            setState(() {
                                              searchController.clear();
                                              results = [];
                                            });
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ["All", "Songs", "Artists", "Albums"].map((type) {
                                  final bool isSelected = selectedFilter == type;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(type),
                                      selected: isSelected,
                                      onSelected: (_) => setState(() => selectedFilter = type),
                                      selectedColor: Colors.black,
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      backgroundColor: Colors.black.withOpacity(0.06),
                                      side: BorderSide(
                                        color: Colors.black12,
                                      ),
                                    ),
                                  );
                                }).toList(),
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
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            sliver: SliverFillRemaining(
              hasScrollBody: true,
              child: isLoading
                  ? _buildShimmerLoading()
                  : results.isNotEmpty
                      ? _buildResultList()
                      : _buildHistoryList(),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildResultList() {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, index) {
        final song = results[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.thumbnail.isNotEmpty
                  ? Image.network(
                      song.thumbnail,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 54,
                      height: 54,
                      color: Colors.black12,
                      child: const Icon(Icons.music_note_rounded, color: Colors.black45),
                    ),
            ),
            title: Text(
              song.title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                song.artist,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black54),
              onPressed: () {},
            ),
            onTap: () {},
          ),
        );
      },
    );
  }
  Widget _buildHistoryList() {
    return ListView.separated(
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, index) {
        final item = history[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            leading: const Icon(Icons.history_rounded, color: Colors.black45),
            title: Text(
              item,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(Icons.north_west_rounded, color: Colors.black54),
            onTap: () {
              searchController.text = item;
              handleSearch(item);
            },
          ),
        );
      },
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