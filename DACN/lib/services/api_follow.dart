import 'dart:convert';
import 'package:http/http.dart' as http;

class FollowService {
  final String baseUrl = "http://localhost:3000/api"; // đổi IP khi chạy thật (VD: 192.168.x.x)
  Future<bool> addFollow({
    required String userId,
    required String targetType,
    required String targetId,
  }) async {
    final url = Uri.parse("$baseUrl/addfollow");
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
    final url = Uri.parse("$baseUrl/follow/check");
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
    final url = Uri.parse("$baseUrl/unfollow");
    final body = jsonEncode({
      "userId": userId,
      "targetType": targetType,
      "targetId": targetId,
    });

    final res = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
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
    final url = Uri.parse("$baseUrl/follow/$userId");

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data;
    } else {
      throw Exception("Get follow list failed: ${res.body}");
    }
  }
}
