import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favSongs.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/songs.dart';

class FavoriteService {
  final String baseUrl = "http://backend-dacn-9l4w.onrender.com";
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<FavoriteSong>> getFavorites() async {
    try {
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
        if (response.body.isNotEmpty) {
          final body = jsonDecode(response.body);
          if (body is Map && body.containsKey("data")) {
            List data = body["data"];
            return data.map((e) => FavoriteSong.fromJson(e)).toList();
          } else {
            return [];
          }
        } else {
          return [];
        }
      } else {
        throw Exception("Không thể lấy dữ liệu yêu thích (${response.statusCode})");
      }
    } catch (e) {
      print("Error getting favorites: $e");
      return [];
    }
  }

  Future<String> addFavorite(Songs song) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return "⚠️ Bạn chưa đăng nhập!";
      }

      final response = await http.post(
        Uri.parse("https://backend-dacn-9l4w.onrender.com/api/add/favorite"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "title": song.title,
          "artist": song.artist,
          "album": song.album,
          "songId": song.id,
        }),
      );

      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? " Đã thêm vào yêu thích";
      } else if (response.statusCode == 400) {
        return "⚠️ Bài hát đã có trong danh sách yêu thích!";
      } else if (response.statusCode == 401) {
        return "Token không hợp lệ hoặc đã hết hạn!";
      } else {
        return "Lỗi máy chủ (${response.statusCode})";
      }
    } catch (e) {
      print("Error adding favorite: $e");
      return " Không thể kết nối server";
    }
  }
  Future<String> deleteFavoriteById(String songId) async {
    try {
      final token = await _getToken();
      print(" Gửi yêu cầu xóa bài hát $songId");

      final response = await http.delete(
        Uri.parse("https://backend-dacn-9l4w.onrender.com/api/unfavorite"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"id": songId}),
      );

      print("Response: ${response.body}");
      
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          return data['message'] ?? "Đã xóa khỏi yêu thích";
        } else {
          return "Đã xóa khỏi yêu thích";
        }
      } else {
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          return data['message'] ?? " Lỗi xóa bài hát";
        } else {
          return "Lỗi xóa bài hát (${response.statusCode})";
        }
      }
    } catch (e) {
      print("Error deleting favorite: $e");
      return "Không thể kết nối server";
    }
  }
}
