import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/album.dart';

class AlbumService {
  static const String baseApiUrl = 'https://backend-dacn-9l4w.onrender.com';

  static Future<List<Album>> fetchAlbums() async {
    final uri = Uri.parse("$baseApiUrl/api/albums");
    final response = await http.get(Uri.parse("$baseApiUrl/api/albums"));
    print(response.body);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Album.fromJson(json)).toList();
    } else {
      throw Exception("Lỗi tải album: ${response.statusCode}");
    }
  }
}
