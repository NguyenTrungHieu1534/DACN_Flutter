// lib/services/api_lyrics.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LyricsService {
  static const String baseUrl = "https://backend-dacn-9l4w.onrender.com";
  
  static Future<String?> fetchLyrics({
    required String artist,
    required String title,
    required String id,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lyrics'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'artist': artist,
          'title': title,
          '_id': id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['lyrics'] != null && data['lyrics'].toString().isNotEmpty) {
          return data['lyrics'];
        }
      } else {
        print("❌ API error: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Fetch lyrics error: $e");
    }
    return null;
  }
}
