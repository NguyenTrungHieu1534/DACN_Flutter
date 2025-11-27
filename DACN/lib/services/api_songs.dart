import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/songs.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final url = Uri.parse(
        'https://backend-dacn-9l4w.onrender.com/api/search?query=$query');

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

  static Future<String> fetchSongUrl(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url =
        Uri.parse('https://backend-dacn-9l4w.onrender.com/api/play/$songId');

    final response = await http.get(
      url,
      headers: {
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Không thể lấy URL bài hát');
    }
  }

  static Future<Songs?> fetchSongById(String songId) async {
    if (songId.isEmpty) return null;

    try {
      final directUrl =
          Uri.parse('https://backend-dacn-9l4w.onrender.com/api/songs/$songId');
      final response = await http.get(directUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return Songs.fromJson(data);
        }
        if (data is List && data.isNotEmpty) {
          final first = data.first;
          if (first is Map<String, dynamic>) {
            return Songs.fromJson(first);
          }
        }
      }
    } catch (_) {}

    try {
      final songs = await fetchSongs();
      for (final song in songs) {
        if (song.id == songId) return song;
      }
    } catch (_) {
      // ignore and return null
    }

    return null;
  }
//   Future<Map<String, dynamic>?> fetchLyrics({
//   required String songId,
//   required String artist,
//   required String title,
// }) async {
//   final url = Uri.parse("http://<YOUR_SERVER_IP>:<PORT>/api/lyrics");

//   try {
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         "_id": songId,
//         "artist": artist,
//         "title": title,
//       }),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);

//       return {
//         "id": data["_id"],
//         "title": data["title"],
//         "artist": data["artist"],
//         "lyrics": data["lyrics"],
//         "cached": data["cached"] ?? false,
//       };
//     } else {
//       return null;
//     }
//   } catch (e) {
//     return null;
//   }
// }
  Future<void> reportSong({
    required String songId,
    required String reason,
  }) async {
    final url =
        Uri.parse('https://backend-dacn-9l4w.onrender.com/api/songs/report');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final String userId = decodedToken['_id'];
    final body = jsonEncode({
      'songid': songId,
      'userId': userId,
      'reason': reason,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Success: ${data['message']}');
      } else {
        final data = jsonDecode(response.body);
        print('Error: ${data['message']}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  static Future<Songs> fetchSongDetailsById(String songId) async {
    final response = await http.get(
      Uri.parse('https://backend-dacn-9l4w.onrender.com/api/songsin4/$songId'),
    );

    if (response.statusCode == 200) {
      return Songs.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Không thể tải chi tiết bài hát');
    }
  }
}
