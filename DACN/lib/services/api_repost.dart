import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repost.dart';
import '../models/songs.dart';
import 'package:http/http.dart' as http;
class RepostService {
  static const String _baseUrl = 'https://backend-dacn-9l4w.onrender.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  Future<List<Repost>> fetchRepostsByUser(String userId) async {
    final token = await _getToken();
    if (token == null) return [];

    final url = Uri.parse('$_baseUrl/api/reposts/$userId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Repost.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load reposts (${response.statusCode})');
    }
  }
  Future<bool> toggleRepost(Songs song, bool currentlyReposted) async {
    final token = await _getToken();
    if (token == null) throw Exception('User not authenticated');

    final String endpoint = currentlyReposted ? '/api/repost/remove' : '/api/repost/add';
    final Uri url = Uri.parse('$_baseUrl$endpoint');
    final String method = currentlyReposted ? 'DELETE' : 'POST';

    final bodyData = {
      'songId': song.id,
      if (!currentlyReposted) ...{
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'url': song.url,
        'thumbnail': song.thumbnail,
      }
    };

    final client = http.Client(); 
  try {
    final request = http.Request(method, url) 
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode(bodyData);

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse); 

    if (response.statusCode == 201 || response.statusCode == 200) {
      return !currentlyReposted;
    } else if (response.statusCode == 409) {
      throw Exception('Bài hát đã được repost rồi.');
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Thao tác Repost thất bại.');
    }
  } finally {
    client.close();
  }
  }
  Future<bool> isSongReposted(String songId) async {
    final token = await _getToken();
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/api/repost/check/$songId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reposted'] ?? false;
    }
    return false;
  }
}