import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/playlist.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/songs.dart';
import 'dart:io';

class ApiPlaylist {
  static const String baseUrl = "https://backend-dacn-9l4w.onrender.com";
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Playlist>> getPlaylistsByUser() async {
    final token = await _getToken();
    Map<String, dynamic> decoded = JwtDecoder.decode(token.toString());
    String username = decoded["username"];
    final response =
        await http.get(Uri.parse("$baseUrl/api/playlists/$username"));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'] ?? [];
      return data.map((e) => Playlist.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load playlists");
    }
  }

  static Future<bool> createPlaylist(
      String token, String name, String description) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/playlist"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'description': description,
      }),
    );

    return response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> renamePlaylist(String token,
      String playlistId, String newName, String newDescription) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/playlist/$playlistId/rename"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': newName,
        'description': newDescription,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      AlertDialog(
        title: const Text("toi bi ngu"),
      );
    }
    return null;
  }

  static Future<bool> deletePlaylist(String token, String playlistId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/playlist/$playlistId"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  static Future<bool> addSongToPlaylist(
      String token, String playlistId, Songs song) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/addplaylistSong/$playlistId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'songTitle': song.title,
        'artist': song.artist,
        'songId': song.id,
        'album': song.albuml,
        'url': song.url,
        'mp3url': song.mp3Url,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> removeSongFromPlaylist(
      String token, String playlistId, String songId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/api/playlist/$playlistId/$songId"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  Future<List<Songs>> fetchPlaylistSong(
      String username, String playlistName, String token) async {
    final url = Uri.parse(
        'https://backend-dacn-9l4w.onrender.com/api/playlistSong/$username/$playlistName');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<Songs> songs = (data['songs'] as List)
          .map((songJson) => Songs.fromJson(songJson))
          .toList();

      return songs;
    } else {
      throw Exception('Không thể lấy playlist (${response.statusCode})');
    }
  }

  Future<String?> fetchPlaylistPicUrl(
      String username, String playlistName, String token) async {
    final url = Uri.parse(
        'https://backend-dacn-9l4w.onrender.com/api/playlistPic/$username/$playlistName');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['picUrl'] as String?;
    } else {
      print('Lỗi khi lấy picUrl: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadPlaylistPic({
    required String playlistId,
    required File imageFile,
  }) async {
    final uri = Uri.parse(
        'https://backend-dacn-9l4w.onrender.com/api/upload-playlistPic');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.fields['id'] = playlistId;
      final multipartFile = await http.MultipartFile.fromPath(
        'picUrl',
        imageFile.path,
      );
      request.files.add(multipartFile);
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print(
            "Upload playlist pic failed: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> editPlaylistDescription({
    required String playlistId,
    required String token,
    required String description,
  }) async {
    final url = Uri.parse('$baseUrl/api/playlist/$playlistId/edit');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(' Edit failed: ${response.statusCode}, ${response.body}');
        return {'error': response.body};
      }
    } catch (e) {
      print('Edit exception: $e');
      return {'error': e.toString()};
    }
  }
}
