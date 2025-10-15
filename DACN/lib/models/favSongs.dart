import 'dart:convert';

class FavoriteSong {
  final String? id;
  final String username;
  final String title;
  final String songId;
  final String artist;
  final String filename;
  final String album;

  FavoriteSong({
    this.id,
    required this.username,
    required this.title,
    required this.songId,
    required this.artist,
    required this.filename,
    required this.album,
  });

  factory FavoriteSong.fromJson(Map<String, dynamic> json) {
    return FavoriteSong(
      id: json['_id'] ?? '',
      username: json['username']?? '',
      title: json['title']?? '',
      songId: json['songId']?? '',
      artist: json['artist']?? '',
      filename: json['filename']?? '',
      album: json['album']?? '',
    );
  }
}
