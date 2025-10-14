import 'dart:convert';

class Favorite {
  final String? id; // từ MongoDB: _id có thể ở dạng ObjectId hoặc String
  final String username;
  final String title;
  final String songId;
  final String artist;
  final String filename;
  final String album;

  const Favorite({
    this.id,
    required this.username,
    required this.title,
    required this.artist,
    required this.songId,
    required this.filename,
    required this.album,
  });

  Favorite copyWith({
    String? id,
    String? username,
    String? title,
    String? artist,
    String? filename,
    String? album,
    String? songId,
  }) {
    return Favorite(
      id: id ?? this.id,
      username: username ?? this.username,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      filename: filename ?? this.filename,
      album: album ?? this.album,
      songId: songId ?? this.songId,
    );
  }
}