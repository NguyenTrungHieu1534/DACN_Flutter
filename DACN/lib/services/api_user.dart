import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/socket_service.dart';
import '../services/api_follow.dart';

class UserService {
  UserService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String baseApiUrl = 'https://backend-dacn-9l4w.onrender.com';
  final FollowService followservice = FollowService();
  // static const String baseHealthUrl =

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  //     'https://backend-dacn-9l4w.onrender.com/health';

  // // ------------------------- HEALTH CHECK -------------------------
  // Future<String> checkHealth() async {
  //   try {
  //     final response = await _client
  //         .get(Uri.parse(baseHealthUrl))
  //         .timeout(const Duration(seconds: 8));

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body) as Map<String, dynamic>;
  //       return data['message']?.toString() ?? 'OK';
  //     }

  //     return 'Unhealthy (${response.statusCode})';
  //   } catch (e) {
  //     return 'Offline';
  //   }
  // }

  // ------------------------- SIGN UP -------------------------
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

      final body = jsonDecode(response.body);
      return {
        "success": response.statusCode == 201,
        "message": body["message"] ?? "Đăng ký thành công!",
      };
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

    final Map<String, dynamic> data = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : {};

    if (response.statusCode == 200) {
      // Accept multiple token field names for compatibility
      final token = (data['token'] ?? data['accessToken'] ?? data['jwt'])?.toString();
      final message = data['message']?.toString() ?? 'Đăng nhập thành công';
      if (token == null || token.isEmpty) {
        // Minimal debug info to help diagnose on device logs
        // ignore: avoid_print
        print('Login 200 but no token. Keys: ${data.keys.toList()} body: ${response.body}');
        throw Exception('Thiếu token từ máy chủ');
      }
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', token);
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      if (decodedToken['status'] == "blocked") {
        return LoginResponse(
            token: token,
            message: "Tài khoản của bạn đã bị khóa.",
            userStatus: "blocked");
      }
      SocketService().connect(decodedToken['_id']);
      List<dynamic> userInfor =
          await followservice.getFollowList(decodedToken['_id']);
      prefs.setString('userInfor', jsonEncode(userInfor));
      final fcmToken = prefs.getString('fcmToken');
      http.post(
        Uri.parse("https://backend-dacn-9l4w.onrender.com/api/fcmtoken"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": decodedToken['_id'],
          "fcmtoken": fcmToken,
        }),
      );

      return LoginResponse(
          token: token, message: message, userStatus: decodedToken['status']);
    }

    final errorMessage = data['message']?.toString() ?? 'Đăng nhập thất bại';
    throw Exception(errorMessage);
  }

  Future<Map<String, dynamic>> sendForgotPasswordOtp({
    required String username,
    required String email,
  }) async {
    final uri = Uri.parse('$baseApiUrl/api/forgot-password');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': body['message'] ??
            'Đã gửi OTP hoặc link xác thực đến email của bạn.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse('$baseApiUrl/api/verify-otp');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final body = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': body['message'] ?? 'Xác minh OTP thành công!',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    final uri = Uri.parse('$baseApiUrl/api/reset-password');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'otp': otp,
        }),
      );

      final body = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': body['message'] ?? 'Đặt lại mật khẩu thành công!',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(
      String userId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseApiUrl/api/upload-avatar'),
      );
      request.fields['userId'] = userId;
      request.files.add(await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
      ));
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        print('Upload failed: ${response.statusCode}, $responseBody');
        return {"error": "Upload failed", "details": responseBody};
      }
    } catch (e) {
      return {"error": "Exception", "details": e.toString()};
    }
  }

  Future<void> updatePassword(
      String email, String newPassword, String oldPassword) async {
    if (newPassword.toLowerCase().toString() ==
        oldPassword.toLowerCase().toString()) {
      return;
    }
    final uri = Uri.parse('$baseApiUrl/api/update-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': newPassword}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data['message']);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ??
          'Không thể cập nhật mật khẩu');
    }
  }

  Future<Map<String, dynamic>> updateUsername({
    required String userId,
    required String newUsername,
  }) async {
    final uri = Uri.parse('$baseApiUrl/api/update-username');
    final token = await _getToken();

    if (token == null) {
      return {'success': false, 'message': 'Bạn chưa đăng nhập.'};
    }

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'newUsername': newUsername,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Cập nhật tên người dùng thành công!'
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Cập nhật tên người dùng thất bại.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> updateBio({
    required String userId,
    required String bio,
  }) async {
    final uri = Uri.parse('$baseApiUrl/api/update-bio');
    final token = await _getToken();

    if (token == null) {
      return {'success': false, 'message': 'Bạn chưa đăng nhập.'};
    }

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'bio': bio,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Cập nhật bio thành công!'
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Cập nhật bio thất bại.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> updateEmail({
    required String userId,
    required String newEmail,
  }) async {
    final uri = Uri.parse('$baseApiUrl/api/update-email');
    final token = await _getToken();

    if (token == null) {
      return {'success': false, 'message': 'Bạn chưa đăng nhập.'};
    }

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'newEmail': newEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Cập nhật email thành công!'
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Cập nhật email thất bại.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<bool?> getPrivacy(String userId) async {
    final token = await _getToken();
    if (token == null) return null;
    final uri = Uri.parse('$baseApiUrl/api/user/privacy/$userId');
    try {
      final response = await http
          .get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        if (response.body.isEmpty) return null;
        try {
          final dynamic parsed = jsonDecode(response.body);
          if (parsed is Map<String, dynamic>) {
            return parsed['isPrivate'] == true;
          }
          if (parsed is bool) return parsed;
          return null;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updatePrivacy({
    required String userId,
    required bool isPrivate,
  }) async {
    final uri = Uri.parse('$baseApiUrl/api/update-privacy');
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Bạn chưa đăng nhập.'};
    }
    try {
      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'isPrivate': isPrivate,
        }),
      )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {'success': true, 'message': 'Đã cập nhật quyền riêng tư.'};
        }
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'message': data['message'] ?? 'Đã cập nhật quyền riêng tư.'
          };
        } catch (_) {
          return {'success': true, 'message': 'Đã cập nhật quyền riêng tư.'};
        }
      } else {
        if (response.body.isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            return {
              'success': false,
              'message':
                  data['message'] ?? 'Cập nhật quyền riêng tư thất bại.'
            };
          } catch (_) {
            return {
              'success': false,
              'message':
                  'Cập nhật quyền riêng tư thất bại (${response.statusCode}).'
            };
          }
        }
        return {
          'success': false,
          'message':
              'Cập nhật quyền riêng tư thất bại (${response.statusCode}).'
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Không thể kết nối máy chủ. Vui lòng thử lại.'
      };
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseApiUrl/api/users/search?query=${Uri.encodeQueryComponent(query)}');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPublicProfile(String userId) async {
    final token = await _getToken();
    if (token == null) return null;
    final uri = Uri.parse('$baseApiUrl/api/user/$userId');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }
      if (response.statusCode == 403) {
        return {'isPrivate': true, 'masked': true};
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userInfor');
    SocketService().disconnect();
    final token = prefs.getString('token');
    if (token == null) return;
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    final fcmToken = prefs.getString('fcmToken');
    await http.post(
      Uri.parse("https://backend-dacn-9l4w.onrender.com/api/remove-fcmtoken"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": decodedToken['_id'],
        "fcmtoken": fcmToken,
      }),
    );
    await prefs.remove('token');
  }

  static Future<String> sendVerifyEmail() async {
    final url =
        Uri.parse("https://backend-dacn-9l4w.onrender.com/api/verify-email");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return "Bạn chưa đăng nhập.";
    final userId = JwtDecoder.decode(token)['_id'];
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200) {
        return "Đã gửi email xác thực, vui lòng kiểm tra hộp thư.";
      } else {
        return "${response.body}";
      }
    } catch (err) {
      return "Lỗi kết nối: $err";
    }
  }

  static Future<String> askForArtist() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return "Bạn chưa đăng nhập.";
    final userId = JwtDecoder.decode(token)['_id'];
    final url =
        Uri.parse('https://backend-dacn-9l4w.onrender.com/api/user/askforartist/$userId');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data['message'];
      } else {
        return data['message'];
      }
    } catch (err) {
      return err.toString();
    }
  }
}

class LoginResponse {
  const LoginResponse(
      {required this.token, required this.message, this.userStatus});

  final String token;
  final String message;
  final String? userStatus;
}
