import 'songs.dart'; 
import 'package:flutter/material.dart';

class Repost {
  final String id;
  final String userId;
  final String songId;
  final Songs songInfo;
  final DateTime repostedAt;

  Repost({
    required this.id,
    required this.userId,
    required this.songId,
    required this.songInfo,
    required this.repostedAt,
  });

  factory Repost.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? rawSongInfo = json['songInfo'];

    if (rawSongInfo == null) {
      debugPrint("Lỗi Repost.fromJson: Thiếu trường songInfo");
      throw const FormatException('Repost data is incomplete (missing songInfo).');
    }
    final String songIdStr = json['songId']?.toString() ?? '';
    final String repostedAtStr = json['repostedAt']?.toString() ?? '';
    return Repost(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      songId: songIdStr,
      repostedAt: DateTime.tryParse(repostedAtStr) ?? DateTime.now(),
      songInfo: Songs.fromJson({
        'id': songIdStr,
        'title': rawSongInfo['title'] ?? '',
        'artist': rawSongInfo['artist'] ?? '',
        'album': rawSongInfo['album'] ?? '',
        'url': rawSongInfo['url'] ?? '', 
        'thumbnail': rawSongInfo['thumbnail'] ?? '',
        'mp3Url': rawSongInfo['mp3Url'] ?? '', 
        'lyric': rawSongInfo['lyric'] ?? '',
      }),
    );
  }
}