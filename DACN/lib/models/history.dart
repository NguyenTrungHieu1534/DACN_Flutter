class HistorySong {
  final String username;
  final String title;
  final String artist;
  final String songId;
  final String album;
  final String thumbnail;
  final DateTime playedAt;

  HistorySong({
    required this.username,
    required this.title,
    required this.artist,
    required this.album,
    required this.thumbnail,
    required this.songId,
    required this.playedAt,
  });

  factory HistorySong.fromJson(Map<String, dynamic> json) {
    return HistorySong(
      username: json['username'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      songId: json['songId'] ?? '',
      album: json['album'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      playedAt: json['played_at'] != null
          ? DateTime.parse(json['played_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'title': title,
      'artist': artist,
      'songId': songId,
      'album': album,
      'thumbnail': thumbnail,
      'played_at': playedAt.toIso8601String(),
    };
  }
}
