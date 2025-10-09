import 'dart:convert';

import 'package:http/http.dart' as http;
class UserService {
  UserService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Base API URL for your backend server
  static const String baseApiUrl = 'https://backend-dacn-9l4w.onrender.com';
  static const String baseHealthUrl =
      'https://backend-dacn-9l4w.onrender.com/health';

  Future<String> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse(baseHealthUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['message']?.toString() ?? 'OK';
      }

      return 'Unhealthy (${response.statusCode})';
    } catch (e) {
      return 'Offline';
    }
  }
//signup
static Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseApiUrl/api/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return {
          "success": true,
          "message": body["message"] ?? "Đăng ký thành công!",
        };
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["message"] ?? "Đăng ký thất bại!",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Không thể kết nối đến server.\nLỗi: $e",
      };
    }
  }

  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    final uri = Uri.parse('$baseApiUrl/api/login');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'identifier': identifier,
      'password': password,
    });

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 12));

    final Map<String, dynamic> data =
        response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic> : {};

    if (response.statusCode == 200) {
      final token = data['token']?.toString();
      final message = data['message']?.toString() ?? 'Đăng nhập thành công';
      if (token == null || token.isEmpty) {
        throw Exception('Thiếu token từ máy chủ');
      }
      return LoginResponse(token: token, message: message);
    }

    final errorMessage = data['message']?.toString() ?? 'Đăng nhập thất bại';
    throw Exception(errorMessage);
  }
}

class LoginResponse {
  const LoginResponse({required this.token, required this.message});

  final String token;
  final String message;
}




