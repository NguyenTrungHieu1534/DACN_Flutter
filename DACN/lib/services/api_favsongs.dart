import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favSongs.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class FavoriteService {
  final String baseUrl = "http://backend-dacn-9l4w.onrender.com";
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<FavoriteSong>> getFavorites() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      return [];
    }

    Map<String, dynamic> decoded = JwtDecoder.decode(token.toString());
    String username = decoded["username"];

    final response = await http.get(
      Uri.parse("$baseUrl/api/favorites/$username"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List data = body["data"];
      return data.map((e) => FavoriteSong.fromJson(e)).toList();
    } else {
      throw Exception("Không thể lấy dữ liệu yêu thích");
    }
  }

  Future<String> addFavorite(FavoriteSong song) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/api/add/favorite"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "title": song.title,
        "artist": song.artist,
        "album": song.album,
        "songId": song.songId,
      }),
    );

    return jsonDecode(response.body)['message'];
  }

  // ✅ 3. Xóa yêu thích bằng `_id`
  Future<String> deleteFavoriteById(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/api/unfavorite"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"id": id}),
    );

    return jsonDecode(response.body)['message'];
  }

  Future<String> deleteFavoriteBySongId(String songId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/api/delete/favoriteSong"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"songId": songId}),
    );

    return jsonDecode(response.body)['message'];
  }
}
