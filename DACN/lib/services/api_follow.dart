import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FollowService {
  final String baseUrl = "https://backend-dacn-9l4w.onrender.com/api";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> addFollow({
    required String userId,
    required String targetType,
    required String targetId,
  }) async {
    final token = await _getToken();
    final url = Uri.parse("$baseUrl/addfollow");
    final body = jsonEncode({
      "userId": userId,
      "targetType": targetType,
      "targetId": targetId,
    });

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token'
      },
      body: body,
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return true;
    } else if (res.statusCode == 409) {
      // Đã follow rồi
      return false;
    } else {
      throw Exception("Failed to follow: ${res.body}");
    }
  }

  Future<bool> checkFollow({
    required String userId,
    required String targetType,
    required String targetId,
  }) async {
    final token = await _getToken();
    final url = Uri.parse("$baseUrl/follow/check");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        "userId": userId,
        "targetType": targetType,
        "targetId": targetId,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["followed"] == true;
    } else {
      throw Exception("Check follow failed: ${res.body}");
    }
  }

  Future<bool> unfollow({
    required String userId,
    required String targetType,
    required String targetId,
  }) async {
    final token = await _getToken();
    final url = Uri.parse("$baseUrl/unfollow");
    final body = jsonEncode({
      "userId": userId,
      "targetType": targetType,
      "targetId": targetId,
    });

    final res = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token'
      },
      body: body,
    );

    if (res.statusCode == 200) {
      return true;
    } else if (res.statusCode == 404) {
      return false;
    } else {
      throw Exception("Unfollow failed: ${res.body}");
    }
  }

  Future<List<dynamic>> getFollowList(String userId) async {
    final token = await _getToken();
    final url = Uri.parse("$baseUrl/follow/$userId");

    final res = await http.get(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data;
    } else {
      throw Exception("Get follow list failed: ${res.body}");
    }
  }

  Future<Map<String, dynamic>> getFollowInfo({
    required String userId,
    required String targetType,
    required String targetId,
  }) async {
    final url =
        Uri.parse("https://backend-dacn-9l4w.onrender.com/api/follow/info");

    final body = jsonEncode({
      "userId": userId,
      "targetType": targetType,
      "targetId": targetId,
    });

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return decoded["data"];
    } else {
      throw Exception(
        "Get follow info failed (${res.statusCode}): ${res.body}",
      );
    }
  }

  Future<int> fetchTotalFollow(String userId) async {
    final url = Uri.parse('$baseUrl/total-follow/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['total'];
    } else {
      throw Exception('Failed to load total follow: ${response.body}');
    }
  }
}
