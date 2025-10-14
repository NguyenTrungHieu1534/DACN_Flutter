import 'package:flutter/material.dart';
import '../models/favSongs.dart';
import '../services/api_favsongs.dart';
import '../widgets/FavoriteSongList.dart';

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
    appBar: AppBar(
      title: Text("Yêu Thích"),
      centerTitle: true,
      backgroundColor: Color.fromARGB(255, 112, 150, 193),
      elevation: 0,
    ),
    backgroundColor: Colors.transparent,
     
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 112, 150, 193), // xanh ngọc retro
            Color(0xFFFFFFFF), // trắng pastel
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: FutureBuilder<List<FavoriteSong>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi tải dữ liệu 😢"));
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
  );
}

}
