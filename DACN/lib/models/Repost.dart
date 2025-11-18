import 'songs.dart';

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
    return Repost(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      songId: json['songId']?.toString() ?? '',
      repostedAt: DateTime.tryParse(json['repostedAt']?.toString() ?? '') ?? DateTime.now(),
      
      // Xử lý songInfo - Nó là một Map chứa thông tin cơ bản của bài hát
      songInfo: Songs.fromJson({
        'id': json['songId'], // Sử dụng songId làm ID
        'title': json['songInfo']['title'] ?? '',
        'artist': json['songInfo']['artist'] ?? '',
        'album': json['songInfo']['album'] ?? '',
        'url': json['songInfo']['url'] ?? '',
        'thumbnail': json['songInfo']['thumbnail'] ?? '',
        // Các trường khác như mp3Url, lyric có thể là null hoặc chuỗi rỗng
        'mp3Url': '',
        'lyric': '',
      }),
    );
  }
}