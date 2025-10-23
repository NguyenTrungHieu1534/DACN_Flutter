// lib/services/api_lyrics.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LyricsService {
  static const String baseUrl = "https://backend-dacn-9l4w.onrender.com";

  Future<Map<String, dynamic>?> fetchLyrics({
    required String songId,
    required String artist,
    required String title,
  }) async {
    final url = Uri.parse("$baseUrl/api/lyrics");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "_id": songId,
          "artist": artist,
          "title": title,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "id": data["_id"],
          "title": data["title"],
          "artist": data["artist"],
          "lyrics": data["lyrics"],
          "cached": data["cached"] ?? false,
        };
      }

      print("fetchLyrics failed: ${response.statusCode} ${response.body}");
      return null;
    } catch (e) {
      print("fetchLyrics error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchLyricsURL({
    required String artist,
    required String title,
  }) async {
    final url = Uri.parse("$baseUrl/api/lyricURL");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "artist": artist,
          "title": title,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "title": data["title"],
          "artist": data["artist"],
          "url": data["url"], // URL của lyrics
        };
      }

      print("fetchLyricsURL failed: ${response.statusCode} ${response.body}");
      return null;
    } catch (e) {
      print("fetchLyricsURL error: $e");
      return null;
    }
  }
}
