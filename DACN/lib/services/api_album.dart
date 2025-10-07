import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/album.dart';

class AlbumService {
  static Future<List<Album>> fetchAlbums() async {
    final url = Uri.parse('https://backend-dacn-9l4w.onrender.com/api/albums');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final albums = data.map((e) => Album.fromJson(e)).toList();
      print('Fetched ${albums.length} albums');
      return albums;
    } else {
      throw Exception('Lỗi tải album: ${response.statusCode}');
    }
  }
}
