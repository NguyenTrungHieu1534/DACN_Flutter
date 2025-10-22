import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favSongs.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/songs.dart';
import '../models/artist.dart';

class ArtistService {
  static const String _baseUrl = 'YOUR_RENDER_BASE_URL';
  final http.Client _client;

  ArtistService({http.Client? client}) : _client = client ?? http.Client();
  Future<List<Artist>> fetchArtists() async {
    final uri = Uri.parse('$_baseUrl/api/artists');
    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> artistsJson = jsonDecode(response.body);
        return artistsJson.map((json) => Artist.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load artists (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('ArtistService Error (fetchArtists): $e');
      throw Exception('Network error or server connection failed.');
    }
  }

  Future<Map<String, dynamic>> fetchArtistDetails(String artistName) async {
    final encodedName = Uri.encodeComponent(artistName);
    final uri = Uri.parse('$_baseUrl/api/artist/$encodedName');
    
    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Artist not found: $artistName');
      } else {
        throw Exception('Failed to load artist details (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('ArtistService Error (fetchArtistDetails): $e');
      throw Exception('Network error or failed to get details.');
    }
  }

  Future<String> fetchArtistPhotoUrl(String artistName) async {
    final encodedName = Uri.encodeComponent(artistName);
    final uri = Uri.parse('$_baseUrl/api/artist/photo/$encodedName');

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // API trả về object: { url: "..." }
        final String photoUrl = json['url'] as String? ?? ''; 
        return photoUrl;
      } else {
        throw Exception('Failed to load artist photo URL (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('ArtistService Error (fetchArtistPhotoUrl): $e');
      throw Exception('Network error or failed to get photo.');
    }
  }
  Future<List<Songs>> fetchSongsByArtist(String artistName) async {
    final encodedName = Uri.encodeComponent(artistName);
    final uri = Uri.parse('$_baseUrl/api/artist/songs/$encodedName');

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> songsJson = jsonDecode(response.body);
        return songsJson.map((json) => Songs.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load songs by artist (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('ArtistService Error (fetchSongsByArtist): $e');
      throw Exception('Network error or failed to get songs.');
    }
  }
  Future<List<String>> fetchAlbumsByArtist(String artistName) async {
    final encodedName = Uri.encodeComponent(artistName);
    final uri = Uri.parse('$_baseUrl/api/artist/albums/$encodedName');

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> albumsJson = jsonDecode(response.body);
        // API trả về một mảng các chuỗi (tên album)
        return albumsJson.map((album) => album.toString()).toList();
      } else {
        throw Exception('Failed to load albums by artist (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('ArtistService Error (fetchAlbumsByArtist): $e');
      throw Exception('Network error or failed to get albums.');
    }
  }
}