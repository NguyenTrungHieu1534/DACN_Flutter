import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/models/history.dart';

class HistoryService {
  static const String baseUrl = "https://backend-dacn-9l4w.onrender.com";
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<HistorySong>> getHistory() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/api/history"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => HistorySong.fromJson(e)).toList();
    } else {
      throw Exception("Không thể lấy lịch sử nghe");
    }
  }

  Future<List<HistorySong>> getAllHistory() async {
    final response = await http.get(Uri.parse("$baseUrl/api/history/all"));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      List historyData = data['data'] ?? [];
      return historyData.map((e) => HistorySong.fromJson(e)).toList();
    } else {
      throw Exception("Không thể lấy tất cả lịch sử nghe");
    }
  }

  Future<void> addHistory(
    String title,
    String artist,
    String album,
    String songId,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/api/history"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'title': title,
        'artist': artist,
        'songId': songId,
        'album': album,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Api không thể lưu bài hát vào lịch sử");
    }
  }

  Future<int> fetchTotalHistory(String userId) async {
    final url = Uri.parse('$baseUrl/api/total-history/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['total'];
    } else {
      throw Exception('Failed to load total history: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchHistory(String artist) async {
    final url = Uri.parse('$baseUrl/api/history/$artist');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }
}
