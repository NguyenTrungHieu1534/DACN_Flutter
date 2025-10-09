import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/songs.dart';

class Songservice {
  static Future<List<Songs>> fetchSongs() async {
    final url = Uri.parse('https://backend-dacn-9l4w.onrender.com/api/songs');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final songs = data.map((e) => Songs.fromJson(e)).toList();
      print('Fetched ${songs.length} songs');
      return songs;
    } else {
      throw Exception('Lỗi tải album: ${response.statusCode}');
    }
  }
}
