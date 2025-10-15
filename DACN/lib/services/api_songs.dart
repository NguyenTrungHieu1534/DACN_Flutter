import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/songs.dart';

class SongService {
    static Future<List<Songs>> fetchSongs() async {
      final url = Uri.parse('https://backend-dacn-9l4w.onrender.com/api/songs');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final songs = data.map((e) => Songs.fromJson(e)).toList();
        return songs;
      } else {
        throw Exception('Lỗi tải album: ${response.statusCode}');
      }
    }
    Future<List<dynamic>> searchSongs(String query) async {
    final url = Uri.parse('https://backend-dacn-9l4w.onrender.com/api/search?query=$query');

    final response = await http.get(url);
    print("Response status: ${response.statusCode}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 400 || response.statusCode == 404) {
      throw Exception(jsonDecode(response.body)['message']);
    } else {
      throw Exception('Lỗi server!');
    }
  }
}
