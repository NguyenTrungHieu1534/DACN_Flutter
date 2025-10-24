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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['lyrics'] != null &&
            data['lyrics'].toString().trim().isNotEmpty) {
          return {
            "id": data["_id"],
            "title": data["title"],
            "artist": data["artist"],
            "lyrics": data["lyrics"],
            "cached": data["cached"] ?? false,
          };
        }

        return {
          "id": data["_id"],
          "title": data["title"] ?? title,
          "artist": data["artist"] ?? artist,
          "lyrics": null,
          "processing": true,
          "message":
              data["message"] ?? "Lyrics đang được lấy, vui lòng thử lại sau.",
        };
      }
      print("fetchLyrics failed: ${response.statusCode} ${response.body}");
      return {
        "id": data["_id"] ?? songId,
        "title": title,
        "artist": artist,
        "lyrics": null,
        "error": true,
        "message":
            data["message"] ?? "Không tìm thấy lyrics, fallback sang URL",
      };
    } catch (e) {
      print("fetchLyrics error: $e");
      return {
        "id": songId,
        "title": title,
        "artist": artist,
        "lyrics": null,
        "error": true,
        "message": "Lỗi khi gọi API lyrics",
      };
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
