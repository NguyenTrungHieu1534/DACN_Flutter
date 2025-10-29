import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/album.dart';
import '../models/songs.dart';

class AlbumService {
  static Future<List<Album>> fetchAlbums() async {
    final url = Uri.parse('https://backend-dacn-9l4w.onrender.com/api/albums');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final albums = data.map((e) => Album.fromJson(e)).toList();
      return albums;
    } else {
      throw Exception('Lỗi tải album: ${response.statusCode}');
    }
  }

  static Future<List<Songs>> fetchSongsByAlbum(String album) async {
    final encodedAlbum = Uri.encodeComponent(album);
    final url =
        'https://backend-dacn-9l4w.onrender.com/api/albums/$encodedAlbum/songs';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final songsJson = data['songs'] as List;
      return songsJson.map((e) => Songs.fromJson(e)).toList();
    } else {
      throw Exception('Không thể tải danh sách bài hát của album này');
    }
  }
  static Future<String> fetchAlbumCover(String albumName) async {
    try {
      final encodedName = Uri.encodeComponent(albumName.trim());
      final response = await http.get(Uri.parse('https://backend-dacn-9l4w.onrender.com/api/albums/cover/$encodedName'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] ?? '/default-covers/no-cover.jpg';
      } else {
        throw Exception('Failed to load album cover');
      }
    } catch (e) {
      print('❌ Lỗi khi lấy cover album: $e');
      return '/default-covers/no-cover.jpg';
    }
  }
}
