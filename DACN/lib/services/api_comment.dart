import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comment.dart';

class CommentService {
  static const String _baseUrl = 'https://backend-dacn-9l4w.onrender.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Comment>> fetchComments(String songId) async {
    final url = Uri.parse('$_baseUrl/api/comments/$songId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Comment.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<Comment> addComment({
    required String songId,
    required String content,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final url = Uri.parse('$_baseUrl/api/comments/add');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'songId': songId,
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      return Comment.fromJson(jsonDecode(response.body));
    } else {
      String errorMessage = 'Lỗi không xác định (${response.statusCode})';
      
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['message'] ?? errorMessage;
      } catch (e) {
        if (response.body.contains('<!DOCTYPE html>')) {
          errorMessage = 'Lỗi kết nối Server hoặc Server gặp lỗi nội bộ (HTML response).';
        } else {
          errorMessage = 'Lỗi phản hồi không mong muốn (${response.statusCode}).';
        }
      }
      throw Exception(errorMessage);
    }
  }
}