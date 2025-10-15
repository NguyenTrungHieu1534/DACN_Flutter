import 'package:flutter/material.dart';
import '../models/favSongs.dart';
import '../services/api_favsongs.dart';
import '../widgets/FavoriteSongList.dart';
import '../theme/app_theme.dart';

class FavScreen extends StatefulWidget {
  const FavScreen({Key? key}) : super(key: key);

  @override
  _FavScreenState createState() => _FavScreenState();
}

class _FavScreenState extends State<FavScreen> {
  late FavoriteService _favService;
  late Future<List<FavoriteSong>> _favoritesFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _favService = FavoriteService();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favService.getFavorites().then((favorites) {
      setState(() {
        _favoritesFuture = Future.value(favorites);
      });
      print("fav data: $favorites");
    }).catchError((err) {
      print("Error loading favorites: $err");
    });
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
          title: const Text('Yêu Thích'),
          pinned: true,
        ),
        SliverFillRemaining(
          hasScrollBody: true,
          child: FutureBuilder<List<FavoriteSong>>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.retroAccent),
                ));
              }

              if (snapshot.hasError) {
                return Center(child: Text("Lỗi tải dữ liệu 😢", style: TextStyle(color: AppColors.retroAccent),));
              }

              final favorites = snapshot.data ?? [];

              return FavoriteSongList(
                songs: favorites,
                onDelete: (song) async {
                  await _favService.deleteFavoriteBySongId(song.songId);
                  _loadFavorites();
                },
                onTap: (song) {},
              );
            },
          ),
        ),
      ],
    ),
  );
}

}
